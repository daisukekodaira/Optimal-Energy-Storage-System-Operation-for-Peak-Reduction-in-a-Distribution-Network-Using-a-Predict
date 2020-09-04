% input: ESS shedule to be optimize
% output: highest probability 

% in: ESS 24h schedule(1*48 matrix) 1*(ESS#1 + ESS#2)
% g_load_data: (720*365 matrix) 2min load data of one Bay's group which is provided from other program
function [cost] = constraints(in)   
    global_var_declare;

    re_in = transpose(reshape(in,[g_L_class,g_num_ESS]));% 
    
    %Initialize the cost
    cost = 0;
    
    %% Arrange cost function: %%%%%
    % 1. Start SOC meets end SOC
    % 2. SOC violation
    % 3. The number of Switching 
    %%%%%%%%%%%%%%%%%%%%%
    
    % 1. Initial SOC meets end SOC: Check whether SOC is the same as at the start time
    for m = 1:g_num_ESS % the number of ESS
        last_SOC = g_initial_SOC(m) + sum(re_in(m,:)); %  re_in "+": Chrage. ESS becomes load. SOC increases.
        if (last_SOC < g_initial_SOC(m) - g_margin(m)) || (g_initial_SOC(m) + g_margin(m) < last_SOC)
            cost = cost + (10^8) + (10^2)*abs(g_initial_SOC(m) - last_SOC);
        end
    end
    % if constraint No.1 is violated, return cost
    if cost ~= 0                
        return;
    end
    
    % 2. SOC violation check: SOC must be within 0% and 100%
    for m = 1:g_num_ESS % the number of ESS
        SOC = zeros(1,g_L_class);
        SOC(1) = g_initial_SOC(m);
        for i = 1:g_L_class
            SOC(i) = SOC(i) + re_in(m,i);  % "in": + means charge, - means discharge
            % Claculate next SOC until 24 hours
            if i ~= g_s_period
                SOC(i+1) = SOC(i); % if the SOC is in the ESS's capacity, refresh the SOC for next loop(hour)
            end
            % Evaluate cost for each situation
            if SOC(i) > g_SOC_limit_upper(m)
                soc_err = (10^3) + (10^3)*abs(SOC(i)-g_SOC_limit_upper(m));  
            elseif SOC(i) < g_SOC_limit_lower(m)
                soc_err = (10^3) + (10^2)*abs(g_SOC_limit_lower(m) - SOC(i));         
            else
                soc_err = 0;
            end
            cost = cost +soc_err;
        end
    end
    if cost ~= 0                
        return;
    end
end






