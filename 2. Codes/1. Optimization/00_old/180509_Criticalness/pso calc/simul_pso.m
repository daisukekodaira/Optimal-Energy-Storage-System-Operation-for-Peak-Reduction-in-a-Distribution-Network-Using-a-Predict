% -------------------------------------------------------------------------------------------------------
%   Date: 2017/04/27
%   Project: Load leveling project 
%   Edited by: Daisuke Kodaira 
%   Input: Classified histgram load data which is obtaned by Baye's theorim(?)
%   Output: ESS operation schedule which minimizes the global criticalness
% -------------------------------------------------------------------------------------------------------

clearvars;
close all;
tic;

%% Include modules for PSO
addpath(genpath('./pso_base'));
addpath('./custom_code');
addpath('../');
savepath;
global_var_declare; % Declare the global variables
simul_1_data_config; % Load parameters

for day = 1:g_days
    p = round(day*100/g_days,1);
    X = [num2str(p), '%'];
    disp(X);
    %% Calculate ESS schedule
    % PSO calculation
    % "run_pso" returns optimum solutions which are given as pso_out
    train_load = g_load_train(:, day);
    test_load = g_load_test(:, day);
    [raw_train_load] = load_calc(train_load, zeros(g_num_ESS,24));
    [g_pred_min, g_pred_max] = Confd_range_af(raw_train_load, g_percent);
    run_pso;
    pso_out(size(pso_out,1)) = []; % optimized ESS schedules

    %% Arrange the data for graph
    % ESS schedule
    out_reshape = transpose(reshape(pso_out,[24,2]));

    % Power flow on feeder including ESS operations
    [adj_train_load(:, day)] = load_calc(train_load, out_reshape);
    [valid_flow(:, day)] = load_calc(test_load, out_reshape);

    % Combied ESS schedule
    for i = 1:g_num_ESS
        ESS_opt(:,i) = transpose(repelem(out_reshape(i,:),g_coef));
    end

    % Raw power flow without ESS operations
    [raw_test_load] = distribute_sub_load(test_load); % ?????

