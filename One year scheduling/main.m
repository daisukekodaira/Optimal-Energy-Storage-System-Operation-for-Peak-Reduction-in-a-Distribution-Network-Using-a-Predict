% -------------------------------------------------------------------------------------------------------
%   Updated: 2019/12/16
%   Edited by: Daisuke Kodaira 
%   Input Data: 
%       1. 'detrPredLoad.csv': the result of deterministic load forecasting
%       2. 'upperCI.csv': upper boundary of probabilistic load forecasting
%       3. 'lowerCI.csv': lower boundary of probabilistic load forecasting
%       4. 'obsrLoad.csv': actual load (without ESS operation)
%       5. 'probLoadPred.csv': the result of probabilistic load forecasting. It to be used for heatmap description
%   Output Data: 
%       1. 'ESS_inout_MW.xlsx': ESS charging/discharging operation (optimized)
%       2. 'SOC_rate.xlsx': ESS SOC transition in the operation
%       3. 'Adjusted predicted load.xlsx': Adjusted forecasted load by the optimized ESS operation
%       4. 'Adjusted observed load.xlsx'; Adjusted actual load by the optimized ESS operation
%       5. 'Preak reduction.xlsx': The result of actual peak reduction by the ESS operation
% 
%   Note: This algorithm takes more than few hours if you use one year data
% -------------------------------------------------------------------------------------------------------

%% Initialization
clearvars; close all; clc;

%% Load the data set and parameters
global_var_declare; % Declare the global variables
data_config; % Load parameters
tic;

% for debug ---------------------------------------
g_days = 2;
% --------------------------------------------------

% Display estimated calculation time for a user
p = 1+g_days;
X = ['Expected time to be done: around ', num2str(p), ' min'];
disp(X);
disp('Calculating...')

for day = 1:g_days    
    %% Update SOC
    if day == 1
        g_SocDayStart = g_initial_SOC;
    else
        g_SocDayStart = SOC_kwh(end,:);
    end
    
    %% Calculate ESS schedule
    % Pick one-day load data
    predLoad = g_predLoad(:, day);  % forecasted load
    obsrLoad = g_obsrLoad(:, day);   % observed load
    g_upperCIOneDay = g_upperCI(:, day);  % upper prediction interval 
    lowerCI = g_lowerCI(:, day); % lower prediction interval
    % PSO calculation
    % - "run_pso" returns optimum solutions which are given as "pso_out"
    % -  The last column of "pso_out" is not solution but the final cost of objective function 
    run_pso;
    % Erase the final cost of the objective function
    pso_out(size(pso_out,1)) = [];

    %% Arrange the data for graph
    % Change the formalt for the output from (solutions,1) to (hours(=24), the number of ESS(=2),)
    out_reshape = transpose(reshape(pso_out,[g_s_period, g_num_ESS]));
    % Combied ESS schedule
    for i = 1:g_num_ESS
        ESS_opt(:,i) = transpose(repelem(out_reshape(i,:),g_coef));
    end

    % Calculate power flow on feeder including ESS operations
    [rawPredLoad(day).data] = load_calc(predLoad, zeros(g_num_ESS,24));           % Power flow at each position without ESS operation for predicted load
    [rawObsrLoad(day).data] = load_calc(obsrLoad, zeros(g_num_ESS,24));           % Power flow at each position without ESS operation for actual (observed) load
    [adjPredLoad(day).data] = load_calc(predLoad, out_reshape);                           % Power flow at each position with ESS operation for predicted load
    [adjObsrLoad(day).data] = load_calc(obsrLoad, out_reshape);                            % Power flow at each position with ESS operation for actual (observed) load
    [rawUpCI(day).data] = load_calc(g_upperCIOneDay, zeros(g_num_ESS,24));
    [rawLoCI(day).data] = load_calc(lowerCI, zeros(g_num_ESS,24));
    [adjUpCI(day).data] = load_calc(g_upperCIOneDay, out_reshape);
    [adjLoCI(day).data] = load_calc(lowerCI, out_reshape);
    
    %% Calculate SOC
    % Set the Initial SOC in a day
    if day ==1
        SOC_kwh = g_initial_SOC;    % SOC [kwh]
    else
        SOC_kwh = SOC_rate(day-1).data(end,:)/100.*g_ESS_capacity;  % SOC [kwh]
    end
    % Calculate SOC transition for the day based on the optimized ESS operation
    for i = 1:g_num_ESS
        ESS_schedule(day).data(:,i) = transpose(repelem(out_reshape(i,:),4));
        for j = 1:24*4
            SOC_kwh(j+1,i) = SOC_kwh(j,i) + ESS_schedule(day).data(j,i).*0.25;   % optimized_ESS: "+" means charge,  "-" means discharge
        end
        SOC_rate(day).data(:,i) = transpose(100*SOC_kwh(:,i)./g_ESS_capacity(i));    % transform SOC[kwh] to SOC[%]
    end
    
    %% Calculate Peak reduction in the day
    peakReduction(day,:) = max(rawObsrLoad(day).data(:,1)) - max(adjObsrLoad(day).data(:,1)); % (+) Reduction, (-) Increase   
    
    %% [For user convenience] Display completed percentage of the calculation
    p = round(day*100/g_days,1);
    X = ['Processing...', num2str(p), '/100[%]'];
    disp(X);

