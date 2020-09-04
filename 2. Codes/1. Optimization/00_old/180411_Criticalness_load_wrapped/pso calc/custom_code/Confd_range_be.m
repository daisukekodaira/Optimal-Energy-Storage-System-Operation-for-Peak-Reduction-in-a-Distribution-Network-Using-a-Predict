function [pred_min, pred_max] = Confd_range_be(flow_on_feeder)

global_var_declare;


for position = 1:size(flow_on_feeder,2)
    % Data arrangement for "line load" PDF (transform 2min data into hourly histgram)
    % Make hourly histgram: every 2min data will be stored into 1 element of structure
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
    
    % Calculate the Adjusted Local criticalness (training + ess_opt) based on "line capacity"
    for i = 1:g_s_period  % loop is not necessary maybe
        h = hourly_histgram(position, i).data;
        m(position,i) = mean(h);
        s(position,i) = std(h);
        pred_min(position,i) = m(position,i) - 2*s(position,i);        
        pred_max(position,i) = m(position,i) + 2*s(position,i);
    end
end 

end