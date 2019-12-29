function [y] = heatmap_desc(load_train)
    global_var_declare;

    % 1. Extract data which is belong to specific time instances
    %   ex) pick the load data between 13:00 and 13:15 during 30 days
    % 2. Make PDF
    for i = 1:size(load_train,2)    % loop for the number of time instances (ex. 96 time instances)
        histData = load_train(:,i);   % histogram with 15min resolution
        pd = fitdist(histData,'Kernel','Kernel','epanechnikov');   % Make PDF object
        x_values = 0:0.1:11;    % Resolution of the PDF is defined by an interval as 0.1. if the interval is smaller more dense we get.
        y(:,i) = pdf(pd,x_values);   % Make PDF
    end
end