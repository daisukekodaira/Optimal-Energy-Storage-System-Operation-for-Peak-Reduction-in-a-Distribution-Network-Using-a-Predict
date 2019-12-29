%----------------------------------------------------
% Input:(y,highest, lowest)
% "y": What you descriped for each step
% "highest": Highest value of Y axis
% "lowest": Lowest value of Y axis
%----------------------------------------------------

function graph_desc(y, load_train, legend)
    global_var_declare;
        
    % Declear figures
    f(1) = figure;  % Figure1: Forecasted information
    f(2) = figure;  % Figure2: Observed infromation
    f_title = {char(strcat('Forecasted load (', legend, ')')'), ...
                  char(strcat('Actual load (', legend, ')'))};    
    
    %% Time frame arrangement for x-axis
    t = datetime([2017  01  01  00  00  00]);
    t.Format = 'DD:HH:mm';
    % make time instances
    for i = 1:size(load_train,2)
        t(i+1) = t(i) + minutes(24*60/size(load_train,2));
    end
    % Convert from number to "date" format
    t = char(t);
    times_num = datenum(t, 'DD:HH:MM');    

    %% X-axis and Y-axis arrangement
    for i = 1:size(f,2)
        figure(f(i));
        xlabel('time');
        ylabel('MW');
        yyaxis right;
        ylim([-0.5, 105]);    
        ylabel('SOC [%]');
        yyaxis left;
        set(gca,'FontSize',20);
        xlim([times_num(1) times_num(end)]);       
        ylim([-1*max(g_ESS_capacity), max(max(g_predLoad))+6]);    
        xData = linspace(times_num(1),times_num(end),7);
        set(gca,'Xtick',xData);
        hold on;
        datetick('x','HH:MM','keeplimits','keepticks')
    end
    
    %% Describe graphs
    % Describe heatmap of probabilistic forecasted load
    [heat_y] = heatmap_desc(load_train); % 2min: 720*72  -> 111*24, 15min: 96*68 -> 111*24
    figure(1);
    unit = (xData(end) - xData(1))/g_s_period;
    xlim_MW = ([xData(1) xData(end)]);
    ylim_MW = 0:0.1:11;
    imagesc(xlim_MW, ylim_MW, heat_y);
    set(gca, 'YDir', 'normal');
    map(:,2) = flipud(transpose([g_color_depth:(1-g_color_depth)/10:1]));
    map(:,3) = flipud(transpose([g_color_depth:(1-g_color_depth)/10:1]));
    map(:,1) = 1;
    colormap(map);

    % Plot lines
    for i = 1:size(y,2)
        if y(i).descrp(1) == 1
            plt(f(1),y,i,times_num);
        end
        if y(i).descrp(2) == 1
            plt(f(2),y,i,times_num);
        end        
    end
    
    % Title of figures
    for i = 1:size(f,2)
        set(0,'CurrentFigure',f(i));
        title(f_title(i));
    end
end

% plot lines function
function plt(f, y, i, times_num)  % f = fig
    set(0,'CurrentFigure',f);
    % Select the y-axis
    if strcmp(y(i).yaxis, 'left')
        yyaxis left;
    else
        yyaxis right;
    end
    % Plot lines
    p = plot(times_num, y(i).data,'LineWidth',1);
    L = legend('show');
    L.FontSize = 12;
    p.DisplayName = y(i).legend;
    p.Color = y(i).color;
    p.LineStyle = y(i).linestyle;
    p.Marker = 'none';
end