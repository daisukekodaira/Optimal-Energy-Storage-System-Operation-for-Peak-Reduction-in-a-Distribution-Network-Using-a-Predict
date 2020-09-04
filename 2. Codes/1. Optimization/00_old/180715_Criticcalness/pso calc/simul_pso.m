% -------------------------------------------------------------------------------------------------------
%   Date: 2017/07/15
%   Project: Load leveling project 
%   Edited by: Daisuke Kodaira (email: daisuke.kodaira03@gmail.com)
% -------------------------------------------------------------------------------------------------------

%% Initialization
clearvars;
close all;
tic;

%% Include modules for PSO
addpath(genpath('./pso_base'));
addpath('./custom_code');
addpath('../');
savepath;

%% Reading parameters
global_var_declare; % Declare the global variables
simul_1_data_config; % Load parameters

%% Calculate ESS schedule
% Calculate the power flow on the feeder
[raw_train_load] = load_calc(g_load_train, zeros(g_num_ESS,24));
% Get the boundaries(upper and lower) for each hour at each point in 24 hours
% pred_min, pred_max: row=days
[pred_min, pred_max] = GetBoundary_order(raw_train_load, g_percent);
    
for day = 1:g_days
    % Update SOC for next day
    if day == 1
        g_current_SOC = g_initial_SOC;
    else
        g_current_SOC = ESS_SOC(day-1).data(end,:)/100.*g_ESS_capacity;
    end
    
    % PSO calculation
    g_pred_min = cell2mat(struct2cell(pred_min(day)));     % convert structure to matrix
    g_pred_max = cell2mat(struct2cell(pred_max(day)));
    run_pso;
    pso_out(size(pso_out,1)) = []; % "pso_out" is optimized ESS schedules
        
    % ESS schedule(MW): first row=ESS#1, seconde row=ESS#2
    ess_operation = reshape(pso_out, [g_num_ESS, g_s_period]);
    out_reshape = transpose(ess_operation);
    for i = 1:g_num_ESS
        ESS_opt(day).data(:,i) = transpose(repelem(ess_operation(i,:),g_coef));
    end

    % Calculate SOC
    soc = g_current_SOC;
    for i = 1:g_num_ESS
        ESS_schedule(day).data(:,i) = transpose(repelem(ess_operation(i,:),4));
        for j = 1:24*4
            soc(j+1,i) = soc(j,i) + ESS_schedule(day).data(j,i).*0.25;   % optimized_ESS: "+" means charge,  "-" means discharge
        end
        ESS_SOC(day).data(:,i) = transpose(100*soc(:,i)./g_ESS_capacity(i));
    end
    g_current_SOC = soc(end,:);
    
    % display the process
    p = round(day*100/g_days,1);
    X = [num2str(p), '%'];
    disp(X);
    
end

% Calculate observed Power flow without ESS operations
[raw_test_load] = distribute_sub_load(g_load_test); % for test(unknown, future) data

