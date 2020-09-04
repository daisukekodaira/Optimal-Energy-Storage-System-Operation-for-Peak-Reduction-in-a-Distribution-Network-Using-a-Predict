%% Read Input File
f1 = 'load.xlsx';
f2 = 'test.xlsx';
g_load_train = xlsread(f1);
g_load_test = xlsread(f2);

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
g_SOC_limit_lower = g_ESS_capacity*0.15;
g_SOC_limit_upper = g_ESS_capacity*0.85;
g_initial_SOC = g_ESS_capacity/2; % initial energy of ESS ex) if ESS has 3MWh at first, it can discharge 3MWh
g_margin = g_initial_SOC*0.02; % 2% margin around 50% for last SOC in a day
g_color_depth = 0; % between 0~1. 0 is the depest.
g_num_ESS = size(g_ESS_capacity,2);
g_distance = [5824 9598 7428];
g_position = g_num_ESS+3;   % the number of observation point in the network(in case there are two ESSs, the point is 5)
% To describe the number of input load data. If we have 15min data, the number of steps are 96 for 24 hours. 
% therefore, coefficient should be 4 because 4*24 = 96
g_coef = g_steps/24;
g_sigma = 3; % 2É–=95% boundary for each PDF

% temp valueables for calculation
g_min_cost = Inf;
for position = 1:g_num_ESS+3
    g_L_critical_best(position,:) = zeros(1,g_s_period);
end

% Flags
g_flag_hist = 0; % disply the histogram or not. True = 1, False =0
