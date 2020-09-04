function [out] = pso_objective(in)
    global_var_declare;
    [n_,m_] = size(in);    % n = number of particles, m = number of variabless 
    
    % Declear variables
    out = zeros(n_,1);

    % PSO is configured to minimize the output, so largest error should be chosen as a return value
    for i = 1:n_
        % Check the constraint violation
        out(i) = constraints(in(i,:));
        if out(i)~=0
            if out(i) < 100
                beep;
            end
            continue;
        end
        % Calculate cost
        re_in = [in(i, 1:24); in(i,25:48)];
        temp_mx = load_calc(transpose(g_pred_max(1,:)), re_in);
        temp_mn = load_calc(transpose(g_pred_min(1,:)), re_in);
        for k = 1:size(temp_mx,2)
            mx(i).data(k,:) = abs(temp_mx(k).data);
            mn(i).data(k,:) = abs(temp_mn(k).data);
        end
        mx1 = max(abs(mx(i).data), abs(mn(i).data));
        [mx_vec(i,:) critica_position(i,:)] = max(mx1);
        [mx_val(i) critical_period(i)] = max(mx_vec(i,:));
        % Objective Function
        out(i) = mx_val(i) + 0.001*sum(abs(in(i,:))); % the coefficient is found by try-and-error
    end

end