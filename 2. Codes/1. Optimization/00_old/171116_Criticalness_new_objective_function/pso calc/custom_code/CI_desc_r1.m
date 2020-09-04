function CI_desc_r1(load,f_name)
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

%% calculate E(x), V(x)
for i = 1: 24
    m(i) = mean(hourly_class(i).data);
    s(i) = std(hourly_class(i).data);
end
%% calculate 95%
for j=1:24
    SUM_CI=1;
    for i=0.01:0.01:4
        if SUM_CI<=size(hourly_class(j).data,1)*0.95
            ci=(abs(hourly_class(j).data-m(j))<=s(j)*i);
            SUM_CI=sum(ci);
        else
            CI(j).data=i;
            save_CI(j).data=SUM_CI;
            break;
        end        
    end
end

for i = 1: 24 
    pred_max(i) = m(i) + CI(i).data * s(i);         % 95% normal confidence interval
    pred_min(i) = m(i) - CI(i).data * s(i); 
end
%%
for i=1:24
    figure(i+2)
    [f,xi] = ksdensity(hourly_class(i).data,'kernel','epanechnikov'); %xi:MW
    plot(xi,f,'LineWidth',4)
    hold on
    y=0:0.01:1;
    plot(pred_max(i)*ones(size(y)),y,'b--')
    plot(pred_min(i)*ones(size(y)),y,'r--')
    hold off
    title(strcat('Predicted Kernel between(', num2str(i-1), ':00and ', num2str(i), ':00)'))
    legend('Kenel distribution','95% CI(Upper)','95% CI(Lower)')
    xlabel('Load [MW]'); % x-axis label
    ylabel('Probabilisity'); % y-axis label
    set(gca,'fontsize',12);
%     f_name='kernel distribution'                                           %%save image 
    mkdir(f_name);
    fpath = pwd;
    fname = sprintf('%dh~%dh.tif',i-1,i);
    saveas(figure(i+2), fullfile(fpath, '/', f_name, fname), 'tif');
    close(figure(i+2));
end
end