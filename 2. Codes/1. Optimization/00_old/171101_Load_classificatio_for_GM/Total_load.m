clear;

filename = 'load.xlsx';
load_data = xlsread(filename,1,'A1:BT720');

% set x axis data
x2 = 1:1:size(load_data,2);

% plotting
figure
plot(x2,load_data,'b');
xlim([0 96]);
ylim([0 4]);
xlabel('time (0:00~24:00)','FontSize',20,'FontWeight','bold');
ylabel('MW','FontSize',25,'FontWeight','bold');
set(gca,'FontSize',20);