%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function requires
% 1. Load at the substation (720*days)
% 2. Each ESS schedule for 24 hours (number of ESS*24hours)
% This function returns
% 1. Power flow including ESS operations at the substation, the right side of ESS#1, the left side of ESS#2, and the ESS#2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [flow_on_feeder] = load_calc(load, re_in)
    global_var_declare;
    if size(re_in,2) == 24
        ess_op(:,1) = transpose(repelem(re_in(1,:), size(load,1)/size(re_in,2))); % hourly data is expaned to every 2 min data seriese by multiplying 30
        ess_op(:,2) = transpose(repelem(re_in(2,:), size(load,1)/size(re_in,2)));
    else
        ess_op(:,1) = re_in(:,1);
        ess_op(:,2) = re_in(:,2);
    end
    
    % calculate load between Substation, ESS#1, ESS#2 and end of the feeder
    L(1).data = load*g_distance(1)/sum(g_distance);  % load at left side of ESS#1
    L(2).data = load*g_distance(2)/sum(g_distance);  % load at right side of ESS#1
    L(3).data = load*(g_distance(3))/sum(g_distance);
    
    
    for day = 1:size(load,2)
        % Criticalness is calculated at flow_on_feeder(1)~(4)
        % ess_op(1),(2):  "+":Charge -> ESS becomes load, "-":Discharge -> ESS becomes generator 
        flow_on_feeder(1).data(:,day) = load(:,day) + (ess_op(:,1) + ess_op(:,2));    % Substation 
        flow_on_feeder(2).data(:,day) = abs(flow_on_feeder(1).data(:,day) - L(1).data(:,day));   % left side from ESS#1
        flow_on_feeder(3).data(:,day) = abs(flow_on_feeder(1).data(:,day) - ess_op(:,1) - L(1).data(:,day));   % right side from ESS#1
        flow_on_feeder(4).data(:,day) = abs(-ess_op(:,2) - L(3).data(:,day));    % left side of ESS#2
        flow_on_feeder(5).data(:,day) = L(3).data(:,day);    % right side of ESS#2
        
    end
end