function [y] = heatmap_desc(load_train)
    global_var_declare;


    for i = 1:size(load_train,2)
        h = load_train(:,i);   % histogram with 15min resolution
        data = reshape(h,[numel(h),1]);
        pd = fitdist(data,'Kernel','Kernel','epanechnikov');   % Make PDF object
        x_values = 0:0.1:11;    % Accuracy of the PDF is defined by an interval as 0.1. if the interval is smaller more accuracy we get.
        y(:,i) = pdf(pd,x_values);   % Make PDF
        cost_func = y(:,i).*transpose((exp(x_values)));
        cost_func = cost_func/max(cost_func); % Normalization
%         figure
%         plot(x_values,cost_func)
%         xlabel('MW');
%         ylabel('Probability');
%         set(gca,'FontSize',20);
%         trapz(x_values,y(:,i))
    end
end