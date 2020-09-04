clear;

filename = '20170410_SCADA.xlsx';
load_data = transpose(xlsread(filename,2,'C2:NA721'));

% separate into a month
monthly(1).load = load_data(:,275:305);
monthly(1).name = 'January';
monthly(2).load = load_data(:,306:333);
monthly(2).name = 'February';
monthly(3).load = load_data(:,334:364);
monthly(3).name = 'March';
monthly(4).load = load_data(:,1:30);
monthly(4).name = 'April';
monthly(5).load = load_data(:,31:61);
monthly(5).name = 'May';
monthly(6).load = load_data(:,62:91);
monthly(6).name = 'June';
monthly(7).load = load_data(:,92:122);
monthly(7).name = 'July';
monthly(8).load =  load_data(:,123:153);
monthly(8).name = 'August';
monthly(9).load = load_data(:,154:183);
monthly(9).name = 'September';
monthly(10).load = load_data(:,184:214);
monthly(10).name = 'October';
monthly(11).load =  load_data(:,215:244);
monthly(11).name = 'November';
monthly(12).load = load_data(:,245:274);
monthly(12).name = 'December';

% set x axis data
x2 = 1:0.1:720;

% plotting
for i = 1:12
    figure
    x = transpose([1:size(monthly(i).load,1)]);
    plot(x,monthly(i).load,'b');
    % graph style
    title(['Load in 24 hours:' monthly(i).name]);
    xlabel('time (0:00~24:00)');
    ylabel('MW');
    xlim([0 size(monthly(i).load,1)]);
    ylim([0 11]);
end