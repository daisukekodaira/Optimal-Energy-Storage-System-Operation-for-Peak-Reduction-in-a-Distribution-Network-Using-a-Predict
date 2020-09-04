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
    
    %% Calculate Load power flow
    [flow_on_feeder] = load_calc(g_load_train, re_in);  % get adjusted power flow by ESS operation

    L_critical = zeros(size(flow_on_feeder,2),g_s_period);   % position * 24 hours
    
    %% Case1) Data arrangement for "line load" PDF ( transform 2min data into hourly histgram)
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
    
%     for i = 1:g_s_period
%         h = hourly_histgram(1, i).data;
%         pd = fitdist(h,'Kernel','Kernel','epanechnikov');   % Make PDF object
%         x_values = 0:0.1:11;    % Accuracy of the PDF is defined by an interval as 0.1. if the interval is smaller more accuracy we get.
%         y = pdf(pd, x_values);   % Make PDF
%         plot(x_values,y);
%     end
    
    %% Case2) Data arrange ment for "thermal" PDF (Make 2min thermal data and Transform 2min data into hourly histgram)
    if g_flag_crit == 2
        ess_op = repelem(in, g_coef); % hourly data is expaned to every 2 min data seriese by multiplying 30          
        for day = 1:g_days
            flow_on_feeder(day,:) = transpose(g_load_train(:,day)) + ess_op; % t_load: One day has (1*720 matrix), ess_op: "+" means charge "-" means discharge
            for i = 1:g_steps-1     % calculate 2min line thermal 
                det_linetemp= ((flow_on_feeder(day,:)-(g_Vw*(g_line_temp(i)) - g_amb_temp(i+1)) ) /g_mCp)*(g_del_t);
                g_line_temp(i+1) = g_line_temp(i)+ det_linetemp;
            end
            % Make hourly histgram: every 2min data will be stored into 1 element of structure
            if day == 1
                for hour = 1: g_s_period % 1:24
                    hourly_histgram(hour).data = g_line_temp(day,(hour-1)*g_coef+1:hour*g_coef); % hourly histgram (for 24 hours) is composed here. Because of 2min data, 30 is multiplied.
                end
            else
                for hour = 1: g_s_period % 1:24
                    hourly_histgram(hour).data = [hourly_histgram(hour).data g_line_temp(day,(hour-1)*g_coef+1:hour*g_coef)];
                end
            end
        end
        % calculate the criteria
        %         criterion = 
        % How can we defined the critelia of thermal???? thermal at 10MW
        % changes with respected to the previous status (line tempreature, ambient tempreature)
    end    

    %% Arrange cost function: 
    % 1. Start SOC meets end SOC
    % 2. SOC violation 
    % 3. Local criticalness derived from "over load"
    % 4. Local criticalness derived from "thermal model"

    % 1. Start SOC meets end SOC: Check whether SOC is the same as at the start point
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
            L_critical = ones(size(flow_on_feeder,2), 24).*(10^8 + abs(g_initial_SOC(m) - last_SOC));
            return;
        end

        % 2. SOC violation check
        for i = 1:g_s_period
            SOC(i) = SOC(i) + re_in(m,i);  % "in": + means charge, - means discharge
            % Claculate next SOC until 24 hours
            if i ~= g_s_period
                SOC(i+1) = SOC(i); % if the SOC is in the ESS's capacity, refresh the SOC for next loop(hour)
            end

            if (SOC(i) > g_ESS_capacity(m)) || (SOC(i) < 0)
                L_critical = zeros(1,g_s_period); % erase the existing criticalness because once SOC violate
                % ------------------Long Explanation for L_critical below---------------------------------------------
                % Sum of  ESS 24h schedule(sum(abs(in))) gives the direction which SOC will go feasible direction.
                % All SOC is zero, which is farest from SOC violation.
                % Initial part as "10^3" must be larger than 1*111 to return the cost as not acceptable cost. 
                % '111' is decided in the following "3. Calculate the adjusted Local criticalness" part 
                % ------------------------------------------------------------------------------------------------------
                L_critical = ones(size(flow_on_feeder,2),24).*(10^5 + sum(abs(re_in(m,:))));
                return;  % if the SOC violate the capacity at this hour, we need not to calcuate the cost for latter hours.
            end
        end
    end

    % 3. Calculate the Adjusted Local criticalness (training + ess_opt) based on "line capacity"
    for position = 1:size(flow_on_feeder,2)
        for i = 1:g_s_period
            h = hourly_histgram(position, i).data;
            pd = fitdist(h,'Kernel','Kernel','epanechnikov');   % Make PDF object
            x_values = 0:0.1:11;    % Accuracy of the PDF is defined by an interval as 0.1. if the interval is smaller more accuracy we get.
            y = pdf(pd, x_values);   % Make PDF
            cost_func = y.*(exp(x_values));
            cost_func = cost_func/max(cost_func); % Normalization
            index = find(x_values*10 == criterion*10);
%             plot(x_values,y(:,i));
            
            % ------------Long Explanation for "L_critical" below---------------------------------------------------------------
            % We would like to make the cost(L_critical) smaller when the SOC is in the suitable range
            % The above "L_critical" is larger than the maximum here. Let's consider the maximum "L_critical" here.
            % Each element of "cost_func" is normalized, so each element's maximum value is "1".
            % the number of elements is decided by "x_values" above. At preset, maximum value of "L_critical" here is 111
            % --------------------------------------------------------------------------------------------------------------------
            for j  = index:size(cost_func,2)       
                L_critical(position, i) = L_critical(position, i) + cost_func(j); % Maximum = 1*111 ( 1*size(cost_func,2)) 
            end        
        end
    end            
end







