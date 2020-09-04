% Input data structure
% (15min data set)*hour (=1612*24)

function [U_bound, L_bound] = get_PI(load, percent)

    percent = (100 - percent)/2;  
    
    %make sort array
    for hour = 1:24
        load_sort(:,hour) = sort(load(:,hour));
    end

    % Calculate the Adjusted Local criticalness (training + ess_opt) based on "line capacity"
    if percent==0
        size_initial = size(load_sort,1);
        front_size = 1;
        back_size = size_initial;
    else
        size_initial = size(load,1);
        front_size = round(size_initial*(percent/100));
        back_size = round(size_initial*((100-percent)/100));
    end
        U_bound = load_sort(back_size,:)'; %Value of MW(upper line)
        L_bound = load_sort(front_size,:)'; %Value of MW(upper line)

    
end