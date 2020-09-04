clear;
close all;

%% Data generation for P_market, P_customer
% Cost(1): P_market
% Cost(2): P_customer
% Cost(3): P_ess
% Cost(4): Combination of P_market, P_customer and P_ess
Cost(1).mu = 7.5;
Cost(1).sigma = 1;
Cost(1).range = [-5:.1:13];
Cost(1).name = 'From market';
Cost(2).mu = 1;
Cost(2).sigma = 0.2;
Cost(2).range = [-5:.1:6];
Cost(2).name = 'From customer';
Cost(3).name = 'From ess';
Cost(3).range = [-5:.1:8];
Cost(4).range = [-5:.1:13];
Cost(4).name = 'combined';

% Data generation
for i = 1:2
    Cost(i).data = normrnd(Cost(i).mu,Cost(i).sigma, [1 100]);
end
Cost(3).data = ones(1,100)*2; % 2[$/MW]

%% Combing of P_maker, P_customer and P_ess
% Calc procurement cost from each resorce:
[Cost] = calc_procurement_cost(Cost);

% Describe PDFs for Éø*P_market, É¿*P_customer, É¡*P_ess
for i = 1:4
    pd_Cost(i) = fitdist(transpose(Cost(i).upddata),'Kernel','BandWidth',0.5);
    y_cost(i).pdf = pdf(pd_Cost(i),Cost(i).range);
    y_cost(i).pdfnormalized = y_cost(i).pdf./trapz(y_cost(i).pdf);
    plot(Cost(i).range, y_cost(i).pdf ,'LineWidth',2)
    hold on;
end
xlabel('1000Åê/MW');
ylabel('Probability');
legend(Cost.name);

%% Describe Histograms
figure;
hold on;
histogram(Cost(1).upddata, 10);
histogram(Cost(2).upddata, 10);
histogram(Cost(3).upddata, 10);
histogram(Cost(4).upddata, 30);
legend(Cost.name);
xlabel('1000Åê/MW');
ylabel('The number of data');
legend(Cost.name);