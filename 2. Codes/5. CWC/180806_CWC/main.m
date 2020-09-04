% ---------------------------------------------------------------------------------------------------------------------
% Evaluation for Probabilistic prediction 
% 2018/6/3 Daisuke Kodaira
% email: daisuke.kodaira03@gmail.com
% 
% PICP: Coverage rate(0%~100%). Bigger is the better. The rate of the predicted value falls into the nominal PI
% NMPIW: Smaller is the better. The mean of the PI widths normalized by the target range. 
% CWC: Smaller is the better. Total quality score. 
% 
% regerence paper: "Prediction Interval Construction and Optimization for Adaptive Neurofuzzy Inference Systems"
% --------------------------------------------------------------------------------------------------------------------------

clear all;
close all;

% Data loading
f1 = 'PredData.csv';
f2 = 'April1st.csv';
PredData = csvread(f1);
P_mean = PredData(:,1);
P_CImin = PredData(:,2);
P_CImax = PredData(:,3);
O_load = csvread(f2);

n = size(P_mean,1); % the number of data


% PICP
count = 0;
for i = 1:n
    if (P_CImin(i) <= O_load(i)) && (O_load(i) <= P_CImax(i))
        count = count +1;
    end
end
PICP = count/n;

% PINAW    
R = max(O_load)-min(O_load);
NMPIW = sum(P_CImax - P_CImin)/(n*R);

% CWC 
% parameters for CWC
% Reference: "Prediction Interval Construction and Optimization for adaptive neurofuzzy inference systems"
eta = 100;
mu = 0.875;
if PICP < mu
    coef = 1;
else
    coef = 0;
end

CWC = NMPIW*(1+coef*exp(-eta*(PICP-mu)));



filename_w1 = 'CWC.xlsx';
xlswrite(filename_w1, PICP,1,'B3');        
xlswrite(filename_w1, NMPIW,1,'C3');        
xlswrite(filename_w1, CWC,1,'D3');       


