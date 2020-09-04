function [y] = heatmap_desc(load_train)
    global_var_declare;

    for day = 1:g_days
        if day == 1
            for hour = 1: g_s_period % 1:24
                hourly_histgram(hour).data = load_train((hour-1)*g_coef+1:hour*g_coef,day); % hourly histgram (for 24 hours) is composed here. Because of 2min data, 30 is multiplied.
            end
        else
            for hour = 1: g_s_period % 1:24
                hourly_histgram(hour).data = [hourly_histgram(hour).data load_train((hour-1)*g_coef+1:hour*g_coef,day)];
            end
        end
    end

    for i = 1:g_s_period
        h = hourly_histgram(i).data;
        data = reshape(h,[numel(h),1]);
        pd = fitdist(data,'Kernel','Kernel','epanechnikov');   % Make PDF object
        x_values = 0:0.1:11;    % Accuracy of the PDF is defined by an interval as 0.1. if the interval is smaller more accuracy we get.
        y(:,i) = pdf(pd,x_values);   % Make PDF
        cost_func = y(:,i).*transpose((exp(x_values)));
        cost_func = cost_func/max(cost_func); % Normalization
%         plot(x_values,cost_func)
%         xlabel('MW');
%         ylabel('Probability');
%         set(gca,'FontSize',20);
%         trapz(x_values,y(:,i))
    end
end