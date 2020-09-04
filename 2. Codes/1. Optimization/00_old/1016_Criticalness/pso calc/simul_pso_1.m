% -------------------------------------------------------------------------------------------------------
%   Date: 2017/04/27
%   Project: Load leveling project 
%   Edited by: Daisuke Kodaira 
%   Input: Classified histgram load data which is obtaned by Baye's theorim(?)
%   Output: ESS operation schedule which minimizes the global criticalness
% -------------------------------------------------------------------------------------------------------

clear; close all;
tic;
% profile on;

%% Include modules for PSO
addpath(genpath('./pso_base'));
addpath('./custom_code');
addpath('../');
savepath;
global_var_declare; % Declare the global variables
simul_1_data_config; % Load parameters

%% Safe check
% Check whether predicted load has possibility to exceed the capacity.
[non_ope, L_critical_orig] = safe_or_not;

%% Calculate ESS schedule
if non_ope == 1
    pso_out = transpose(zeros(1,g_s_period*2));
else
    % PSO calculation
    % "run_pso" returns optimum solutions which are given as pso_out
    run_pso;
    pso_out(size(pso_out,1)) = []; % optimized ESS schedules    
end

%% Evaluation of ESS operation
% Count of Switiching 
switching_cost = 0;
for i = 2:g_s_period
    if pso_out(i) < 0
        if pso_out(i-1) > 0
            switching_cost = switching_cost + 1;
        end
    else 
        if pso_out(i-1) < 0
            switching_cost = switching_cost + 1;
        end                
    end
end
sprintf('Switching count : %d', switching_cost)

%% Arrange the data for graph
% ESS schedule
out_reshape = transpose(reshape(pso_out,[24,2]));
% Power flow on feeder including ESS operations
[flow_on_feeder] = load_calc(g_load_test, out_reshape);
% Combied ESS schedule
for i = 1:g_num_ESS
    ESS_opt(:,i) = transpose(repelem(out_reshape(i,:),g_coef));   
end

% Raw power flow without ESS operations
[raw_train_load] = load_calc(g_load_train, zeros(size(ESS_opt,1),size(ESS_opt,2))); % give all ESS=0
% plot(raw_train_load(2).data);
[raw_test_load] = distribute_sub_load(g_load_test);

%% Graph description
% ---------------------------------------------------------------------------------------
% Figure1: Result of optimized load
% 1. Test load (deterministic): to be predicted. 
% 2. Predicted load (probabilistic): Prediction is provided as PDF whose mean value is described
% 3. Optimized load (deterministic): The result for the predicted load(PDFs)
% 4. Line capacity
% 5. SOC variance
% 6. Adjusted Criticalness (training + ess_opt)
% 7. Original Criticalness (criticalness of predicted load (=training data))
% 8. Adjusted Predicted load
% 9. 
% ---------------------------------------------------------------------------------------

% 0. Select which position is needed to be shown as graph?
pos_graph = [1 1 1 1 1]; % [1 1 0] = [ture ture false].....Position 1 and 2 will be shown as graph
name = {'Initial', 'ESS#1 left', 'ESS#1 right', 'ESS#2 left', 'ESS#2 right'};

