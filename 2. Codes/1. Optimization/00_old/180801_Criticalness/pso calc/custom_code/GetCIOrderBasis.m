function [pred_min, pred_max] = GetCIOrderBasis(flow_on_feeder, percent)
global_var_declare;

percent = (100 - percent)/2;

for position = 1:size(flow_on_feeder,2) %%flow_on_feeder <=flow_on_feeder
    % Data arrangement for "line load" PDF (transform 2min data into hourly histgram)
    % Make hourly histgram: every 2min data will be stored into 1 element of structure
    for hour = 1: g_s_period % 1:24
        hourly_histgram(position, hour).data = flow_on_feeder(position).data((hour-1)*g_coef+1:hour*g_coef); % hourly histgram (for 24 hours) is composed here. Because of 2min data, 30 is multiplied.
    end
    
    %make sort array
    for i=1:24
        hourly_sort_class(position,i).data=sort(hourly_histgram(position,i).data);
    end
    
    % Calculate the Adjusted Local criticalness (training + ess_opt) based on "line capacity"
    for i=1:g_s_period
        if percent==0
            size_initial = size(hourly_histgram(position,i).data,1);
            front_size(position,i) = 1;
            back_size(position,i) = size_initial;
            pred_max(position,i) = hourly_sort_class(position,i).data(back_size(position,i)); %Value of MW(upper line)
            pred_min(position,i) = hourly_sort_class(position,i).data(front_size(position,i)); %Value of MW(lower line)
        else
            size_initial = size(hourly_histgram(position,i).data,1);
            front_size(position,i) = round(size_initial*(percent/100));
            back_size(position,i) = round(size_initial*((100-percent)/100));
            pred_max(position,i) = hourly_sort_class(position,i).data(back_size(position,i)); %Value of MW(upper line)
            pred_min(position,i) = hourly_sort_class(position,i).data(front_size(position,i)); %Value of MW(lower line)
        end
    end
end