% input: ESS shedule to be optimize
% output: highest probability 

% in: ESS 24h schedule(1*24 matrix)
% g_load_data: (720*365 matrix) 2min load data of one Bay's group which is provided from other program
function [L_critical, switching_cost] = calc_L_critical(in)   
    global_var_declare;

    g_line_temp = zeros(1,g_s_period);
    %     g_line_temp(1) = g_init_linetemp;        % Initial temperature
    switching_cost = 0;
    in_reshape = transpose(reshape(in,[24,2]));
    for m = 1:g_num_ESS
        re_in(m,:) = in_reshape(m,:);   % ESS_schedule for ESS1
    end   
    
    % Calculate Load power flow
    [flow_on_feeder] = load_calc(g_load_train, re_in);  % get adjusted power flow by ESS operation
    L_critical = zeros(size(flow_on_feeder,2),g_s_period);   % position * 24 hours
  
    
    %% Arrange cost function: 
    % 1. Start SOC meets end SOC
    % 2. SOC violation 
    % 3. Local criticalness derived from "over load"
    % 4. Local criticalness derived from "thermal model"

    % 1. Initial SOC meets end SOC: Check whether SOC is the same as at the start time
    for m = 1:g_num_ESS % the number of ESS
        SOC = zeros(1,24); 
        SOC(1) = g_initial_SOC(m);
        last_SOC = g_initial_SOC(m) + sum(re_in(m,:)); %  re_in "+": Chrage. ESS becomes load. SOC increases.
        if (last_SOC < g_initial_SOC(m) - g_margin(m)) || (g_initial_SOC(m) + g_margin(m) < last_SOC)
            % ------------------Long Explanation for "L_critical" below--------------------------------------------------
            % Initial part as "10^5" must be larger to return the cost as unacceptable cost.
            % In addtion to that, the Initial part as "10^5" is larger than the initial part in "2. SOC violation check"
            % as "10^3" because once we find the feasible last_SOC, we want to adjust the middle part like t=1~23.
            % For PSO not to go back to adjusting last_SOC, we put the larger cost than in "SOC violation check"
            % -------------------------------------------------------------------------------------------------------------
            L_critical = ones(size(flow_on_feeder,2), 24).*(10^3 + abs(g_initial_SOC(m) - last_SOC));
            return;
        end

     % 2. SOC violation check: SOC must be within 0% and 100%
        for i = 1:g_s_period
            SOC(i) = SOC(i) + re_in(m,i);  % "in": + means charge, - means discharge
            % Claculate next SOC until 24 hours
            if i ~= g_s_period
                SOC(i+1) = SOC(i); % if the SOC is in the ESS's capacity, refresh the SOC for next loop(hour)
            end

            if (SOC(i) > g_ESS_capacity(m)) || (SOC(i) < 0)
                L_critical = zeros(1,g_s_period); % erase the existing criticalness because once SOC violate
                % ------------------Long Explanation for "L_critical" below---------------------------------------------
                % Sum of  ESS 24h schedule(sum(abs(in))) gives the direction which SOC will go feasible direction.
                % All SOC is zero, which is farest from SOC violation.
                % Initial part as "10^3" must be larger than 1*111 to return the cost as not acceptable cost. 
                % '111' is decided in the following "3. Calculate the adjusted Local criticalness" part 
                % ------------------------------------------------------------------------------------------------------
                L_critical = ones(size(flow_on_feeder,2),24).*(10^2 + sum(abs(re_in(m,:))));
                return;  % if the SOC violate the capacity at this hour, we need not to calcuate the cost for latter hours.
            end
        end
    end
    
    % 3. Calculate the Adjusted Local criticalness (training + ess_opt) based on "line capacity"  
    % Data arrangement for "line load" PDF ( transform 2min data into hourly histgram)
    % Make hourly histgram: every 2min data will be stored into 1 element of structure
    if g_flag_crit == 1 % in case of 1, Line Load PDF is adopted
        for position = 1:size(flow_on_feeder,2)
            for day = 1:g_days
                if day == 1
                    for hour = 1: g_s_period % 1:24
                        hourly_histgram(position, hour).data = flow_on_feeder(position).data((hour-1)*g_coef+1:hour*g_coef,day); % hourly histgram (for 24 hours) is composed here. Because of 2min data, 30 is multiplied.
                    end
                else
                    for hour = 1: g_s_period % 1:24
                        hourly_histgram(position, hour).data = [hourly_histgram(position, hour).data; flow_on_feeder(position).data((hour-1)*g_coef+1:hour*g_coef, day)];
                    end
                end
            end
            criterion = g_line_capacity;
        end
    end
    
    % 3. Calculate the Adjusted Local criticalness (training + ess_opt) based on "line capacity"
    % ------------How to design "L_critical" here------------------------------------------
    % We would like to make the cost(L_critical) smaller when the SOC is in the suitable range
    % The above "L_critical" is larger than the maximum of L_critical here.
    % -----------------------------------------------------------------------------------------------
    for position = 1:size(flow_on_feeder,2)
        for i = 1:g_s_period
            % expected load (mean of past load data for each position, each time instance)
            L_critical(position,i)  = mean(hourly_histgram(position, i).data);       
        end
    end 
                      
end







