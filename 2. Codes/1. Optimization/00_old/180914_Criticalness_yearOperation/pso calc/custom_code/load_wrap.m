% --------------------------------------------------------------------
% This function is called from "simul_pso"
% input: 
% output:
% ----------------------------------------------------------------------

function [label] = load_wrap(boundary)
global_var_declare;

% 24hours are devided into 3groups
for position = 1:5
    for j = 1:g_L_class
        for i = 1:g_s_period/g_L_class
%             [load(j,i), time] = max(boundary(position,:));
            [M, time] = max(boundary(position,:));
            label(position,time) = j;
            boundary(position, time) = NaN;
        end
    end
end
    
end