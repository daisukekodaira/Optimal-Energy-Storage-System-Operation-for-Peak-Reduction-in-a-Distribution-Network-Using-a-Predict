function [load_CI] = CI(load, flag)


%% Parameters------------------------------------------------------------------
% 0) For both 
CI_level = 95; % "percentage"

% 1) For Bootstrapping
itr_btsp = 2000;

coef = size(load,1)/24;
elements = size(load,2);

%% Histgram for SD and Mean-------------------------------------------------------------------
% 1) Bootstrapping method
for hour = 1:24            % each hour until 24 hours
    samples = load(1+(hour-1)*coef:hour*coef, 1:elements);
    samples_mdf = reshape(samples, numel(samples), 1);
    k=0;
    for i = 1:itr_btsp
        btstr_smp(:,i) = datasample(samples_mdf, size(samples_mdf,1));
        btstr_mean(i) = mean(btstr_smp(:,i));
        btstr_std(i) = std(btstr_smp(:,i));
    end

    %% Summary of data
    stds = zeros(1,5);
    SEs = zeros(1,5);
    means = zeros(1,5);
    t_values = zeros(5,2);
    CIs = zeros(5,2);
    Inputs(1).data = btstr_std;  % % ƒÐ~1, ƒÐ~2,....
    Inputs(2).data = btstr_mean; % ƒÊ~1, ƒÊ~2,... 
    Inputs(3).data = transpose(samples_mdf);    % A group of bootstrapping which is extracted from population

    %% Confidencial interval---------------------------------------------------------------------------
    for i = 1:length(Inputs)
        stds(i) = std(Inputs(i).data);
        % i=1: ƒÐ~ƒÐ for bootstrap
        % i=2: ƒÐ~ƒÊ for bootstrap
        % i=3: ƒÐ for group(samples)
        means(i) = mean(Inputs(i).data);
        % i=1: ƒÊ~ƒÐ for bootstrap
        % i=2: ƒÊ~ƒÊ for bootstrap
        % i=3: ƒÊ for group(samples)
        t_values(i,:) =  tinv([(100-CI_level)/100 CI_level/100], length(Inputs(i).data)-1);
        CIs(i,:) = means(i) + t_values(i,:)*(stds(i)/sqrt(length(Inputs(i).data)-1));
        % i=1: CI of ƒÊ~ƒÐ for bootstrap
        % i=2: CI of ƒÊ~ƒÊ for bootstrap
        % i=3: CI of ƒÊ for group(samples) -> here, it is not utilized actually
    end
    
    %% shift original load---------------------------------------------------------------------------------
    delt_worst(hour) = CIs(2,1) - means(3);
    delt_best(hour) = CIs(2,2) - means(3);
    worst_samples(hour).data = samples + delt_worst(hour)*ones(size(samples,1), size(samples,2));    % shifted upper 
    best_samples(hour).data = samples + delt_best(hour)*ones(size(samples,1), size(samples,2));  % shifted lower

if flag == 1    % worst_case: upper CI is utilized
        shifted_samples = worst_samples;
    elseif flag ==2     % best_case: lower CI is utilized
        shifted_samples = best_samples;
    else
        msg = 'the flag should be 1:worst_case or 2:best_case.';
        error(msg);
end

for i = 1:size(shifted_samples,2)
    if i ==1
        load_CI = shifted_samples(i).data;
    else
        load_CI = [load_CI; shifted_samples(i).data];
    end
end

%% Figure------------------------------------------------------------------
fig(1).name = transpose(char(strcat('SD of boostrapping data', num2str(hour-1) , '~', num2str(hour) )'));
fig(2).name = transpose(char(strcat('Mean of boostrapping data', num2str(hour-1) , '~', num2str(hour) )'));
fig(3).name = transpose(char(strcat('A Bootstrapping group', num2str(hour-1) , '~', num2str(hour) )'));
fpath = [pwd '\Result'];    % file path to save the figs

for i = 1:length(fig)
    fig(i).graph = histogram(Inputs(i).data,20,'Normalization','probability');
    title(fig(i).name);    
    fname = sprintf('%d. %s.tif',i,fig(i).name);
    saveas(fig(i).graph, fullfile(fpath, fname), 'tif');
end

%% File output
filename_w = 'Confidencial_interval.xls';

% 2) Bootstrapping-------------------------------------------------------
% parameters
xlswrite(filename_w,CI_level,hour,'B1');        %
xlswrite(filename_w,size(samples_mdf,1),hour,'B2');
xlswrite(filename_w,1,hour,'B3');     
xlswrite(filename_w,itr_btsp,hour,'B4');        

% SDs for bootstrapping
xlswrite(filename_w,stds(1),hour,'B22');        % SD for bootstrapping
xlswrite(filename_w,means(1),hour,'B23');        % 
xlswrite(filename_w,CIs(1,:),hour,'C23');        % CI of SD for bootstrapping

% Means for bootstrapping
xlswrite(filename_w,stds(2),hour,'B26');        % SD of mean for bootstrapping
xlswrite(filename_w,means(2),hour,'B27');        % 
xlswrite(filename_w,CIs(2,:),hour,'C27');        % CI of mean for bootstrapping

% A group for bootstrapping
xlswrite(filename_w,stds(3),hour,'E12');        % std of population
xlswrite(filename_w,means(3),hour,'E13');        % std of population

end
