clear all;
clc;

%% kW

data2013_2014 = xlsread('data_total.xlsx',1); 
sup_data_2013_2014 = xlsread('newone_meas2.xlsx',1);

%% kmeans, 2013, train

load_2013 = 0.01*data2013_2014(1:365,1:96); 
load_2014 = 0.01*data2013_2014(366:730,1:96); 

k = 4; % 
rng(1); % what it is ???

% idx: number of group
% c: center of gravity for each group
[rabel_2013,c] = kmeans(load_2013,k);

%% Classify load in 2014
% train with 2013 data
sup_2013 = sup_data_2013_2014(1:365,:);
nb = NaiveBayes.fit(sup_2013, rabel_2013); %# train model (training data, training rabel)

% Making rable for 2014 data
sup_2014 = sup_data_2013_2014(366:730,:);
rabel_2014 = nb.predict(sup_2014);

%% Arrange the matrix for clasified load patterns: 96*days
for m = 1:4
    classified_load(m).data = zeros(size(transpose(load_2013),1),sum(rabel_2013(:)==m));
    classified_load(m).year = 2013;
    classified_load(m).group = m;
end

for m = 5:8
    classified_load(m).data = zeros(size(transpose(load_2014),1),sum(rabel_2014(:)==m-4));
    classified_load(m).year = 2014;
    classified_load(m).group = m-4;
end

%% Classify load 
for i = 1:length(rabel_2013)
    for j = 1:length(rabel_2013)
        if  classified_load(rabel_2013(i)).data(1,j) == 0
            classified_load(rabel_2013(i)).data(:,j) = transpose(load_2013(i,:)); 
            break;
        end
    end
end

for i = 1:length(rabel_2014)
    for j = 1:length(rabel_2014)
        if  classified_load(rabel_2014(i)+k).data(1,j) == 0
            classified_load(rabel_2014(i)+k).data(:,j) = transpose(load_2014(i,:)); 
            break;
        end
    end
end

%% File output: each group is allocated in each sheet
filename_w = 'Classified_load.xls';
xlswrite(filename_w,load_2013,1,'B2');        
xlswrite(filename_w,load_2014,2,'B2');        

for i = 1:length(classified_load)
    xlswrite(filename_w,classified_load(i).data,i+2,'B1');        
end

