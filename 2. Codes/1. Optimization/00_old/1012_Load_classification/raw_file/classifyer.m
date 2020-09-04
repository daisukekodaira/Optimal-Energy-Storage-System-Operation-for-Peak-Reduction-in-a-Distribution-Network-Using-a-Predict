clear all;
clc;

%% kW

data2013_2014 = xlsread('data_total.xlsx',1); % Ã¹¹øÂ°½ÃÆ® : 2013³?1¿?~ 2014³?12¿?µ¥ÀÌÅÍ

%% kmeans, 2013, train

rng(1)

X = data2013_2014(1:365,1:96); % Ç?: ÃÖ´?ö¿?kW), 2013³?µ¥ÀÌÅÍ »ç¿?

k = 4 % Å¬·¯½ºÅÍ °¹¼?4
[idx,c] = kmeans(X,k);


%% bayesian

meas = xlsread('newone_meas2.xlsx',1); % 2013³?1¿?~ 2014³?12¿?(¿äÀÏ¸¸µç°Å)
species = idx;

%# lets split into training/testing
training = meas(1:365,:); % 2013³?1¿?~ 12¿?(¿äÀÏ¸¸µç°Å)
train_class = species(1:365,:); % 2013³?1¿?~ 12¿?(kmeansºÐ·ùÇÑ°Å)

confirm = meas(366:730,:); % 2014³?1¿?~ È®ÀÎ (¿äÀÏ¸¸µç°Å)

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