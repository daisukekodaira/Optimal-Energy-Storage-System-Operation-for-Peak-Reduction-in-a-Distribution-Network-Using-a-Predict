clear all;
close all;

%% File read
filename1 = 'population.csv';
population = csvread(filename1);


%% Parameters------------------------------------------------------------------
CI_level = 95; % "percentage"
n_sample = 100; % Take 100 from 10,000

% 1) For sampling
n_series = 10; % how many times take from the population

% 2) For Bootstrapping
itr_btsp = 100;


%% Histgram for SD and Mean-------------------------------------------------------------------
% 1) Smapling method
for i = 1: n_series
    sample = datasample(population, n_sample);
    std_smp(i) = std(sample);
    mean_smp(i) = mean(sample);
    %     % Sample figure output
    %     if mod(i,25)==0
    %         figure;
    %         histogram(sample,'Normalization','pdf')
    %         title('Sample');
    %     end
end
std_mean = std(std_smp);
mean_mean = mean(mean_smp);

% 2) Bootstrapping method
stats = bootstrp(itr_btsp,@(x)[mean(x) std(x)], sample);
mean_bstr = stats(:,1);
std_bstr = stats(:,2);

%% Confidencial interval---------------------------------------------------------------------------
t_value = tinv([(100-CI_level)/100 CI_level/100], n_series-1);

% 0) Population
pop_std = std(population);
pop_mean = mean(population);
pd = fitdist(population,'Normal');
CI_p= paramci(pd); 

% 1) Smapling method
pd = fitdist(transpose(std_smp),'Normal');
ci= paramci(pd);
CI_sd(1,:) = transpose(ci(:,1)); % confidential interval of SD of samples
pd = fitdist(transpose(mean_smp),'Normal');
ci = paramci(pd); 
CI_mean(1,:) = transpose(ci(:,1)); % confidential interval of Mean of samples

% 2) Bootstrapping method
pd = fitdist(std_bstr,'Normal');
ci= paramci(pd);
CI_sd(2,:) = transpose(ci(:,1)); % confidential interval of SD of samples
pd = fitdist(mean_bstr,'Normal');
ci = paramci(pd); 
CI_mean(2,:) = transpose(ci(:,1)); % confidential interval of Mean of samples



%% Figure------------------------------------------------------------------
figure;
histogram(population,50,'Normalization','probability')
title('Population');

figure;
histogram(std_smp,20,'Normalization','probability')
title('Standard Deviation of Smaples')


figure;
histogram(mean_smp,20,'Normalization','probability')
title('Mean of Smaples')


figure;
histogram(mean_bstr,50,'Normalization','probability')
title('Mean of boostrapping data')


figure;
histogram(std_bstr,50,'Normalization','probability')
title('SD of boostrapping data')


%% File output
filename_w = 'Confidencial_interval.xls';
xlswrite(filename_w,CI_level,1,'B1');        %
xlswrite(filename_w,pop_std,1,'B2');        %
xlswrite(filename_w,pop_mean,1,'B3');        %
xlswrite(filename_w,transpose(CI_p(:,2)),1,'B6');        %
xlswrite(filename_w,CI_sd,1,'B7');        % SD of samples
xlswrite(filename_w,transpose(CI_p(:,1)),1,'B11');        %
xlswrite(filename_w,CI_mean,1,'B12');        % Mean of samples
xlswrite(filename_w,n_sample,1,'B16');        % Mean of samples
xlswrite(filename_w,n_series,1,'B17');        % Mean of samples
xlswrite(filename_w,itr_btsp,1,'B18');        % Mean of samples


