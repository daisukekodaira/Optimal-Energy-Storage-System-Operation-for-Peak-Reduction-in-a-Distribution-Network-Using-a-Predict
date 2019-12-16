% Return the boundaries of confidence interval


function [lwBound, upBound] = GetChebyshevPI(prob_prediction, percentage)    

for hour = 1:24
    hourly_class(hour).data = reshape(prob_prediction(:, 1+(hour-1)*4:hour*4), [4*size(prob_prediction,1),1]);
end

%% calculate E(x), V(x), pred_min, pred_max
area = percentage; % = 1/(k^2) Reference: Probabilistic statement "https://en.wikipedia.org/wiki/Chebyshev%27s_inequality"
k = 1/sqrt(area);
for i = 1: 24
    m(i) = mean(hourly_class(i).data);
    s(i) = std(hourly_class(i).data);
    pred_max(i,1) = m(i) + k*s(i); % É +k*É–
    pred_min(i,1) = m(i) - k*s(i); % É -k*É–
end

    pred_min = max(pred_min, 0);

for hour = 1:24
    lwBound(1+(hour-1)*4:hour*4, 1) = repmat(pred_min(hour,1), 4,1);
    upBound(1+(hour-1)*4:hour*4, 1) = repmat(pred_max(hour,1), 4,1);
end
end    