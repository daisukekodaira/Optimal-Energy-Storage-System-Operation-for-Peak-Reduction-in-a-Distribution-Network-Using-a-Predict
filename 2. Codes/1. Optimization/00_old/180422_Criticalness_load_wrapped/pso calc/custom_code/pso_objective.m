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
        % in: particle*(24hours, ESS#1+ESS#2)
        % re_in: ESS#*wrapped load (the number of group is defined as g_L_class)
        re_in = [in(i, 1:g_L_class); in(i,g_L_class+1:end)];
        % Note: At present, we assume the substation has the peak in the
        %           network(That's why only (1,:) is utilized here). It would be
        %           more general way to considering all "g_pred_max".
        temp_mx = load_calc(transpose(g_pred_max(1,:)), re_in); 
        temp_mn = load_calc(transpose(g_pred_min(1,:)), re_in);
        for k = 1:size(temp_mx,2)
            mx(i).data(k,:) = abs(temp_mx(k).data);
            mn(i).data(k,:) = abs(temp_mn(k).data);
        end
        mx1 = max(abs(mx(i).data), abs(mn(i).data));
        [mx_vec(i,:) critica_position(i,:)] = max(mx1);
        [mx_val(i) critical_period(i)] = max(mx_vec(i,:));
        out(i) = mx_val(i) + 0.05*sum(abs(in(i,:)));
    end
end