% Calculate observed and past Power flow on feeder with ESS operations
[adj_train_load] = load_calc(g_load_train, ess_operation); % for training data
[valid_flow] = load_calc(g_load_test, ess_operation); % for test(unknown,future) data


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
            % 01. Predicted load: mean load of each time step (Take mean value of each PDF) (1*720 matrix)
            if size(g_load_train(:,day),2) == 1
                y(1).data = transpose(raw_train_load(position).data(:,day));   % load_pred in case that test is only one day
            else
                y(1).data = max(max(transpose(raw_train_load(position).data(:,day))));   % load_pred
            end
            y(1).name = 'Predicted Load (max)';   % mean of plobablistic predictions
            y(1).color = 'm';
            y(1).yaxis = 'left';
            y(1).linestyle = '-';
            y(1).descrp = [0 0]; % [1 0] = [ture false]
    
            % 02. Optimized load (test load data + ESS operation)
            y(2).data = transpose(valid_flow(position).data(:,day)); %load_opt
            y(2).name = 'Adjusted observed Load';
            y(2).color = 'g';
            y(2).yaxis = 'left';
            y(2).linestyle = '-';
            y(2).descrp = [0 0];
    
            % 03. Test load (raw test load data)
            y(3).data = transpose(raw_test_load(position).data);
            y(3).name = 'Observed Load';
            y(3).color = 'm';
            y(3).yaxis = 'left';
            y(3).linestyle = '-';
            y(3).descrp = [0 0];
    
            % 04. Line capacity
            y(4).data = g_line_capacity*ones(1,g_steps);
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
                y(end+1).data = repelem(ESS_SOCForGraph(day).data(:,num), 15)';
                y(end).name = (['SOC ESS#',num2str(num)]);
                y(end).color = [0 0 0+0.5*(num-1)];
                y(end).yaxis = 'right';
                y(end).linestyle = '-';
                y(end).descrp = [1 0];
            end
    
            % 06. Probabilistic Interval before operation. (training data)
            %       derived from order-basis boundaries  
            [rawLowBoundOrder, rawUpBoundOrder] = GetBoundary_order(raw_train_load, g_percent);
            y(end+1).data = repelem(rawUpBoundOrder(day).data(position,:), g_coef); % 2min: 1*24, 30 = 720   15min:1*24,4 = 96
            y(end).name = 'Predicted PI order-basis';
            y(end).color = 'm';
            y(end).yaxis = 'left';
            y(end).linestyle = '--';
            y(end).descrp = [1 0];
            y(end+1).data = repelem(rawLowBoundOrder(day).data(position,:), g_coef); % 2min: 1*24, 30 = 720   15min:1*24,4 = 96
            y(end).name = 'Predicted PI order-basis';
            y(end).color = 'm';
            y(end).yaxis = 'left';
            y(end).linestyle = '--';
            y(end).descrp = [1 0];
    
            % 07. Probabilistic Interval before operation. (training data)
            %       derived from Normal distribution basis boundaries  
            [rawLowBoundNormal, rawUpBoundNormal] = GetBoundary_NomalDist(raw_train_load, sigma);
            y(end+1).data = repelem(rawUpBoundNormal(day).data(position,:), g_coef); % 2min: 1*24, 30 = 720   15min:1*24,4 = 96
            y(end).name = 'Predicted PI NormalDist-basis';
            y(end).color = 'r';
            y(end).yaxis = 'left';
            y(end).linestyle = '-.';
            y(end).descrp = [0 0];
            y(end+1).data = repelem(rawLowBoundNormal(day).data(position,:), g_coef); % 2min: 1*24, 30 = 720   15min:1*24,4 = 96
            y(end).name = 'Predicted PI NormalDist-basis';
            y(end).color = 'r';
            y(end).yaxis = 'left';
            y(end).linestyle = '-.';
            y(end).descrp = [0 0];
    
            % 08. Adjusted Probabilistic Interval after operation (training data + ess operation)
            %       derived from order-basis boundaries  
            [adjLowBoundOrder, adjUpBoundOrder] = GetBoundary_order(adj_train_load, g_percent);   % mx has 5*24, mn has 5*24    
            y(end+1).data = repelem(adjUpBoundOrder(day).data(position,:),g_coef); % 2min: 1*24, 30 = 720   15min:1*24,4 = 96
            y(end).name = 'Adjusted PI order-basis';
            y(end).color = 'g';
            y(end).yaxis = 'left';
            y(end).linestyle = '--';
            y(end).descrp = [1 0]; 
            y(end+1).data = repelem(adjLowBoundOrder(day).data(position,:),g_coef); % 2min: 1*24, 30 = 720   15min:1*24,4 = 96
            y(end).name = 'Adjusted PI order-basis';
            y(end).color = 'g';
            y(end).yaxis = 'left';
            y(end).linestyle = '--';
            y(end).descrp = [1 0]; 
    
            % 09. Adjusted Probabilistic Interval after operation (training data + ess operation)
            %       derived from  Normal distribution basis boundaries  
            [adjLowBoundNormal, adjUpBoundNormal] = GetBoundary_NomalDist(adj_train_load, g_percent);   % mx has 5*24, mn has 5*24    
            y(end+1).data = repelem(adjUpBoundNormal(day).data(position,:),g_coef); % 2min: 1*24, 30 = 720   15min:1*24,4 = 96
            y(end).name = 'Adjusted PI NormalDist-basis';
            y(end).color = 'b';
            y(end).yaxis = 'left';
            y(end).linestyle = '-.';
            y(end).descrp = [0 0]; 
            y(end+1).data = repelem(adjLowBoundNormal(day).data(position,:),g_coef); % 2min: 1*24, 30 = 720   15min:1*24,4 = 96
            y(end).name = 'Adjusted PI NormalDist-basis';
            y(end).color = 'b';
            y(end).yaxis = 'left';
            y(end).linestyle = '-.';
            y(end).descrp = [0 0]; 
            
            % 10. Heatmap
            y(end+1).descrp = [1 0];
    
            %------------------------------------------------------------------------------------------
            graph_desc(y, raw_train_load(position).data(:, day), adj_train_load(position).data(:,day), name(position));
    
            % Calculate peak
            % pick the peak in all the trained data set
            [pred_peak, peak_hour(1)] = max(max(raw_train_load(position).data));
            [adjusted_peak, peak_hour(2)] = max(max(adj_train_load(position).data));  % peak among whole days
            % Table
            LastName = {char(strcat('Predicted load (', name(position), ')')); char(strcat('Adjusted load (', name(position), ')'))};
            Peak_at_Substation = [pred_peak peak_hour(1); adjusted_peak peak_hour(2)];
            table(Peak_at_Substation,'RowNames',LastName)
    
