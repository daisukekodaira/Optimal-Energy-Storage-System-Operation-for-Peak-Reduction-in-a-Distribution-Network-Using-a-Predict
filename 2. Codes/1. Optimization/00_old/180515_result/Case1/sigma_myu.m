% Peak reduction graph

% Data loading
f1 = 'Adjusted test load.xlsx';
load_orig = xlsread(f1,1);
load_adj = xlsread(f1,2);

% Reduction
red_peak = max(load_orig) - max(load_adj);

% Graph
h = histogram(red_peak, 'Normalization','probability');
h.NumBins = 20;
h.BinLimits = [-0.5, 2];
xlabel('Reduced Peak [MW]');
ylabel('Probability');

% Evaluation criteria
sigm = var(red_peak);
myu = mean(red_peak);

% parameter output
filename_w1 = 'Evaluation.xlsx';
xlswrite(filename_w1, sigm,2,'B2');        % Sheet1: Write T-node(1) original energy[wh] power consumption
xlswrite(filename_w1, myu,2,'C2');        % Sheet1: Write T-node(1) original energy[wh] power consumption


