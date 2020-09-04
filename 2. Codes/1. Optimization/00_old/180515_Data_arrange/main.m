% ----------------------------------------------
% Generate prediction PDF with arbitral error
% a and b indicates the error 
% ex) 2 = -200%~200% error is added to the original prediction
% ------------------------------------------------------------------

close all;
clear all;

% Data loading
f1 = 'load_orig.csv';
load_orig = csvread(f1);

% rand: error distribute a<err<b
a = -1.0;
b = 1.0;
err = a + (b-a).*rand(size(load_orig));

load_err = load_orig.*(1+err);
figure
h1 = histogram(load_orig);
title('Original Load')
h1.NumBins = 20;
figure
h2 = histogram(load_err);
h2.BinLimits = [-5, 18];
h1.NumBins = 20;
title('Load with 200% error')
figure;
histogram(err);
title('error')

% parameter output
filename_w1 = 'load.csv';
csvwrite(filename_w1, load_err);