function Graph(Pred_load, Obsr_load, pi_nominal, U_bound, L_bound)
  
    figure;
       
    for hour = 1:24
        if hour == 1
            U = repmat(U_bound(hour),[4,1]);
            L = repmat(L_bound(hour),[4,1]);
        else
            U = [U; repmat(U_bound(hour),[4,1])];
            L = [L; repmat(L_bound(hour),[4,1])];
        end
    end
    hold on;
    plot(U, 'Linewidth', 3);
    plot(L, 'Linewidth', 3);
    for days = 1:size(Obsr_load, 2)
        plot(Obsr_load(:,days),'b.');
    end
    title(['Predicted boundary with ', num2str(pi_nominal), '% vs observed data']);
    xlabel('time in a day');
    ylabel('Power[MW]');
    legend('Predicted upper boundary', 'Predicted lower boundary', 'observed data');


end