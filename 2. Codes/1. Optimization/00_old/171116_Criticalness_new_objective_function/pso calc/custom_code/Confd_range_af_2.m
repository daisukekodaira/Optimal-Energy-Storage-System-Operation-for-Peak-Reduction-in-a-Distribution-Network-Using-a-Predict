%% file open
function [pred_min, pred_max] = confd_range_af_2(flow_on_feeder, percent)
global_var_declare;

for position = 1:size(flow_on_feeder,2) %%flow_on_feeder <=flow_on_feeder
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
            m(position,i) = mean(hourly_histgram(position,i).data);
            s(position,i) = std(hourly_histgram(position,i).data);
        else
            size_initial = size(hourly_histgram(position,i).data,1);
            front_size(position,i) = size_initial*(percent/100);
            back_size(position,i) = size_initial*((100-percent)/100);
            pred_max(position,i) = hourly_sort_class(position,i).data(back_size(position,i)); %Value of MW(upper line)
            pred_min(position,i) = hourly_sort_class(position,i).data(front_size(position,i)); %Value of MW(lower line)
            m(position,i) = mean(hourly_histgram(position,i).data);
            s(position,i) = std(hourly_histgram(position,i).data);
        end
    end
    
    
    %     for j=1:g_s_period
    %         size_initial=size(hourly_histgram(j).data,1);
    %         while(1)
    %             if size(hourly_histgram(position, j).data,1) >= (((100-2*percent)/100)*size_initial)
    %                 for k=1:size_initial
    %                     if max(hourly_histgram(position, j).data)==hourly_histgram(position, j).data(k);
    %                         t_max=k;
    %                         break;
    %                     end
    %                 end
    %                 for k=1:size_initial
    %                     if min(hourly_histgram(position, j).data)==hourly_histgram(position, j).data(k);
    %                         t_min=k;
    %                         break;
    %                     end
    %                 end
    %                 hourly_histgram(position, j).data(t_max)=[];
    %                 hourly_histgram(position, j).data(t_min)=[];
    %             else
    %                 break;
    %             end
    %         end
    %         pred_max(j) =max(hourly_histgram(position,j).data);         % 95% normal confidence interval
    %         pred_min(j) =min((hourly_histgram(position,j).data));
    %     end
end