end
%% [For user convenience] Display the status of the calcualtion
disp('Completed!!');
toc;

%% Graph description
% ---------------------------------------------------------------------------------------
% Figure1: Result of optimized load
% Contents;
%   01. Predicted load: mean load of each time step 
%   02. Optimized load (test load data + ESS operation) (probabilistic)
%   03. Test load (raw test load data)
%   04. Line capacity
%   05. SOC variance
%   06. Original Confidence range  (training data)_before
%   07. Original Confidence range  (training data)_after
%   08. Adjusted Confidence range (training data + ess operation)_before
%   09. Adjusted range (training data + ess operation)_after
%   10. Heatmap
% ---------------------------------------------------------------------------------------

% Select which area in the line is needed to be shown as graph?
line_area = [1 0 0 0 0]; % Ex) [1 1 0] = [ture ture false].....Area 1 and 2 will be shown as graph
name = {'Substation', 'ESS#1 left', 'ESS#1 right', 'ESS#2 left', 'ESS#2 right'}; % name of the area
day =1; % chose arbitral day in the input data
sigma=2; % 2sigma=95% boundaries for Prediction Interval

% A loop for devided line areas. The area is composed of (the number of ESS)+3
for area = 1:g_num_ESS+3
    % Check the flags to display the graph for each area
    if line_area(area) == 1 % 1 means ture
        % 01. Predicted load (forecasted load data)
        y(1).data = rawPredLoad(day).data(:,area);  % pick the position's load at the day
        y(1).name = 'Deterministic forecasted load';  
        y(1).color = 'm';
        y(1).yaxis = 'left';
        y(1).linestyle = '-';
        y(1).descrp = [1 0]; % [1 0] = [ture false] for each ESS

        % 02. Optimized actual load (actual load data + ESS operation)
        y(end+1).data = adjObsrLoad(day).data(:,area); 
        y(end).name = 'Adjusted actual load';
        y(end).color = 'g';
        y(end).yaxis = 'left';
        y(end).linestyle = '-';
        y(end).descrp = [0 1];

        % 03. Actual load (actual load data without ESS operation)
        y(end+1).data = rawObsrLoad(day).data(:,area);
        y(end).name = 'Actual load';
        y(end).color = 'm';
        y(end).yaxis = 'left';
        y(end).linestyle = '-';
        y(end).descrp = [0 1];

        % 04. Line capacity
        y(end+1).data = g_line_capacity*ones(size(predLoad,1),1);
        y(end).name = 'Line capacity';
        y(end).color = 'r';
        y(end).yaxis = 'left';
        y(end).linestyle = '-';
        y(end).graphno = 0;
        y(end).descrp = [0 0];

        % 05. SOC
        % NOTE:
        %   'SOCrate' stores 97 records per one day. The last record for each day
        %   is the same as the first record of the next day. All the last records for 
        %   each day is removed to avoid the duplication.
        for i = 1:g_days
            SOC_rate(i).data(end, :) = [];  % dupulicated records are removed
        end
        for num = 1:g_num_ESS
            y(end+1).data = SOC_rate(day).data(:,num);
            y(end).name = (['SOC ESS#',num2str(num)]);
            y(end).color = [0 0 0+0.5*(num-1)];
            y(end).yaxis = 'right';
            y(end).linestyle = '-';
            y(end).descrp = [1 1];
        end

        % 06. Probabilistic Interval before ESS operation      
        y(end+1).data = rawUpCI(day).data(:,area);
        y(end).name = 'Predicted PI';
        y(end).color = 'm';
        y(end).yaxis = 'left';
        y(end).linestyle = '--';
        y(end).descrp = [1 0];
        y(end+1).data = rawLoCI(day).data(:,area); % 2min: 1*24, 30 = 720   15min:1*24,4 = 96
        y(end).name = '~'; % 'Predicted PI';
        y(end).color = 'm';
        y(end).yaxis = 'left';
        y(end).linestyle = '--';
        y(end).descrp = [1 0];

        % 07. Adjusted Probabilistic Interval after operation (training data + ess operation)
        y(end+1).data = adjUpCI(day).data(:,area); % 2min: 1*24, 30 = 720   15min:1*24,4 = 96
        y(end).name = 'Adjusted PI';
        y(end).color = 'g';
        y(end).yaxis = 'left';
        y(end).linestyle = '--';
        y(end).descrp = [1 0]; 
        y(end+1).data = adjLoCI(day).data(:,area); % 2min: 1*24, 30 = 720   15min:1*24,4 = 96
        y(end).name = '~';
        y(end).color = 'g';
        y(end).yaxis = 'left';
        y(end).linestyle = '--';
        y(end).descrp = [1 0]; 

        % Describe the graph 
        graph_desc(y, g_ProbPredLoad, name(area));

