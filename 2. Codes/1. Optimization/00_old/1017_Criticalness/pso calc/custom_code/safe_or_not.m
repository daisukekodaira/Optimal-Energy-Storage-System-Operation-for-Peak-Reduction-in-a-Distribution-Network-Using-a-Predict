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
            h = hourly_histgram(position, i).data;
            pd = fitdist(h,'Kernel','Kernel','epanechnikov');   % Make PDF object
            x_values = 0:0.1:11;    % Accuracy of the PDF is defined by an interval as 0.1. if the interval is smaller more accuracy we get.
            y = pdf(pd, x_values);   % Make PDF
            cost_func = y.*(exp(x_values));
            cost_func = cost_func/max(cost_func); % Normalization
            index = find(x_values*10 == g_line_capacity*10);
%             plot(x_values,y);

            % ------------Long Explanation for "L_critical" below---------------------------------------------------------------
            % We would like to make the cost(L_critical) smaller when the SOC is in the suitable range
            % The above "L_critical" is larger than the maximum here. Let's consider the maximum "L_critical" here.
            % Each element of "cost_func" is normalized, so each element's maximum value is "1".
            % the number of elements is decided by "x_values" above. At preset, maximum value of "L_critical" here is 111
            % --------------------------------------------------------------------------------------------------------------------
            for j  = index:size(cost_func,2)       
                L_critical(position, i) = L_critical(position, i) + cost_func(j); % Maximum = 1*111 ( 1*size(cost_func,2)) 
                %             if L_critical(i) > 0
                %                 plot(x_values,y);
                %             end
            end        
        end
    end 
    
    if sum(L_critical) < 0.1
        non_ope = 1;    % If there is no possibility to exceed the capacity, non_ope flag is "Ture(=1)"
    else
        non_ope =0;
    end

    
    
end