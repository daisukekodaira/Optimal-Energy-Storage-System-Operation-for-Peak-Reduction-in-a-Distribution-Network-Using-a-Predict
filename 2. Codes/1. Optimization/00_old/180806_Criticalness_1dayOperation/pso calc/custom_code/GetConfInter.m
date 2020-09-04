% Return the boundaries of confidence interval


function [lwBound, upBound] = GetConfInter(prob_prediction, percentage)    

for hour = 1:24
    hourly_class(hour).data = reshape(prob_prediction(:, 1+(hour-1)*4:hour*4), [4*size(prob_prediction,1),1]);
end

%% calculate E(x), V(x), pred_min, pred_max
for i = 1: 24
    m(i) = mean(hourly_class(i).data);
    s(i) = std(hourly_class(i).data);
    pred_max(i,1) = m(i) + 2*s(i); % É +2É–
    pred_min(i,1) = m(i) - 2*s(i); % É -2É–
end

    pred_min = max(pred_min,0);

for hour = 1:24
    upBound(1+(hour-1)*4:hour*4, 1) = repmat(pred_max(hour,1), 4,1);
    lwBound(1+(hour-1)*4:hour*4, 1) = repmat(pred_min(hour,1), 4,1);
end

% %% graph describe
% % figure;
% hold on;
% for i = 1:size(prob_prediction,1)
%     plot(prob_prediction(i,:), 'green');
% end
% plot(lwBound, 'black');
% plot(upBound, 'black');
% legend('95% boundaries by Confidence Interval');





end    