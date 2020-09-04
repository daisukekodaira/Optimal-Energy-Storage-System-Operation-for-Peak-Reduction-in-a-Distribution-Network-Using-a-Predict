function [out] = pso_objective(in)
    global_var_declare;
    [n_,m_] = size(in);    % n = number of particles, m = number of variables

    
    % Declear variables
    out = zeros(n_,1);
    for position = 1:g_num_ESS+1
        Crit(position).data = zeros(n_, g_s_period*g_num_ESS);
    end
    switching_cost = zeros(n_,1);
    
    % PSO is configured to minimize the output, so largest error should be chosen as a return value
    for i = 1:n_
        % "select the largest local criticalness during 24 hours" and "sum of 24 hours criticalness"
        % this part will be replaced with thermal model to be provided
        [Crit(i).data, switching_cost(i)] = calc_L_critical(in(i,:));
        % "Extract most dangerouns time instance among all positions" + "Total criticalness at all positions"
        if max(max(transpose(Crit(i).data))) > 10^3
            % Evaluate SOC constraints
            out(i) = max(max(transpose(Crit(i).data))) + sum(in(i,:).^2);
        else
            % Evaluate over power flow
            out(i) = (max(max(transpose(Crit(i).data))))^2 + sum(in(i,:).^2);
        end
    end    
    %  Calculate the Adjusted Local criticalness (training + ess_opt) based on "line capacity"
    [temp_cost, indx] = min(out);
    if temp_cost < g_min_cost
        g_L_critical_best = Crit(indx).data;
        g_min_cost = temp_cost;
    end
    
return