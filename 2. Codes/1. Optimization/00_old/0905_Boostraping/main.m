clear all;
close all;

%% File read
filename1 = 'population.csv';
population = csvread(filename1);


%% Parameters------------------------------------------------------------------
% 0) For both 
CI_level = 95; % "percentage"
n_sample = 100; % Take 10 from 2,000,000

% 1) For sampling
n_cluster = 500; % how many times take from the population

% 2) For Bootstrapping
itr_btsp = 500;


%% Histgram for SD and Mean-------------------------------------------------------------------
% 1) Smapling method
k = 0;
for i = 1: n_cluster
    sample = datasample(population, n_sample);
    smp_std(i) = std(sample);
    smp_mean(i) = mean(sample);
        % Sample figure output
        if mod(i,n_cluster/4)==0
            k = k+1;
            figure;
            histogram(sample,20,'Normalization','probability')
            title(['Sample' num2str(k)]);
            clust_std(k,1) = smp_std(i);
            clust_mean(k,1) = smp_mean(i);
        end
end

% 2) Bootstrapping method
k=0;
for i = 1:itr_btsp
    btstr_smp(:,i) = datasample(sample, n_sample);
    btstr_mean(i) = mean(btstr_smp(:,i));
    btstr_std(i) = std(btstr_smp(:,i));
    if mod(i,itr_btsp/4)==0
        k = k+1;
        figure;
        histogram(btstr_smp(:,i),20,'Normalization','probability')
        title(['Bootstrapping clusters' num2str(k)]);
        btstr_clust_std(k,1) = btstr_std(i);
        btstr_clust_mean(k,1) = btstr_mean(i);
    end
end    

%% Summary of data
stds = zeros(1,5);
SEs = zeros(1,5);
means = zeros(1,5);
t_values = zeros(5,2);
CIs = zeros(5,2);
Inputs(1).data = population; % É–
Inputs(2).data = smp_std; % É–~1, É–~2,....
Inputs(3).data = smp_mean;  % É ~1, É ~2,... 
Inputs(4).data = btstr_std;  % 
Inputs(5).data = btstr_mean;
Inputs(6).data = sample;    % A group of bootstrapping which is extracted from population

%% Confidencial interval---------------------------------------------------------------------------
for i = 1:length(Inputs)
    stds(i) = std(Inputs(i).data);
    % i=1: É–     for population
    % i=2: É–~É– for sample
    % i=3: É–~É  for sample
    % i=4: É–~É– for bootstrap
    % i=5: É–~É  for bootstrap
    means(i) = mean(Inputs(i).data);
    % i=1: É      for population
    % i=2: É ~É– for sample
    % i=3: É ~É  for sample
    % i=4: É ~É– for bootstrap
    % i=5: É ~É  for bootstrap
    
    SEs(i) = stds(i)/sqrt(length(Inputs(i).data));
    t_values(i,:) =  tinv([(100-CI_level)/100 CI_level/100], length(Inputs(i).data)-1);
    CIs(i,:) = means(i) + t_values(i,:)*SEs(i);
    % i=1: CI of É       for population
    % i=2: CI of É ~É–  for sample
    % i=3: CI of É ~É  for sample
    % i=4: CI of É ~É– for bootstrap
    % i=5: CI of É ~É  for bootstrap    
end

%% Figure------------------------------------------------------------------
fig(1).name = 'Population';
fig(2).name = 'Standard Deviation of Smaples';
fig(3).name = 'Mean of Smaples';
fig(4).name = 'SD of boostrapping data';
fig(5).name = 'Mean of boostrapping data';
fig(6).name = 'A Bootstrapping group';
fpath = [pwd '\Result'];    % file path to save the figs

for i = 1:length(fig)
    fig(i).graph = histogram(Inputs(i).data,20,'Normalization','probability');
    title(fig(i).name);    
    fname = sprintf('%d. %s.tif',i,fig(i).name);
    saveas(fig(i).graph, fullfile(fpath, fname), 'tif');
end



%% File output
filename_w = 'Confidencial_interval.xls';

% 1) Sampling method-------------------------------------------------------
% parameters
xlswrite(filename_w,CI_level,1,'B1');        %
xlswrite(filename_w,n_sample,1,'B2');
xlswrite(filename_w,n_cluster,1,'B3');     

% Population
xlswrite(filename_w,stds(1),1,'B7');        % std of population
xlswrite(filename_w,means(1),1,'B8');        % mean of population
xlswrite(filename_w,CIs(1,:),1,'C8');        % CI of population

% Clusters for sampling
xlswrite(filename_w,clust_std,1,'B12');        % std of population
xlswrite(filename_w,clust_mean,1,'B16');        % std of population

% SDs for sampling
xlswrite(filename_w,stds(2),1,'B22');        % SD of samples
xlswrite(filename_w,means(2),1,'B23');        % 
xlswrite(filename_w,CIs(2,:),1,'C23');        % CI of population

% Means for sampling
xlswrite(filename_w,stds(3),1,'B26');        % SD of samples
xlswrite(filename_w,means(3),1,'B27');        % 
xlswrite(filename_w,CIs(3,:),1,'C27');        % CI of population

% 2) Bootstrapping-------------------------------------------------------
% parameters
xlswrite(filename_w,CI_level,2,'B1');        %
xlswrite(filename_w,n_sample,2,'B2');
xlswrite(filename_w,1,2,'B3');     
xlswrite(filename_w,itr_btsp,2,'B4');        

% Population
xlswrite(filename_w,stds(1),2,'B7');        % std of population
xlswrite(filename_w,means(1),2,'B8');        % mean of population
xlswrite(filename_w,CIs(1,:),2,'C8');        % CI of population

% Clusters for bootstrapping
xlswrite(filename_w,btstr_clust_std,2,'B12');        % std of population
xlswrite(filename_w,btstr_clust_mean,2,'B16');        % std of population

% SDs for bootstrapping
xlswrite(filename_w,stds(4),2,'B22');        % SD for bootstrapping
xlswrite(filename_w,means(4),2,'B23');        % 
xlswrite(filename_w,CIs(4,:),2,'C23');        % CI of SD for bootstrapping

% Means for bootstrapping
xlswrite(filename_w,stds(5),2,'B26');        % SD of mean for bootstrapping
xlswrite(filename_w,means(5),2,'B27');        % 
xlswrite(filename_w,CIs(5,:),2,'C27');        % CI of mean for bootstrapping

% A group for bootstrapping
xlswrite(filename_w,stds(6),2,'E12');        % std of population
xlswrite(filename_w,means(6),2,'E13');        % std of population