%             clear y;
        end
    end
    
    % ---------------------------------------------------------------------------------------
    % Figure2: Histgram of prediction in 24 hours 
    % 1. Predicted load 
    % -----------------------------------------------------------------------------------
    % histogram_desc(g_flag_hist,raw_train_load(1).data, 'raw_train'); % disply the histogram or not. True = 1, False =0
    % histogram_desc(g_flag_hist,adj_train_load(1).data, 'adj_train'); % disply the histogram or not. True = 1, False =0
    
    % ---------------------------------------------------------------------------------------
    % Figure3: Confidence interval 
    % -----------------------------------------------------------------------------------
    if g_flag_hist ~= 0
        CI_name_raw=strcat('PDF_raw_',num2str(g_percent),'%');
        CI_name_adj=strcat('PDF_adj_',num2str(g_percent),'%');
        histo_name_raw=strcat('histogram_raw_',num2str(g_percent),'%');
        histo_name_adj=strcat('histogram_adj_',num2str(g_percent),'%');
        CI_desc(raw_train_load(1).data, CI_name_raw, histo_name_raw, g_percent)
        CI_desc(adj_train_load(1).data, CI_name_adj, histo_name_adj, g_percent)
    end



for x = 1:g_days
    ESS1_schedule(:,x) = ESS_schedule(x).data(:,1); % ESS#1
    ESS2_schedule(:,x) = ESS_schedule(x).data(:,2); % ESS#2
    ESS1_SOC(:,x) = ESS_SOC(x).data(:,1); % ESS#1
    ESS2_SOC(:,x) = ESS_SOC(x).data(:,2); % ESS#2
    adj_train_load1(:,x) = adj_train_load(1).data(:,x);
    adj_test_load1(:,x) = valid_flow(1).data(:,x);
end

filename_w1 = 'ESS_inout_MW.xlsx';
xlswrite(filename_w1, ESS1_schedule,1,'B5');        % Sheet1: Write T-node(1) original energy[wh] power consumption
xlswrite(filename_w1, ESS2_schedule,2,'B5');        % Sheet1: Write T-node(1) original energy[wh] power consumption

filename_w2 = 'ESS_SOC.xlsx';
xlswrite(filename_w2, ESS1_SOC,1,'B5');        % Sheet1: Write T-node(1) original energy[wh] power consumption
xlswrite(filename_w2, ESS2_SOC,2,'B5');        % Sheet1: Write T-node(1) original energy[wh] power consumption

filename_w3 = 'Adjusted training load.xlsx';
xlswrite(filename_w3,g_load_train,1,'B2');      
xlswrite(filename_w3,transpose(1:g_steps),1,'A2');      
xlswrite(filename_w3,adj_train_load1,2,'B2');      
xlswrite(filename_w3,transpose(1:g_steps),2,'A2');    

filename_w4 = 'Adjusted test load.xlsx';
xlswrite(filename_w4, g_load_test, 1, 'B2');       
xlswrite(filename_w4, transpose(1:g_steps),1,'A2');      
xlswrite(filename_w4, adj_test_load1,2,'B2');        
xlswrite(filename_w4, transpose(1:g_steps),2,'A2');     
    


beep;
toc;

