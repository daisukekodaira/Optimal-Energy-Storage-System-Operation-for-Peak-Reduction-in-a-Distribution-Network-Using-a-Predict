clear all;
clc;

%% kW

data2013_2014 = xlsread('data_total.xlsx',1); % 첫번째시트 : 2013년 1월 ~ 2014년 12월 데이터

%% kmeans, 2013, train

X = data2013_2014(1:365,1:96); % 행 : 최대수요(kW), 2013년 데이터 사용

k = 4 % 클러스터 갯수 4
[idx,c] = kmeans(X,k);

%% bayesian

meas = xlsread('newone_meas2.xlsx',1); % 2013년 1월 ~ 2014년 12월 (요일만든거)
species = idx;

%# lets split into training/testing
training = meas(1:365,:); % 2013년 1월 ~ 12월 (요일만든거)
train_class = species(1:365,:); % 2013년 1월 ~ 12월 (kmeans분류한거)

confirm = meas(366:730,:); % 2014년 1월 ~ 확인 (요일만든거)

%# train model
nb = NaiveBayes.fit(training, train_class);
%# prediction
y = nb.predict(confirm);

%% class data -> load data
for i = 1:1:365
for j = 1:1:4
    if y(i,1) == j
    result_C(i,:) = c(j,:); 
    end
end
end