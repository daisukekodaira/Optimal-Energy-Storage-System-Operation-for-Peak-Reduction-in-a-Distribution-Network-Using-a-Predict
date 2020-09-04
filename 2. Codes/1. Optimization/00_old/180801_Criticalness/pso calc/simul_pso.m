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

    %% Update SOC
    if day == 1
        g_SocDayStart = g_initial_SOC;
    else
        g_SocDayStart = SOC(end,:);
    end
    
    %% Calculate ESS schedule
    % PSO calculation
    % "run_pso" returns optimum solutions which are given as pso_out
    train_load = g_load_train(:, day);
    test_load = g_load_test(:, day);
    [raw_train_load] = load_calc(train_load, zeros(g_num_ESS,24));
    [g_pred_min, g_pred_max] = GetCIOrderBasis(raw_train_load, g_percent);
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
    
    p = round(day*100/g_days,1);
    X = [num2str(p), '%'];
    disp(X);

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