% for position = 1:g_num_ESS+3
for position = 1:1
    if pos_graph(position) == 1 
        % 1. Predicted load: mean load of each time step (Take mean value of each PDF) (1*720 matrix)
        if size(g_load_train,2) == 1
            y(1).data = transpose(raw_train_load(position).data);   % load_pred in case that test is only one day
        else
            y(1).data = median(transpose(raw_train_load(position).data));   % load_pred
        end
        y(1).name = 'Predicted Load (mean)';   % mean of plobablistic predictions
        y(1).color = 'm';
        y(1).yaxis = 'left';
        y(1).linestyle = '-';
        y(1).descrp = [0 0]; % [1 0] = [ture false]

        % 2. Optimized load
        y(2).data = transpose(flow_on_feeder(position).data); %load_opt
        y(2).name = 'Adjusted Actual Load';
        y(2).color = 'g';
        y(2).yaxis = 'left';
        y(2).linestyle = '-';
        y(2).descrp = [0 0]; 

        % 3. Test load (ture load)
        y(3).data = transpose(raw_test_load(position).data);
        y(3).name = 'Actual Load';
        y(3).color = 'm';
        y(3).yaxis = 'left';
        y(3).linestyle = '-';
        y(3).descrp = [0 0]; 

        % 4. Line capacity
        y(4).data = g_line_capacity*ones(1,g_steps);
        y(4).name = 'Line capacity';
        y(4).color = 'r';
        y(4).yaxis = 'left';
        y(4).linestyle = '-';
        y(4).graphno = 0; % both 1 and 2
        y(4).descrp = [1 1]; 

        % 5. SOC
        SOC = g_initial_SOC;
        for i = 1:g_steps
                SOC(i+1,:) = SOC(i,:) + ESS_opt(i,:)/30;   % optimized_ESS: "+" means charge,  "-" means discharge
        end
        SOC(1,:) = []; % erase the initial status for the graph description
        for num = 1:g_num_ESS
            y(end+1).data = transpose(100*SOC(:,num)./g_ESS_capacity(num));
            y(end).name = (['SOC ESS#',num2str(num)]);
            y(end).color = [0 0 0+0.5*(num-1)];
            y(end).yaxis = 'right';
            y(end).linestyle = '-';
            y(end).descrp = [1 1]; 
        end
        
        % 6. Adjusted Criticalness (training + ess_opt)
        L_critical_best = round(g_L_critical_best(position,:),1);
        normalized_adj_crit = 100*L_critical_best/max(L_critical_orig(1,:));
        if isnan(normalized_adj_crit)
            normalized_adj_crit = zeros(size(normalized_adj_crit,1),size(normalized_adj_crit,2));
        end
        y(end+1).data = repelem(normalized_adj_crit,g_coef);
        y(end).name = 'Adjusted criticalness (for predicted load)';
        y(end).color = 'g';
        y(end).yaxis = 'right';
        y(end).linestyle = '--';
        y(end).descrp = [1 1]; 

        % 7. Original Criticalness (criticalness of predicted load (=training data))
        normalized_orig_crit = 100*L_critical_orig(position,:)/max(L_critical_orig(1,:));
        if isnan(normalized_orig_crit)
            normalized_orig_crit = zeros(size(normalized_orig_crit,1),size(normalized_orig_crit,2));
        end
        y(end+1).data = repelem(normalized_orig_crit,g_coef);
        y(end).name = 'Predicted criticalness';
        y(end).color = 'm';
        y(end).yaxis = 'right';
        y(end).linestyle = '--';
        y(end).descrp = [1 1];

        % 8. Adjusted Predicted load
        adj_load =  load_calc(raw_train_load(1).data, ESS_opt); 
        if size(g_load_train,2) == 1
            y(end+1).data = transpose(adj_load(position).data);   % (1*720): median of all training days
        else
            y(end+1).data = median(transpose(adj_load(position).data));   % load_pred
        end
        y(end).name = 'Adjusted Predicted load';
        y(end).color = 'g';
        y(end).yaxis = 'left';
        y(end).linestyle = '-';
        y(end).descrp = [0 0]; 

        %------------------------------------------------------------------------------------------
        graph_desc(y, raw_train_load(position).data, adj_load(position).data, name(position));

        % Calculate peak
        act_peak = max(raw_test_load(position).data);
        pred_peak = max(y(1).data);
        adjusted_peak = max(flow_on_feeder(position).data);  % peak among whole days
        % Table
        LastName = {char(strcat('Predicted load (', name(position), ')')); char(strcat('Actual load (', name(position), ')')); char(strcat('Adjusted load (', name(position), ')'))};
        Peak = [pred_peak; act_peak; adjusted_peak];
        table(Peak,'RowNames',LastName)
        
%         clear y;
    end
end
% % ---------------------------------------------------------------------------------------
% % Figure2: Temperature
% % y(1): Line tempreature with ESS for test load
% % y(2): Line tempreature without ESS for test load
% % -----------------------------------------------------------------------------------
% if g_flag_crit == 1     % if the flag is "1", it means we adapted the "thermal limitation" not "line capacity"
%     y(1).data = g_line_temp;
%     y(1).name = 'with ESS'
%     y(1).color = '';
% end

% ---------------------------------------------------------------------------------------
% Figure4: Histgram of prediction in 24 hours 
% 1. Predicted load
% -----------------------------------------------------------------------------------
histogram_desc(g_flag_hist,g_load_train); % disply the histogram or not. True = 1, False =0

%% File Output
SOC = g_initial_SOC;
for i = 1:g_num_ESS
    ESS_schedule(:,i) = transpose(repelem(out_reshape(i,:),4));
    for j = 1:24*4
        SOC(j+1,i) = SOC(j,i) + ESS_schedule(j,i).*0.25;   % optimized_ESS: "+" means charge,  "-" means discharge
    end
    ESS_SOC(:,i) = transpose(100*SOC(:,i)./g_ESS_capacity(i));
end

filename_w = 'ESS_schedule.xlsx';
xlswrite(filename_w,ESS_schedule,1,'B5');        % Sheet1: Write T-node(1) original energy[wh] power consumption
xlswrite(filename_w,ESS_SOC,1,'F5');        % Sheet1: Write T-node(1) original energy[wh] power consumption

beep;
toc;
% profile viewer;
% profsave;




