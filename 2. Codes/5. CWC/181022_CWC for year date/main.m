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
    % PICP
    count = 0;
    for i = 1:n
        if (lowerPI(i,day) <= obserLoad(i,day)) && (obserLoad(i,day) <= upperPI(i,day))
            count = count +1;
        end
    end

    PICP(day,1) = count/n;

    % PINAW    
    R = max(upperPI(:,day)) - min(lowerPI(:,day));
    NMPIW(day,1) = sum(upperPI(:,day) - lowerPI(:,day))/(n*R);

    % CWC 
    % parameters for CWC
    % Reference: "Prediction Interval Construction and Optimization for adaptive neurofuzzy inference systems"
    eta = 100;
    mu = 0.95;
    CWC(day,1) = NMPIW(day,1)*(1+exp(-eta*(PICP(day,1)-mu)));
end

PICPAve = mean(PICP);
CWCAve = mean(CWC);
NMPIWAve = mean(NMPIW);


filename_w1 = 'CWC.xlsx';
xlswrite(filename_w1, PICPAve,1,'B3');        
xlswrite(filename_w1, NMPIWAve,1,'C3');        
xlswrite(filename_w1, CWCAve,1,'D3');       

xlswrite(filename_w1, PICP,1,'B7');        
xlswrite(filename_w1, NMPIW,1,'C7');        
xlswrite(filename_w1, CWC,1,'D7');       


