%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function requires
% 1. Load at the substation. Data size is (1440*72). Data is composed of 2min_data(720)*ESS#(2) = 1440, 72 = days
% 2. Each ESS schedule for 24 hours (number of ESS*24hours)
% This function returns
% 1. Power flow including ESS operations at the substation, the right side of ESS#1, the left side of ESS#2, and the ESS#2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [flow_on_feeder] = load_calc(load, re_in)
    global_var_declare;
    if size(re_in,2) == g_s_period
        ess_op(:,1) = transpose(repelem(re_in(1,:), size(load,1)/size(re_in,2))); % hourly data is expaned to every 2 min data seriese by multiplying 30
        ess_op(:,2) = transpose(repelem(re_in(2,:), size(load,1)/size(re_in,2)));
    elseif size(re_in,2) == g_L_class
        for i = 1:g_s_period
            if g_label(1,i) == 1
                ess_op(i,:) = re_in(:,1)'; 
            elseif g_label(1,i) == 2
                ess_op(i,:) = re_in(:,2)';                 
            elseif g_label(1,i) == 3
                ess_op(i,:) = re_in(:,3)';                                 
            end
        end
    else
        ess_op = re_in;
    end
    
    % calculate load between Substation, ESS#1, ESS#2 and end of the feeder
    L(:,1) = load*g_distance(1)/sum(g_distance);  % load at left side of ESS#1
    L(:,2) = load*g_distance(2)/sum(g_distance);  % load at right side of ESS#1
    L(:,3) = load*(g_distance(3))/sum(g_distance);
    
    
    % Criticalness is calculated at flow_on_feeder(1)~(4)
    % ess_op(1),(2):  "+":Charge -> ESS becomes load, "-":Discharge -> ESS becomes generator 
    flow_on_feeder(:,1) = load + (ess_op(:,1) + ess_op(:,2));    % Substation 
    flow_on_feeder(:,2) = abs(flow_on_feeder(:,1) - L(:,1));   % left side from ESS#1
    flow_on_feeder(:,3) = abs(flow_on_feeder(:,1) - ess_op(:,1) - L(:,1));   % right side from ESS#1
    flow_on_feeder(:,4) = abs(-ess_op(:,2) - L(:,3));    % left side of ESS#2
    flow_on_feeder(:,5) = L(:,3);    % right side of ESS#2
        
end