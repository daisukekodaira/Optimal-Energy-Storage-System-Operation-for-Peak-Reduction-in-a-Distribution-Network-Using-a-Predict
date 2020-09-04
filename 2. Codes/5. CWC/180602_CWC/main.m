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
f1 = 'Predicted_load.csv';
f2 = 'Observed_load.csv';
P_load = csvread(f1);
O_load = csvread(f2);

% transforme the data fomat
% 96*days (15min time steps * days) -> (0:00~1:00 * days)
for hour = 1:24
     Pred_load(:,hour) = reshape(P_load(1+4*(hour-1):4*hour,:), [], 1);      
end
for hour = 1:24
     Obsr_load(:,hour) = reshape(O_load(1+4*(hour-1):4*hour,:), [], 1);      
end

% 5%~100% PI
for x = 1:20
    % Parameters
    pi_nominal(x,1) = x*5;    % norminal PI for predicted load

    % Calculate PI 
    [NMPIW(x,1), PICP(x,1), CWC(x,1)]  = calc_CWC(Pred_load, Obsr_load, pi_nominal(x));

    % Graph
    [U_bound, L_bound] = get_PI(Pred_load, pi_nominal(x));
    Graph(P_load, O_load, pi_nominal(x), U_bound, L_bound);
end

filename_w1 = 'result_summary.xlsx';
xlswrite(filename_w1, pi_nominal,1,'A3');       
xlswrite(filename_w1, PICP,1,'B3');        
xlswrite(filename_w1, NMPIW,1,'C3');        
xlswrite(filename_w1, CWC,1,'D3');       


