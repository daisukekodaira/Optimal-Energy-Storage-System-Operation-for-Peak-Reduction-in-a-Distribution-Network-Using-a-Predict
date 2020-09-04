function [non_ope, L_critical] = safe_or_not
    global_var_declare;    
    re_in = zeros(g_num_ESS, g_s_period); % ESS operation (zero)
    [flow_on_feeder] = load_calc(g_load_train, re_in);  % get adjusted power flow by ESS operation (ESS operation is zero here)
    L_critical = zeros(size(flow_on_feeder,2),g_s_period);   % Initialized Criticalness as zero (position * 24 hours)
    
    % Make hourly histgram: every 2min data will be stored into 1 element of structure
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
    end   
    
    % Calculate the Local criticalness based on "line capacity"
    for position = 1:size(flow_on_feeder,2)
        for i = 1:g_s_period
            % expected load (mean of past load data for each position, each time instance)
            L_critical(position,i)  = mean(hourly_histgram(position, i).data);       
        end
    end 
    
    % If there is at least one value above the line capacity, ESS should work ( non_ope = 0)
    % If there is no possibility to exceed the capacity, non_ope flag is "Ture(=1)"
    if L_critical < g_line_capacity 
        non_ope = 1;    
    else
        non_ope =0;
    end
end