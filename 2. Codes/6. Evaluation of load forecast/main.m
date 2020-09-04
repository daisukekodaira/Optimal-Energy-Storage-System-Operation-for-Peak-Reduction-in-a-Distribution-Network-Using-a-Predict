
clear all;
close all;

% Data loading
f1 = 'detrPredLoad.csv';
f2 = 'obsrLoad.csv';
f3 = 'upperCI.csv';
f4 = 'lowerCI.csv';
detrPredLoad = csvread(f1);
obserLoad = csvread(f2);
upperPI = csvread(f3);
lowerPI = csvread(f4);

n = size(detrPredLoad,1); % the number of data
days = size(detrPredLoad,2); % the number of days

for day = 1:days
    deviation(:,day) = obserLoad(:,day) - upperPI(:,day);
    stddev(day,1) = std(deviation(:,day));
end

histogram(stddev(:,day));

filename_w1 = 'CWC.xlsx';
xlswrite(filename_w1, stddev,1,'F7');        