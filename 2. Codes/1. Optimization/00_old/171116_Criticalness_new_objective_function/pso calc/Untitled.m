clc, clear;
f1 = 'load.csv';
load = csvread(f1);
plot(load)
x_tick=30:30:720;
xlim([0,720])
set(gca,'xtick',x_tick);
set(gca,'xticklabel',char('1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20','21','22','23','24'));
xlabel('Hour'); % x-axis label
ylabel('Load [MW]'); % y-axis label
set(gca,'fontsize',18);