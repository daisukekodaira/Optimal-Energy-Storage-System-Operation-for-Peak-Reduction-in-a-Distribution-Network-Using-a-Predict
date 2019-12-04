% -------------------------------------------------------------------------------------------------------
%   Date: 2018/10/12
%   Project: Load leveling project 
%   Edited by: Daisuke Kodaira 
%   Input: 
%   Output: 
% -------------------------------------------------------------------------------------------------------

clearvars;
close all;
clc;

%% Include modules for PSO
addpath(genpath('./pso_base'));
addpath('./custom_code');
addpath('../');
savepath;
global_var_declare; % Declare the global variables
simul_1_data_config; % Load parameters
tic;
for day = 1:g_days

    %% Update SOC
    if day == 1
        g_SocDayStart = g_initial_SOC;
    else
        g_SocDayStart = SOC(end,:);
    end
    
    %% Calculate ESS schedule
    % PSO calculation
    % "run_pso" returns optimum solutions which are given as pso_out
    predLoad = g_predLoad(:, day);
    obsrLoad = g_obsrLoad(:, day);
    g_upperCIOneDay = g_upperCI(:, day);
    lowerCI = g_lowerCI(:, day);    
    
    run_pso;
    pso_out(size(pso_out,1)) = []; % optimized ESS schedules

    %% Arrange the data for graph
    % ESS schedule
    out_reshape = transpose(reshape(pso_out,[24,2]));

    % Power flow on feeder including ESS operations
    [rawPredLoad(day).data] = load_calc(predLoad, zeros(g_num_ESS,24));           % Power flow at each position without ESS operation for predicted load
    [rawObsrLoad(day).data] = load_calc(obsrLoad, zeros(g_num_ESS,24));           % Power flow at each position without ESS operation for predicted load
    [adjPredLoad(day).data] = load_calc(predLoad, out_reshape);                           % Power flow at each position with ESS operation for predicted load
    [adjObsrLoad(day).data] = load_calc(obsrLoad, out_reshape);                            % Power flow at each position with ESS operation for observed load
    [rawUpCI(day).data] = load_calc(g_upperCIOneDay, zeros(g_num_ESS,24));
    [rawLoCI(day).data] = load_calc(lowerCI, zeros(g_num_ESS,24));
    [adjUpCI(day).data] = load_calc(g_upperCIOneDay, out_reshape);
    [adjLoCI(day).data] = load_calc(lowerCI, out_reshape);
    

    % Combied ESS schedule
    for i = 1:g_num_ESS
        ESS_opt(:,i) = transpose(repelem(out_reshape(i,:),g_coef));
    end
    
    %% File Output
    if day ==1;
        SOC = g_initial_SOC;    % SOC [kwh]
    else
        SOC = ESS_SOC(day-1).data(end,:)/100.*g_ESS_capacity;  % SOC [kwh]
    end
        
    for i = 1:g_num_ESS
        ESS_schedule(day).data(:,i) = transpose(repelem(out_reshape(i,:),4));
        for j = 1:24*4
            SOC(j+1,i) = SOC(j,i) + ESS_schedule(day).data(j,i).*0.25;   % optimized_ESS: "+" means charge,  "-" means discharge
        end
        ESS_SOC(day).data(:,i) = transpose(100*SOC(:,i)./g_ESS_capacity(i));    % SOC[%]
    end
    
    % Calculate Peak reduction
    peakReduction(day,:) = max(rawObsrLoad(day).data(:,1)) - max(adjObsrLoad(day).data(:,1)); % (+) Reduction, (-) Increase   
    
    p = round(day*100/g_days,1);
    X = [num2str(p), '%'];
    disp(X);