%             clear y;
    end
end

% This part needs to be modifed (2019,12/16 Koda) 
%  ---------------------------------------------------------------------------------------------------------------------------------------
% %% Calculate the highest peak in a year
% % - Search whole area among whole days (in a year)
% % - 
% % Pick the peak among all the actual data set
% [~, phour(1)] = max(rawObsrLoad(day).data(:,area)); % pick the time instance
% peak_hour(1) = fix(phour(1)/4);   % calcurate peak hour from the time instance
% observed_peak = max(max(obsrLoad));
% [~, phour(2)] = max(adjObsrLoad(day).data(:,area));
% peak_hour(2) = fix(phour(2)/4);
% adjObserved_peak = max(max(adjObsrLoad(day).data(:,area)));  % peak among whole days
% % Table
% LastName = {char(strcat('Observed load (', name(position), ')')); char(strcat('Adjusted Observed load (', name(area), ')'))};
% Peak_at_Substation = [observed_peak peak_hour(1); adjObserved_peak peak_hour(2)];
% table(Peak_at_Substation,'RowNames',LastName)
%  ---------------------------------------------------------------------------------------------------------------------------------

%% File output
% Disable warning 
warning('off', 'MATLAB:xlswrite:AddSheet');
% Transform the data format of matrices for file output
for x = 1:g_days
    ESS1_schedule(:,x) = ESS_schedule(x).data(:,1); % ESS#1
    ESS2_schedule(:,x) = ESS_schedule(x).data(:,2); % ESS#2
    ESS1_SOC(:,x) = SOC_rate(x).data(:,1); % ESS#1
    ESS2_SOC(:,x) = SOC_rate(x).data(:,2); % ESS#2
    raw_train_load(:,x) = rawPredLoad(x).data(:,1);    % area = 1; substation
    raw_test_load(:,x) = rawObsrLoad(x).data(:,1);     % area = 1; substation
    adj_train_load1(:,x) = adjPredLoad(x).data(:,1);    % area = 1; substation
    adj_test_load1(:,x) = adjObsrLoad(x).data(:,1);     % area = 1; substation
end
% ESS power transition
filename_w1 = 'out_ESS_inout_MW.xlsx';
xlswrite(filename_w1, ESS1_schedule,1,'B5');        % Sheet1: Write ESS1 power transition
xlswrite(filename_w1, ESS2_schedule,2,'B5');        % Sheet2: Write ESS2 power transition
% ESS SOC transition
filename_w2 = 'out_ESS_SOC.xlsx';
xlswrite(filename_w2, ESS1_SOC,1,'B5');        % Sheet1: ESS#1
xlswrite(filename_w2, ESS2_SOC,2,'B5');        % Sheet2: ESS#2
% Adjusted forecasted load (forecasted load + ESS operation)
filename_w3 = 'out_Adjusted_predicted_load.xlsx';
xlswrite(filename_w3,raw_train_load,1,'B2');
xlswrite(filename_w3,transpose(1:g_steps),1,'A2');      
xlswrite(filename_w3,adj_train_load1,2,'B2');      
xlswrite(filename_w3,transpose(1:g_steps),2,'A2');    
% Adjusted actual load (actual load + ESS operation)
filename_w4 = 'out_Adjusted_actual_load.xlsx';
xlswrite(filename_w4, raw_test_load, 1, 'B2');       
xlswrite(filename_w4, transpose(1:g_steps),1,'A2');      
xlswrite(filename_w4, adj_test_load1,2,'B2');        
xlswrite(filename_w4, transpose(1:g_steps),2,'A2');     
% Peak reduction (Gap between actual load with ESS and without ESS)
filename_w5 = 'out_Peak_reduction.xlsx';
xlswrite(filename_w5, peakReduction, 1, 'A2');  % Excel sheet (+) Reduction, (-) Increase

%% Figures for summary
% Histogram for peak reduction
figure;
data = xlsread(filename_w5);
histogram(data*-1,'Normalization','probability'); % Histogram: (-) Reduction, (+) Increase
xlabel('Peak variation [MW]');
ylabel('Probability')

beep;


