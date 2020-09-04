function [Line_load] = distribute_sub_load(total_load)
    global_var_declare;
    
    Line_load(1).data = total_load;  % substation
    Line_load(2).data = total_load - total_load*g_distance(1)/sum(g_distance);  % load at left side of ESS#1
    Line_load(3).data = total_load - total_load*g_distance(1)/sum(g_distance);  % load at right side of ESS#1
    Line_load(4).data = total_load - total_load*(g_distance(1)+g_distance(2))/sum(g_distance);
    Line_load(5).data = total_load - total_load*(g_distance(1)+g_distance(2))/sum(g_distance);


end