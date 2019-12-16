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
        re_in = [in(i, 1:24); in(i,25:48)]; % extract ESS#1 and ESS#2 schedule
        t = load_calc(g_upperCIOneDay, re_in);  % calculate load including ESS operation at each position
        
        % Find the max in whole postions during whole a day        
        highestCI = max(max(t));     % pick the highest CI from all positions
%         CIgap = abs(max(max(t)) - min(min(t)));
        CIstd = std(t(:,1));
        out(i) = highestCI + 100*CIstd + 0.05*sum(abs(in(i,:)));
%         out(i) = highestCI + 0.5*CIgap + 0.05*sum(abs(in(i,:)));
    end
end