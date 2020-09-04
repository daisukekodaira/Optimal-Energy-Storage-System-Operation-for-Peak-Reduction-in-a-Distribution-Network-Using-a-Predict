% -------------------------------------------------------------------------------------------------------
%   Date: 2019/02/07
%   Project: Distribution ESS
%   Edited by: Daisuke Kodaira 
%   Input: 1. Demand Forecast Result(DFR_YYYYMMDDHHMM.csv)
%              2. ESS Schedule Result(ECF_YYYYMMDDHHMM.csv)
%   Output: 1. Accumulated Operation Summary
%                 2. Accumulated ESS Schedule
%                 3. ESS Schedule Result (ESR_YYYYMMDDHHMM.csv)
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
    overWriteOrNot(demandResult, ESS_schedule, ESS_SOC, resulting_Peak, peak_Reduction, ESS_total_ch, ESS_total_disch)   
      
    flag = 1;   % operation successfully end -> 1

end


