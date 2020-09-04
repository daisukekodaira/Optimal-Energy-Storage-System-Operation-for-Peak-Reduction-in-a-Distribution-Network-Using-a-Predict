clear all;
clc;

%% kW

data2013_2014 = xlsread('data_total.xlsx',1); % 첫번째시트 : 2013�?1�?~ 2014�?12�?데이터

%% kmeans, 2013, train

rng(1)

X = data2013_2014(1:365,1:96); % �?: 최�?熾?kW), 2013�?데이터 사�?

k = 4 % 클러스터 갯�?4
[idx,c] = kmeans(X,k);


%% bayesian

meas = xlsread('newone_meas2.xlsx',1); % 2013�?1�?~ 2014�?12�?(요일만든거)
species = idx;

%# lets split into training/testing
training = meas(1:365,:); % 2013�?1�?~ 12�?(요일만든거)
train_class = species(1:365,:); % 2013�?1�?~ 12�?(kmeans분류한거)

confirm = meas(366:730,:); % 2014�?1�?~ 확인 (요일만든거)

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