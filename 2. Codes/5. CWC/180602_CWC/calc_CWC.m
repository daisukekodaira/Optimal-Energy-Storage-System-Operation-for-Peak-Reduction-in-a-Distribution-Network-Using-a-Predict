function [NMPIW, PICP, CWC] = calc_CWC(Pred_load, Obsr_load, pi_nominal)
    
    % Get PI
    [U_bound, L_bound] = get_PI(Pred_load, pi_nominal);    % 24 upper boundaries 
        
    % Calculate NMPIW
    y_max = max(max(Obsr_load));
    y_min = min(min(Obsr_load));
    R = y_max - y_min;  % range of observed load
    n = size(Pred_load,1); % the number o PI
    NMPIW = sum(U_bound - L_bound)/(24*R);
           
    % Calculate PICP
    c = zeros(24,1);
    for hour = 1:24
        for j = 1:size(Obsr_load,1)
            if (L_bound(hour) < Obsr_load(j,hour)) && (Obsr_load(j,hour)< U_bound(hour))
                c(hour) = c(hour)+1;
            end
        end
    end
    PICP = sum(c)/(n*24); % 0~1
   
    % CWC 
    % parameters for CWC
    eta = 200;
    mu = 0.875;
        
    CWC = NMPIW/(1+exp(-eta*(PICP-mu)));

    PICP = 100*PICP; % 0%~100%
    
end