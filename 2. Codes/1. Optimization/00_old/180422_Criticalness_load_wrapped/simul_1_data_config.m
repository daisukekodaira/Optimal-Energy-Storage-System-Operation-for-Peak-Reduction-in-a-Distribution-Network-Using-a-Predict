%% Read Input File
% f1 = 'Load_QR_reg.xls';
f1 = 'load.xls';
f2 = 'test.csv';
g_load_train = xlsread(f1);
g_load_test = csvread(f2);

% reshape load
g_load_train = data_reshape(g_load_train);
g_load_test = data_reshape(g_load_test);

%% Paramters & Flags
g_days = size(g_load_train,2);   % how many days compose the one group(class)
g_steps = size(g_load_train,1);  % how many time steps in a day : e.x) 2min data =720, 15min data = 96
g_s_period = 24; % schedule period , e.g.) 24 hour ahead schedule(t = 24) requires 24 unknown variables to be optimized
g_PSC_capacity = [0.75 1];
g_line_capacity = 2.5;   % Around 10 is appropriate for real data. Interval must be 0.5 such as 9.5, 10.0 or 10.5. I will make it flexible later.
g_ESS_capacity = [1.5 2];
g_margin = g_ESS_capacity*0.02; % 5% margin for last SOC in a day
g_SOC_limit_lower = g_ESS_capacity*0.15;
g_SOC_limit_upper = g_ESS_capacity*0.85;
g_initial_SOC = g_ESS_capacity/2; % initial energy of ESS ex) if ESS has 3MWh at first, it can discharge 3MWh
g_color_depth = 0; % between 0~1. 0 is the depest.
g_num_ESS = size(g_ESS_capacity,2);
g_distance = [5824 9598 7428];
g_position = g_num_ESS+3;   % the number of observation point in the network(in case there are two ESSs, the point is 5)
g_percent = 95; % percentage of confidence interval [%] ex) 100% takes 100% CI for PDF
g_L_class = 3; % How many load classes devided into from 24hours (this number shoud be divisor of 24)


% g_op_unit: ESS input/output 0.1MWh as a unit. ex) g_op_unit = 1 -> 0.3MWh is a unit of input/output
%                    g_op_unit*0.1 is the minimum operation unit of ESS output/input
% g_op_floag: True(0) or false(1). 
%                     0 -> Apply operation unit using "g_op_unit" 
%                     1 -> Don't apply operation unit using "g_op_unit" 
% these two variable is used in "pso_Trelea_vectorized"
% However, this method leads the non-optimized situation because of the "round"
% The better method to mitigate fluctuation of ESS shoud be considered
g_op_unit = 1; 
g_op_flag = 1;

% To describe the number of input load data. If we have 15min data, the number of steps are 96 for 24 hours. 
% therefore, coefficient should be 4 because 4*24 = 96
g_coef = g_steps/24;


% temp valueables for calculation
g_min_cost = Inf;
for position = 1:g_num_ESS+3
    g_L_critical_best(position,:) = zeros(1,g_s_period);
end

% Flags
g_flag_hist =0; % disply the histogram or not. True = 1, False =0
