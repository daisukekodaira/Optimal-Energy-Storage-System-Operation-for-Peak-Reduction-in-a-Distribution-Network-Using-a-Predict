function [load] = Generate_input_load

%% Loading file
filename1 = 'Deterministic_prediction_2014.xlsx';
filename2 = 'err_percentage_365days.xlsx';
pred_data = xlsread(filename1,1,'A1:CR365');
err_data = xlsread(filename2,1,'A1:CR365');

%% Generate probabilistic prediction data
% Probabilistic prediction is generated here.
% Input: 365(deays)*96(15min data)
% output: "dest_pred"  365*365*96 (days, elements for histgram, time instance 15min)
for days = 1:365
    for i = 1:96    % time steps for pred_data
        for k = 1:20 % 365    % days for err_data
            day = randsample(1:365,1);  % select the error randomly in 365 days in 2014
            dist_pred(days).data(k,i) = pred_data(days,i)/(1-err_data(day,i)); 
        end
    end
end

for days = 1:365
    if days ==1
        load = dist_pred(days).data;
    else
        load = [load; dist_pred(days).data];
    end
end

    load = transpose(load);

end

