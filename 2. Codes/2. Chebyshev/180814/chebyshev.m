clc, clear, close all

%% file open
f1 = 'load.csv';
load = csvread(f1);
load_reshape = data_reshape(load);

for hour = 1:24
    hourly_class(hour).data = reshape(load(1+(hour-1)*30:hour*30, :), [30*size(load,2),1]);
end

%% calculate E(x), V(x), pred_min, pred_max
area = 0.05; % = 1/(k^2) Reference: Probabilistic statement "https://en.wikipedia.org/wiki/Chebyshev%27s_inequality"
k = 1/sqrt(area);
for i = 1: 24
    m(i) = mean(hourly_class(i).data);
    s(i) = std(hourly_class(i).data);
    pred_max(i,1) = m(i) + k*s(i); % É +k*É–
    pred_min(i,1) = m(i) - k*s(i); % É -k*É–
    pred_max(i,2) = m(i) +2*s(i); % É +2*É–
    pred_min(i,2) = m(i) - 2*s(i); % É -2*É–    
end

for hour = 1:24
    CheUpBound(1+(hour-1)*30:hour*30, 1) = repmat(pred_max(hour,1), 30,1);
    CheLoBound(1+(hour-1)*30:hour*30, 1) = repmat(pred_min(hour,1), 30,1);
    NorUpBound(1+(hour-1)*30:hour*30, 1) = repmat(pred_max(hour,2), 30,1);
    NorLoBound(1+(hour-1)*30:hour*30, 1) = repmat(pred_min(hour,2), 30,1);
end
%% graph describe
x = 1:720;
figure;
hold on;
for i = 1:size(load,2)
    plot(x, load(:,i), 'green');
end
p1= plot(x, CheUpBound, 'blue');
plot(x, CheLoBound, 'blue');
p2 = plot(x, NorUpBound, 'red');
plot(x, NorLoBound, 'red');
legend(p1, '95% boundaries by Chevichef');
hold on
legend(p2, '95% boundaries by variance');

