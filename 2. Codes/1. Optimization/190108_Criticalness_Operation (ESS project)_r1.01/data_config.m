function data_config(demandResult, ESSconfigs)
    
    global_var_declare;

    %% Read demandResult
    demandResult = csvread(demandResult,1,0);
    g_date = demandResult(:,1:6); 
    g_predLoad = demandResult(:,7);   % demand mean (deterministic load prediction from median of PIs)
    g_lowerPI = demandResult(:,8);   % lower PI
    g_upperPI = demandResult(:,9);   % upper PI

    %% Read ESSconfigs
    ESSconfigs = csvread(ESSconfigs,1,0);
    g_num_ESS = size(ESSconfigs(:,1),1);
    g_Battery_cap = ESSconfigs(:,2)';
    g_currentSOC = g_Battery_cap.*ESSconfigs(:,3)'/100; % g_currentSOC is defined as MWh
    g_min_SOC = g_Battery_cap.*ESSconfigs(:,4)'/100; % g_min_SOC [MWh]
    g_max_SOC = g_Battery_cap.*ESSconfigs(:,5)'/100; % g_max_SOC [MWh]
    g_PSC_ch_cap = ESSconfigs(:,6)';
    g_PSC_disch_cap = ESSconfigs(:,7)';
    g_PSC_ch_eff = ESSconfigs(:,8)';
    g_PSC_disch_eff = ESSconfigs(:,9)';
    g_ESS_Op_flag = ESSconfigs(:,10)';
    
    %% Paramters for optimization
    g_days = 1;   % How many days do we make schedule for?
    g_steps = size(g_predLoad,1);  % how many time steps in a day : e.x) 2min data =720 steps, 15min data = 96 steps
    g_s_period = 24; % schedule period , e.g.) 24 hour ahead schedule(t = 24) requires 24 unknown variables to be optimized
    g_line_capacity = 10;   % Around 10 is appropriate for real data. Interval must be 0.5 such as 9.5, 10.0 or 10.5. I will make it flexible later.
    g_margin = g_Battery_cap*0.02; % 2% margin for last SOC in a day
    g_distance = [5824 9598 7428];
    g_position = g_num_ESS+3;   % the number of observation point in the network(in case there are two ESSs, the point is 5)

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
end
