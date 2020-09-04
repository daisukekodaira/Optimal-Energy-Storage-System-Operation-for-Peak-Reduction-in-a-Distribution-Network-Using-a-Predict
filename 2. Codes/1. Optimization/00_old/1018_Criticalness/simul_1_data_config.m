%% Read Input File
f1 = 'load.csv';
f2 = 'test.csv';
g_load_train = csvread(f1);
g_load_test = csvread(f2);
% g_amb_temp = xlsread(f2,1);

% reshape load
g_load_train = data_reshape(g_load_train);
g_load_test = data_reshape(g_load_test);


%% Paramters & Flags
g_days = size(g_load_train,2);   % how many days compose the one group(class)
g_steps = size(g_load_train,1);  % how many time steps in a day : e.x) 2min data =720, 15min data = 96
g_s_period = 24; % schedule period , e.g.) 24 hour ahead schedule(t = 24) requires 24 unknown variables to be optimized
g_Load_scenarios = 1; % The number of load senarios which is provided by the baye's theory
g_PSC_capacity = [0.75 1];
g_line_capacity = 1.7;   % Around 10 is appropriate for real data. Interval must be 0.5 such as 9.5, 10.0 or 10.5. I will make it flexible later.
g_ESS_capacity = [1.5 2];
g_margin = g_ESS_capacity*0.05; % 5% margin for last SOC in a day
g_initial_SOC = g_ESS_capacity/2; % initial energy of ESS ex) if ESS has 3MWh at first, it can discharge 3MWh
g_color_depth = 0; % between 0~1. 0 is the depest.
g_num_ESS = size(g_ESS_capacity,2);
g_distance = [5824 9598 7428];
% To describe the number of input load data. If we have 15min data, the number of steps are 96 for 24 hours. 
% therefore, coefficient should be 4 because 4*24 = 96
g_coef = g_steps/24;

% temp valueables for calculation
g_min_cost = Inf;
for position = 1:g_num_ESS+3
    g_L_critical_best(position,:) = zeros(1,g_s_period);
end

% % Parameters for thermal calculation
% g_init_linetemp =100;
% g_amb_temp =0;  % ambient temprerature
% g_mCp = 192;    % 
% g_Vw = 0.61;  % wind velocity at a specific height
% g_R=1;  % Resistance of line at specific temperature T
% g_del_t = 120;  % Measurement time interval in seconds. ex) 2min inverval = 120seconds

% Flags
g_flag_hist = 1; % disply the histogram or not. True = 1, False =0
% "OH! YOU FOUND THE IMPORTANT FLAG!"
% if you use the "line capacity" as a criterion: 1
% if you use the "line tempreature" as a criterion: 2
g_flag_crit = 1;