end
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
    
    % 0. Select which position is needed to be shown as graph?
    pos_graph = [1 0 0 0 0]; % [1 1 0] = [ture ture false].....Position 1 and 2 will be shown as graph
    name = {'Substation', 'ESS#1 left', 'ESS#1 right', 'ESS#2 left', 'ESS#2 right'};
    day =1;
    sigma=2; % 2É–=95% boundaries
    
    % for position = 1:g_num_ESS+3
    for position = 1:g_num_ESS+3
        if pos_graph(position) == 1
            % 01. Predicted load (raw observed load data)
            y(1).data = rawPredLoad(day).data(:,position);  % pick the position's load at the day
            y(1).name = 'Predicted Load (max)';  
            y(1).color = 'm';
            y(1).yaxis = 'left';
            y(1).linestyle = '-';
            y(1).descrp = [0 0]; % [1 0] = [ture false]
    
            % 02. Optimized load (observed load data + ESS operation)
            y(2).data = adjObsrLoad(day).data(:,position); 
            y(2).name = 'Adjusted observed Load';
            y(2).color = 'g';
            y(2).yaxis = 'left';
            y(2).linestyle = '-';
            y(2).descrp = [0 0];
    
            % 03. Observed load (raw observed load data)
            y(3).data = rawObsrLoad(day).data(:,position);
            y(3).name = 'Observed Load';
            y(3).color = 'm';
            y(3).yaxis = 'left';
            y(3).linestyle = '-';
            y(3).descrp = [0 0];
    
            % 04. Line capacity
            y(4).data = g_line_capacity*ones(size(predLoad,1),1);
            y(4).name = 'Line capacity';
            y(4).color = 'r';
            y(4).yaxis = 'left';
            y(4).linestyle = '-';
            y(4).graphno = 0; % both 1 and 2
            y(4).descrp = [0 0];
    
            % 05. SOC
            ESS_SOCForGraph = ESS_SOC;
            ESS_SOCForGraph(day).data(1, :) = [];
            for num = 1:g_num_ESS
                y(end+1).data = ESS_SOCForGraph(day).data(:,num);
                y(end).name = (['SOC ESS#',num2str(num)]);
                y(end).color = [0 0 0+0.5*(num-1)];
                y(end).yaxis = 'right';
                y(end).linestyle = '-';
                y(end).descrp = [1 0];
            end
    
            % 06. Probabilistic Interval before operation. (training data)      
            y(end+1).data = rawUpCI(day).data(:,position);
            y(end).name = 'Predicted PI order-basis';
            y(end).color = 'm';
            y(end).yaxis = 'left';
            y(end).linestyle = '--';
            y(end).descrp = [1 0];
            y(end+1).data = rawLoCI(day).data(:,position); % 2min: 1*24, 30 = 720   15min:1*24,4 = 96
            y(end).name = 'Predicted PI order-basis';
            y(end).color = 'm';
            y(end).yaxis = 'left';
            y(end).linestyle = '--';
            y(end).descrp = [1 0];
        
            % 07. Adjusted Probabilistic Interval after operation (training data + ess operation)
            y(end+1).data = adjUpCI(day).data(:,position); % 2min: 1*24, 30 = 720   15min:1*24,4 = 96
            y(end).name = 'Adjusted PI order-basis';
            y(end).color = 'g';
            y(end).yaxis = 'left';
            y(end).linestyle = '--';
            y(end).descrp = [1 0]; 
            y(end+1).data = adjLoCI(day).data(:,position); % 2min: 1*24, 30 = 720   15min:1*24,4 = 96
            y(end).name = 'Adjusted PI order-basis';
            y(end).color = 'g';
            y(end).yaxis = 'left';
            y(end).linestyle = '--';
            y(end).descrp = [1 0]; 
                          
            % set initial y value
            y(5).data = [50; y(5).data];
            y(6).data = [50; y(6).data];
% %             y(7).data = [g_initial_SOC y(5).data];
            graph_desc(y, g_ProbPredLoad, name(position));
    
%             % Calculate peak
%             % pick the peak in all the trained data set
%             [a, phour(1)] = max(rawObsrLoad(day).data(:,position));
%             peak_hour(1) = fix(phour(1)/4);   % peak hour
%             observed_peak = max(max(obsrLoad));
%             [a, phour(2)] = max(adjObsrLoad(day).data(:,position));
%             peak_hour(2) = fix(phour(2)/4);
%             adjObserved_peak = max(max(adjObsrLoad(day).data(:,position)));  % peak among whole days
%             % Table
%             LastName = {char(strcat('Observed load (', name(position), ')')); char(strcat('Adjusted Observed load (', name(position), ')'))};
%             Peak_at_Substation = [observed_peak peak_hour(1); adjObserved_peak peak_hour(2)];
%             table(Peak_at_Substation,'RowNames',LastName)
    
%             clear y;
        end
    end



for x = 1:g_days
    ESS1_schedule(:,x) = ESS_schedule(x).data(:,1); % ESS#1
    ESS2_schedule(:,x) = ESS_schedule(x).data(:,2); % ESS#2
    ESS1_SOC(:,x) = ESS_SOC(x).data(:,1); % ESS#1
    ESS2_SOC(:,x) = ESS_SOC(x).data(:,2); % ESS#2
    raw_train_load(:,x) = rawPredLoad(x).data(:,1);
    raw_test_load(:,x) = rawObsrLoad(x).data(:,1);    
    adj_train_load1(:,x) = adjPredLoad(x).data(:,1);    % position = 1
    adj_test_load1(:,x) = adjObsrLoad(x).data(:,1);
end

filename_w1 = 'ESS_inout_MW.xlsx';
xlswrite(filename_w1, ESS1_schedule,1,'B5');        % Sheet1: Write T-node(1) original energy[wh] power consumption
xlswrite(filename_w1, ESS2_schedule,2,'B5');        % Sheet1: Write T-node(1) original energy[wh] power consumption

filename_w2 = 'ESS_SOC.xlsx';
xlswrite(filename_w2, ESS1_SOC,1,'B5');        % Sheet1: Write T-node(1) original energy[wh] power consumption
xlswrite(filename_w2, ESS2_SOC,2,'B5');        % Sheet1: Write T-node(1) original energy[wh] power consumption

filename_w3 = 'Adjusted predicted load.xlsx';
xlswrite(filename_w3,raw_train_load,1,'B2');     % adjusted train(prediction)
xlswrite(filename_w3,transpose(1:g_steps),1,'A2');      
xlswrite(filename_w3,adj_train_load1,2,'B2');    % raw traing      
xlswrite(filename_w3,transpose(1:g_steps),2,'A2');    

filename_w4 = 'Adjusted observed load.xlsx';
xlswrite(filename_w4, raw_test_load, 1, 'B2');       
xlswrite(filename_w4, transpose(1:g_steps),1,'A2');      
xlswrite(filename_w4, adj_test_load1,2,'B2');        
xlswrite(filename_w4, transpose(1:g_steps),2,'A2');     

filename_w5 = 'Preak reduction.xlsx';
xlswrite(filename_w5, peakReduction, 1, 'A2');  % Excel sheet (+) Reduction, (-) Increase

% histogram for peak reduction
figure;
data = xlsread('Preak reduction.xlsx');
histogram(data*-1,'Normalization','probability'); % Histogram: (-) Reduction, (+) Increase
xlabel('Peak variation [MW]');
ylabel('Probability')

beep;


