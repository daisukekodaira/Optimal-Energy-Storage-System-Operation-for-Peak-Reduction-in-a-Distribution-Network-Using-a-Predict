clear;
filename = 'load.xlsx';
load_data = xlsread(filename,1,'A1:BT2000');

filename = 'ESS_schedule.xlsx';
ESS_schedule = xlsread(filename,1,'W5:X28');
ESS_schedule_reshp = repelem(sum(ESS_schedule,2), size(load_data,1)/24, 1);

for i = 1:size(load_data,2)
    Adj_group2(:,i) = load_data(:,i) + ESS_schedule_reshp; 
end

Adj_group2(:,end+1) = 6*ones(720,1);
load_data(:,end+1) = 6*ones(720,1);

t = datetime([2017  01  01  00  00  00]);
t.Format = 'DD:HH:mm';
for i = 1:size(load_data,1)
    t(i+1) = t(i) + minutes(24*60/size(load_data,1));
end
t = char(t);
times_num = datenum(t, 'DD:HH:MM');
xlabel('time');
ylabel('MW');
ylim([-0.5, 8]);
set(gca,'FontSize',20);
xlim([times_num(1) times_num(end)]);  % 2min: 721*1 -> 720*1
                                                                  % 15min: 97*1 -> 96*1
xData = linspace(times_num(1),times_num(end),7);
set(gca,'Xtick',xData);
hold on;
datetick('x','HH:MM','keeplimits','keepticks')
times_num(end) = [];
p = plot(times_num, Adj_group2,'LineWidth',1);

figure;
t = datetime([2017  01  01  00  00  00]);
t.Format = 'DD:HH:mm';
for i = 1:size(load_data,1)
    t(i+1) = t(i) + minutes(24*60/size(load_data,1));
end
t = char(t);
times_num = datenum(t, 'DD:HH:MM');
xlabel('time');
ylabel('MW');
ylim([-0.5, 8]);
set(gca,'FontSize',20);
xlim([times_num(1) times_num(end)]);  % 2min: 721*1 -> 720*1
                                                                  % 15min: 97*1 -> 96*1
xData = linspace(times_num(1),times_num(end),7);
set(gca,'Xtick',xData);
hold on;
datetick('x','HH:MM','keeplimits','keepticks')
times_num(end) = [];
p = plot(times_num, load_data,'LineWidth',1);
