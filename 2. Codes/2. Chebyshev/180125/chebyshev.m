clc, clear

%% file open
f1 = 'load.csv';
load = csvread(f1);
load_reshape = data_reshape(load);

%% Time Classification(24hours*1(72days))
% hourly_class(1).data=load
% hourly_class(2).data=load
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


%% calculate E(x), V(x), pred_min, pred_max
for i = 1: 24
    m(i) = mean(hourly_class(i).data);
    s(i) = std(hourly_class(i).data);
    pred_max(i) = m(i) + 2 * sqrt(5) * s(i); %2sqrt(5) => 95% Confidence Interval
    pred_min(i) = m(i) - 2 * sqrt(5) * s(i);
end


%% graph describe
plot(pred_max)
hold on
plot(pred_min)

