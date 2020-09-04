clear;

filename = 'Load_data_at_substation.xlsx';
two_min_data = xlsread(filename,1); % average of whole year in 2014. 2min data

% Transform the data instance from 2min to houly
for i = 1:24
    hour_data(i) = mean(two_min_data((1+(i-1)*30:i*30)));
end

% Parameters for distribution
sigma = 1;

% Generate the normal distribution data
for i = 1:365
%     R(:,i) = normrnd(hour_data,sigma);
    R(:,i) = normrnd(two_min_data,sigma);
end

% % Display the data distribution based on normal distribution
% x_values = [0:0.1:10];
% for i = 1:24
%     figure;
%     pd = fitdist(transpose(R(i,:)), 'Normal');
%     y = pdf(pd, x_values);
%     plot(x_values, y, 'LineWidth',2);
% end

% Output the Load based on normal distribution
filename_w1 = 'Normal_Distibution.xlsx';
xlswrite(filename_w1,R,1);        % hour*dyas
