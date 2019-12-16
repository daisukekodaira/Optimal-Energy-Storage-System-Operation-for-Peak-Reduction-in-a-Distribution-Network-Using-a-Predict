function CI_desc(load,f_name_kernel,f_name_histo, percent)
global_var_declare;
load_reshape = data_reshape(load);

%% Time Classification(24hours*1(72days))
for day = 1:size(load_reshape,2)
    if day == 1
        for hour = 1:24
            hourly_class(hour).data = load_reshape((hour-1)*60+1:hour*60,day); %hourly classification (Sort 72 days by 24 hours)
        end
    else
        for hour = 1:24
            hourly_class(hour).data = [hourly_class(hour).data; load_reshape((hour-1)*60+1:hour*60,day)];
        end
    end
end

for i=1:24
    hourly_sort_class(i).data=sort(hourly_class(i).data);
end

%% calculate 95%
for i=1:24
        if percent==100
            size_initial = size(hourly_class(i).data,1);
            front_size(i) = 1;
            back_size(i) = size_initial;
            pred_max(i) = hourly_sort_class(i).data(back_size(i)); %Value of MW(upper line)
            pred_min(i) = hourly_sort_class(i).data(front_size(i)); %Value of MW(lower line)
            m(i) = mean(hourly_class(i).data);
            s(i) = std(hourly_class(i).data);
        else
            size_initial = size(hourly_class(i).data,1);
            front_size(i) = round(size_initial*( ((100-percent)/2)/100));
            back_size(i) = round(size_initial*((100 - (100 - percent)/2)/100));
            pred_max(i) = hourly_sort_class(i).data(back_size(i)); %Value of MW(upper line)
            pred_min(i) = hourly_sort_class(i).data(front_size(i)); %Value of MW(lower line)
            m(i) = mean(hourly_class(i).data);
            s(i) = std(hourly_class(i).data);
        end
    end

%%
for i=1:24
    figure(i+2)
    [f,xi] = ksdensity(hourly_class(i).data,'kernel','epanechnikov'); %xi:MW
    plot(xi,f,'LineWidth',2)
    hold on
    y=0:0.01:1;
    plot(pred_max(i)*ones(size(y)),y,'b--')
    plot(pred_min(i)*ones(size(y)),y,'b--')
    plot(m(i)*ones(size(y)),y,'g--')
    hold off
    title(strcat('Predicted Kernel between(', num2str(i-1), ':00and ', num2str(i), ':00) [',num2str(percent),'%]' ))
    legend('Kenel distribution',strcat(num2str(percent),'% CI(Upper)'),strcat(num2str(percent),'% CI(Lower)'),'mean')
    xlabel('Load [MW]'); % x-axis label
    ylabel('Probabilisity'); % y-axis label
    set(gca,'fontsize',12);
    mkdir(f_name_kernel);
    fpath = pwd;
    fname = sprintf('%dh~%dh.tif',i-1,i);
    saveas(figure(i+2), fullfile(fpath, '/', f_name_kernel, fname), 'tif');
    close(figure(i+2));
end

for i=1:24
    figure(i+2)
    histogram(hourly_class(i).data)
    title( strcat('Histogram between(', num2str(i-1), ':00and ', num2str(i), ':00) [',num2str(percent),'%]' ))
    xlabel('Load [MW]'); % x-axis label
    ylabel('The number of data instance'); % y-axis label
    set(gca,'fontsize',12);
    mkdir(f_name_histo);
    fpath = pwd;
    fname = sprintf('%dh~%dh.tif',i-1,i);
    saveas(figure(i+2), fullfile(fpath, '/', f_name_histo, fname), 'tif');
    close(figure(i+2));
end
end