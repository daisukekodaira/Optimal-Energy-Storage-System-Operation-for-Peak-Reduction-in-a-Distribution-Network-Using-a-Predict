% -------------------------------------------------------------------------------------------------------
%   Date: 2018/10/12
%   Project: Load leveling project 
%   Edited by: Daisuke Kodaira 
%   Input: demandResult, ESSconfigs
%   Output: Acc_Op_Sum.csv, Acc_ESS_Schedule.csv, ESS_Schedule_YYYYMMDDhhmm.csv
% -------------------------------------------------------------------------------------------------------

function flag = objESS(demandResult, ESSconfigs)

    global_var_declare; % Declare the global variables
    data_config(demandResult, ESSconfigs); % read demand forecast data and ESS configurations

    %% Calculate ESS schedule
    % PSO calculation
    % "run_pso" returns optimum solutions which are given as pso_out
    run_pso;
    pso_out(size(pso_out,1)) = []; % optimized ESS schedules

    % ESS schedule
    out_reshape = transpose(reshape(pso_out,[24,2]));

    % Calculate SOC
    ESS_SOC = g_currentSOC;
    for i = 1:g_num_ESS
        ESS_schedule(:,i) = transpose(repelem(out_reshape(i,:),4));     % Reshape the ESS shculed data
        for j = 1:24*4
            ESS_SOC(j+1,i) = ESS_SOC(j,i) + ESS_schedule(j,i).*0.25;   % optimized_ESS: "+" means charge,  "-" means discharge
        end
        ESS_SOC(:,i) = transpose(100*ESS_SOC(:,i)./g_Battery_cap(i));    % SOC[%]
    end

    % Power flow on feeder including ESS operations
    [rawPredLoad] = load_calc(g_predLoad, zeros(g_num_ESS,24));           % Power flow at each position without ESS operation for predicted load
    [adjPredLoad] = load_calc(g_predLoad, out_reshape);                           % Power flow at each position with ESS operation for predicted load
    [rawUpPI] = load_calc(g_upperPI, zeros(g_num_ESS,24));
    [rawLoPI] = load_calc(g_lowerPI, zeros(g_num_ESS,24));
    [adjUpPI] = load_calc(g_upperPI, out_reshape);
    [adjLoPI] = load_calc(g_lowerPI, out_reshape);
    
    %% Arrange the data for output
    resulting_Peak = max(max(adjPredLoad)); 
    
    % Calculate Peak reduction for power [MW]
    % peak [MW] with 15min resolution
    % (+) Reduction, (-) Increase 
    peak_Reduction = max(max(rawPredLoad)) - max(max(adjPredLoad)); 
    
    % Calculate ESS total charge
    ESS_total_ch = 0;
    
    % calculate ESS total discharge
    ESS_total_disch = 0; 
   
    %% File output
    t = datetime;
    filename_w1 = 'Acc_Op_Sum.csv';
    filename_w2 = 'Acc_ESS_Schedule.csv';
    filename_w3 = strcat('ESS_Schedule_', mat2str(t.Year), mat2str(t.Month),mat2str(t.Day), mat2str(t.Hour), mat2str(t.Minute), '.csv');

    % 1.Acc_Op_Sum.csv
    % Headers for output file
    ext_data = xlsread(filename_w1);    
    hedder1 = {'BuildingIndex', 'Year', 'Month', 'Day', 'Resulting peak[MW]', 'Peak reduction[MW]', 'ESS Total charged Energy[MWh]',...
                      'ESS Total Discharged Energy [MWh]', 'TOU cost savings', 'Peak cost savings', 'Total cost'};
    fid = fopen(filename_w1,'wt');
    fprintf(fid,'%s,',hedder1{:});
    fprintf(fid,'\n');    
    % get the current status of the ACC files
    new_op_sum = [g_date(1, 1:end-2) resulting_Peak peak_Reduction ESS_total_ch ESS_total_disch 0 0 0];
    if isempty(ext_data) ~= 1
        fprintf(fid,['%d,', '%d,', '%d,', '%d,', '%f,', '%f,', '%f,', '%f,', '%f,', '%f,','%f,' '\n'], ext_data');
    end
    fprintf(fid,['%d,', '%d,', '%d,', '%d,', '%f,', '%f,', '%f,', '%f,', '%f,', '%f,','%f,' '\n'], new_op_sum');
    fclose(fid);
    
    % 2.Acc_ESS_Schedule.csv
    % Headers for output file
    ext_data = xlsread(filename_w2);    
    hedder2 = {'BuildingIndex', 'Year', 'Month', 'Day', 'Hour', 'Quarter', 'ESS#1 Scheule[MW]','ESS#2 Scheule[MW]', 'ESS#1 SOC[%]','ESS#2 SOC[%]' };
    fid = fopen(filename_w2,'wt');
    fprintf(fid,'%s,',hedder2{:});
    fprintf(fid,'\n');    
    % get the current status of the ACC files
    new_ESS_sum = [g_date(:, 1:end) ESS_schedule ESS_SOC(2:end,:)];
    if isempty(ext_data) ~= 1
        fprintf(fid,['%d,', '%d,', '%d,', '%d,', '%d,', '%d,', '%f,', '%f,', '%f,', '%f,' '\n'], ext_data');
    end
    fprintf(fid,['%d,', '%d,', '%d,', '%d,', '%d,', '%d,', '%f,', '%f,', '%f,', '%f,' '\n'], new_ESS_sum');
    fclose(fid);
    
    % 3.ESS_Schedule_YYYYMMDDhhmm.csv
    fid = fopen(filename_w3,'wt');
    fprintf(fid,'%s,',hedder2{:});
    fprintf(fid,'\n');    
    fprintf(fid,['%d,', '%d,', '%d,', '%d,', '%d,', '%d,', '%f,', '%f,', '%f,', '%f,' '\n'], new_ESS_sum');
    fclose(fid);
    
    flag = 1;   % operation successfully end 

end


