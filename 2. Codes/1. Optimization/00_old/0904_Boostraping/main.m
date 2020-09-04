clear all;
close all;

%% File read
filename1 = 'population.csv';
population = csvread(filename1);


%% Parameters------------------------------------------------------------------
% 0) For both 
CI_level = 95; % "percentage"
n_sample = 100; % Take 100 from 10,000

% 1) For sampling
n_series = 100; % how many times take from the population

% 2) For Bootstrapping
itr_btsp = 500;


%% Histgram for SD and Mean-------------------------------------------------------------------
% 1) Smapling method
for i = 1: n_series
    sample = datasample(population, n_sample);
    smp_std(i) = std(sample);
    smp_mean(i) = mean(sample);
    %     % Sample figure output
    %     if mod(i,25)==0
    %         figure;
    %         histogram(sample,'Normalization','pdf')
    %         title('Sample');
    %     end
end

% 2) Bootstrapping method
for i = 1:itr_btsp
    btstr_smp(:,i) = datasample(sample, n_sample);
    bstr_mean(i) = mean(btstr_smp(:,i));
    bstr_std(i) = std(btstr_smp(:,i));
end    
% stats = bootstrp(itr_btsp,@(x)[mean(x) std(x)], sample);
% bstr_mean = stats(:,1);
% bstr_std = stats(:,2);

%% Confidencial interval---------------------------------------------------------------------------
% 0) Population
% mean
pop_std = std(population);
pop_SE = pop_std/sqrt(length(population));
pop_mean = mean(population);
t_value = tinv([(100-CI_level)/100 CI_level/100], length(population)-1);
CI_p_mean = pop_mean + t_value*pop_SE;

% 1) Smapling method std
% STD
std_std = std(smp_std);
std_SE = std_std/sqrt(length(smp_std));
std_mean = mean(smp_std);
t_value = tinv([(100-CI_level)/100 CI_level/100], n_series-1);
CI_sm_std = std_mean + t_value*std_SE;
% Mean
mean_std = std(smp_mean);
mean_SE = mean_std/sqrt(length(smp_mean));
mean_mean = mean(smp_mean);
t_value = tinv([(100-CI_level)/100 CI_level/100], n_series-1);
CI_sm_mean = mean_mean + t_value*mean_SE;

% 2) Bootstrapping method
% STD
std_std = std(bstr_std);
std_SE = std_std/sqrt(length(bstr_std));
std_mean = mean(bstr_std);
t_value = tinv([(100-CI_level)/100 CI_level/100], length(bstr_std)-1);
CI_bstr_std = std_mean + t_value*std_SE;
% Mean
mean_std = std(bstr_mean);
mean_SE = mean_std/sqrt(length(bstr_mean));
mean_mean = mean(bstr_mean);
t_value = tinv([(100-CI_level)/100 CI_level/100],  length(bstr_mean)-1);
CI_bstr_mean = mean_mean + t_value*mean_SE;


%% Figure------------------------------------------------------------------
figure;
histogram(population,50,'Normalization','probability')
title('Population');

figure;
histogram(smp_std,20,'Normalization','probability')
title('Standard Deviation of Smaples')


figure;
histogram(smp_mean,20,'Normalization','probability')
title('Mean of Smaples')


figure;
histogram(bstr_mean,50,'Normalization','probability')
title('Mean of boostrapping data')


figure;
histogram(bstr_std,50,'Normalization','probability')
title('SD of boostrapping data')


%% File output
filename_w = 'Confidencial_interval.xls';
xlswrite(filename_w,CI_level,1,'B1');        %
xlswrite(filename_w,pop_std,1,'B2');        %
xlswrite(filename_w,pop_mean,1,'B3');        %
xlswrite(filename_w,CI_sm_std,1,'B7');        % SD of samples
xlswrite(filename_w,CI_bstr_std,1,'B8');        % SD of samples
xlswrite(filename_w,CI_p_mean,1,'B11');        %
xlswrite(filename_w,CI_sm_mean,1,'B12');        % Mean of samples
xlswrite(filename_w,CI_bstr_mean,1,'B13');        % SD of samples
xlswrite(filename_w,n_sample,1,'B16');        % Mean of samples
xlswrite(filename_w,n_series,1,'B17');        % Mean of samples
xlswrite(filename_w,itr_btsp,1,'B18');        % Mean of samples