%     %% Graph description
%     % ---------------------------------------------------------------------------------------
%     % Figure1: Result of optimized load
%     % 01. Predicted load: mean load of each time step 
%     % 02. Optimized load (test load data + ESS operation) (probabilistic)
%     % 03. Test load (raw test load data)
%     % 04. Line capacity
%     % 05. SOC variance
%     % 06. Original Confidence range  (training data)_before
%     % 07. Original Confidence range  (training data)_after
%     % 08. Adjusted Confidence range (training data + ess operation)_before
%     % 09. Adjusted range (training data + ess operation)_after
%     % 10. Heatmap
%     % ---------------------------------------------------------------------------------------
%     
%     % 0. Select which position is needed to be shown as graph?
%     pos_graph = [1 0 0 0 0]; % [1 1 0] = [ture ture false].....Position 1 and 2 will be shown as graph
%     name = {'Substation', 'ESS#1 left', 'ESS#1 right', 'ESS#2 left', 'ESS#2 right'};
%     
%     % for position = 1:g_num_ESS+3
%     for position = 1:g_num_ESS+3
%         if pos_graph(position) == 1
%             % 1. Predicted load: mean load of each time step (Take mean value of each PDF) (1*720 matrix)
%             if size(train_load,2) == 1
%                 y(1).data = transpose(raw_train_load(position).data);   % load_pred in case that test is only one day
%             else
%                 y(1).data = max(max(transpose(raw_train_load(position).data)));   % load_pred
%             end
%             y(1).name = 'Predicted Load (max)';   % mean of plobablistic predictions
%             y(1).color = 'm';
%             y(1).yaxis = 'left';
%             y(1).linestyle = '-';
%             y(1).descrp = [0 0]; % [1 0] = [ture false]
%     
%             % 2. Optimized load (test load data + ESS operation)
%             y(2).data = transpose(valid_flow(position).data); %load_opt
%             y(2).name = 'Adjusted Actual Load';
%             y(2).color = 'g';
%             y(2).yaxis = 'left';
%             y(2).linestyle = '-';
%             y(2).descrp = [0 0];
%     
%             % 3. Test load (raw test load data)
%             y(3).data = transpose(raw_test_load(position).data);
%             y(3).name = 'Actual Load';
%             y(3).color = 'm';
%             y(3).yaxis = 'left';
%             y(3).linestyle = '-';
%             y(3).descrp = [0 0];
%     
%             % 4. Line capacity
%             y(4).data = g_line_capacity*ones(1,g_steps);
%             y(4).name = 'Line capacity';
%             y(4).color = 'r';
%             y(4).yaxis = 'left';
%             y(4).linestyle = '-';
%             y(4).graphno = 0; % both 1 and 2
%             y(4).descrp = [0 0];
%     
%             % 5. SOC
%             SOC = g_initial_SOC;
%             for i = 1:g_steps
%                     SOC(i+1,:) = SOC(i,:) + ESS_opt(i,:)/g_coef;   % optimized_ESS: "+" means charge,  "-" means discharge
%             end
%             SOC(1,:) = []; % erase the initial status for the graph description
%             for num = 1:g_num_ESS
%                 y(end+1).data = transpose(100*SOC(:,num)./g_ESS_capacity(num));
%                 y(end).name = (['SOC ESS#',num2str(num)]);
%                 y(end).color = [0 0 0+0.5*(num-1)];
%                 y(end).yaxis = 'right';
%                 y(end).linestyle = '-';
%                 y(end).descrp = [1 0];
%             end
%     
%             % 6. Original range  (training data)_before
%             [orig_mn_be, orig_mx_be] = Confd_range_be(raw_train_load);
%             y(end+1).data = repelem(orig_mx_be(position,:), g_coef); % 2min: 1*24, 30 = 720   15min:1*24,4 = 96
%             y(end).name = 'Predicted range';
%             y(end).color = 'm';
%             y(end).yaxis = 'left';
%             y(end).linestyle = '--';
%             y(end).descrp = [0 0];
%             y(end+1).data = repelem(orig_mn_be(position,:), g_coef); % 2min: 1*24, 30 = 720   15min:1*24,4 = 96
%             y(end).name = 'Predicted range';
%             y(end).color = 'm';
%             y(end).yaxis = 'left';
%             y(end).linestyle = '--';
%             y(end).descrp = [0 0];
%     
%             % 7. Original range  (training data)_after
%             [orig_mn_af, orig_mx_af] = Confd_range_af(raw_train_load,g_percent);
%             y(end+1).data = repelem(orig_mx_af(position,:), g_coef); % 2min: 1*24, 30 = 720   15min:1*24,4 = 96
%             y(end).name = 'Predicted range';
%             y(end).color = 'r';
%             y(end).yaxis = 'left';
%             y(end).linestyle = '-.';
%             y(end).descrp = [1 0];
%             y(end+1).data = repelem(orig_mn_af(position,:), g_coef); % 2min: 1*24, 30 = 720   15min:1*24,4 = 96
%             y(end).name = 'Predicted range';
%             y(end).color = 'r';
%             y(end).yaxis = 'left';
%             y(end).linestyle = '-.';
%             y(end).descrp = [1 0];
%     
%             % 8. Adjusted range (training data + ess operation)_before
%             [adj_mn, adj_mx] = Confd_range_be(adj_train_load);   % mx has 5*24, mn has 5*24    
%             y(end+1).data = repelem(adj_mx(position,:),g_coef); % 2min: 1*24, 30 = 720   15min:1*24,4 = 96
%             y(end).name = 'Adjusted predicted range';
%             y(end).color = 'g';
%             y(end).yaxis = 'left';
%             y(end).linestyle = '--';
%             y(end).descrp = [0 0]; 
%             y(end+1).data = repelem(adj_mn(position,:),g_coef); % 2min: 1*24, 30 = 720   15min:1*24,4 = 96
%             y(end).name = 'Adjusted predicted range';
%             y(end).color = 'g';
%             y(end).yaxis = 'left';
%             y(end).linestyle = '--';
%             y(end).descrp = [0 0]; 
%     
%             % 9. Adjusted range (training data + ess operation)_after
%             [adj_mn, adj_mx] = Confd_range_af(adj_train_load,g_percent);   % mx has 5*24, mn has 5*24    
%             y(end+1).data = repelem(adj_mx(position,:),g_coef); % 2min: 1*24, 30 = 720   15min:1*24,4 = 96
%             y(end).name = 'Adjusted predicted range';
%             y(end).color = 'b';
%             y(end).yaxis = 'left';
%             y(end).linestyle = '-.';
%             y(end).descrp = [1 0]; 
%             y(end+1).data = repelem(adj_mn(position,:),g_coef); % 2min: 1*24, 30 = 720   15min:1*24,4 = 96
%             y(end).name = 'Adjusted predicted range';
%             y(end).color = 'b';
%             y(end).yaxis = 'left';
%             y(end).linestyle = '-.';
%             y(end).descrp = [1 0]; 
%             
%             % 10. Heatmap
%             y(end+1).descrp = [1 0];
%     
%             %------------------------------------------------------------------------------------------
%             graph_desc(y, raw_train_load(position).data, adj_train_load(position).data, name(position));
%     
%             % Calculate peak
%             [pred_peak, peak_hour(1)] = max(orig_mx_be(1,:));
%             [adjusted_peak, peak_hour(2)] = max(adj_mx(1,:));  % peak among whole days
%             % Table
%             LastName = {char(strcat('Predicted load (', name(position), ')')); char(strcat('Adjusted load (', name(position), ')'))};
%             Peak_at_Substation = [pred_peak peak_hour(1); adjusted_peak peak_hour(2)];
%             table(Peak_at_Substation,'RowNames',LastName)
%     
%             clear y;
%         end
%     end
%     
%     % ---------------------------------------------------------------------------------------
%     % Figure2: Histgram of prediction in 24 hours 
%     % 1. Predicted load 
%     % -----------------------------------------------------------------------------------
%     % histogram_desc(g_flag_hist,raw_train_load(1).data, 'raw_train'); % disply the histogram or not. True = 1, False =0
%     % histogram_desc(g_flag_hist,adj_train_load(1).data, 'adj_train'); % disply the histogram or not. True = 1, False =0
%     
%     % ---------------------------------------------------------------------------------------
%     % Figure3: Confidence interval 
%     % -----------------------------------------------------------------------------------
%     if g_flag_hist ~= 0
%         CI_name_raw=strcat('PDF_raw_',num2str(g_percent),'%');
%         CI_name_adj=strcat('PDF_adj_',num2str(g_percent),'%');
%         histo_name_raw=strcat('histogram_raw_',num2str(g_percent),'%');
%         histo_name_adj=strcat('histogram_adj_',num2str(g_percent),'%');
%         CI_desc(raw_train_load(1).data, CI_name_raw, histo_name_raw, g_percent)
%         CI_desc(adj_train_load(1).data, CI_name_adj, histo_name_adj, g_percent)
%     end
     
    
    %% File Output
    if day ==1;
        SOC = g_initial_SOC;
    else
        SOC = ESS_SOC(day-1).data(end,:)/100.*g_ESS_capacity;
    end
        
    for i = 1:g_num_ESS
        ESS_schedule(day).data(:,i) = transpose(repelem(out_reshape(i,:),4));
        for j = 1:24*4
            SOC(j+1,i) = SOC(j,i) + ESS_schedule(day).data(j,i).*0.25;   % optimized_ESS: "+" means charge,  "-" means discharge
        end
        ESS_SOC(day).data(:,i) = transpose(100*SOC(:,i)./g_ESS_capacity(i));
    end

end

for x = 1:g_days
    ESS1_schedule(:,x) = ESS_schedule(x).data(:,1); % ESS#1
    ESS2_schedule(:,x) = ESS_schedule(x).data(:,2); % ESS#2
    ESS1_SOC(:,x) = ESS_SOC(x).data(:,1); % ESS#1
    ESS2_SOC(:,x) = ESS_SOC(x).data(:,2); % ESS#2
    adj_train_load1(:,x) = adj_train_load(1,x).data;
    adj_test_load1(:,x) = valid_flow(1,x).data;
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

