% -------------------------------------------------------------------------------------------------------
%   Date: 2019/12/09
%   Project: Distribution ESS
%   Edited by: Daisuke Kodaira, daisuke.kodaira03@gmail.com
%   Input: 1. Demand Forecast Result (DFR_YYYYMMDDHHMM.csv)
%              2. ESS configuration file (ECF_YYYYMMDDHHMM.csv)
%   Output: 1. Accumulated Operation Summary
%                 2. Accumulated ESS Schedule
%                 3. ESS Schedule Result (ESR_YYYYMMDDHHMM.csv)
% -------------------------------------------------------------------------------------------------------

function flag = objESS(demandResult, ESSconfigs)

    % Declare the global variables
    global_var_declare; 

    % Read demand forecast data and ESS configurations
    data_config(demandResult, ESSconfigs); 

    % Parameters
    time_horizen = 24; % hours  
    
    %% Calculate ESS schedule
    % PSO calculation
    % - "run_pso" returns optimum solutions which are given as "pso_out"
    run_pso;

    % Erase the final cost of the objective function
    % - The last column of "pso_out" is not solution but the final cost of objective function 
    pso_out(size(pso_out,1)) = [];     
    
    % Change (solutions,1) format into (hours, the number of ESS) 
    out_reshape = transpose(reshape(pso_out,[time_horizen, g_num_ESS]));

    % Calculate SOC
    %  - "g_currentSOC keeps the SOC of the last day
    ESS_SOC = g_currentSOC;
    for i = 1:g_num_ESS
        % Reshape the ESS shculed data
        ESS_schedule(:,i) = transpose(repelem(out_reshape(i,:),4));     
        for j = 1:24*4
            % ESS_schedule: "+" (positive) means charge,  "-" (negative) means discharge
            % here is still SOC [kwh]
            ESS_SOC(j+1,i) = ESS_SOC(j,i) + ESS_schedule(j,i).*0.25;   
        end
        % Change the unit from SOC[kwh] to SOC[%]
        ESS_SOC(:,i) = transpose(100*ESS_SOC(:,i)./g_Battery_cap(i));    
    end

    % Power flow on feeder including ESS operations
    [rawPredLoad] = load_calc(g_predLoad, zeros(g_num_ESS,24));  % Power flow at each position without ESS operation for predicted load
    [adjPredLoad] = load_calc(g_predLoad, out_reshape);                   % Power flow at each position with ESS operation for predicted load
    [rawUpPI] = load_calc(g_upperPI, zeros(g_num_ESS,24));
    [rawLoPI] = load_calc(g_lowerPI, zeros(g_num_ESS,24));
    [adjUpPI] = load_calc(g_upperPI, out_reshape);
    [adjLoPI] = load_calc(g_lowerPI, out_reshape);
    
    %% Arrange the data for output
    % Pick the predicted highest peak
    resulting_Peak = max(max(adjPredLoad)); 
    
    % Calculate Peak reduction for power [MW]
    % peak [MW] with 15min resolution
    % peak_Reduction: (+) Reduction, (-) Increase 
    peak_Reduction = max(max(rawPredLoad)) - max(max(adjPredLoad)); 
      
    %% File output
    csvOutput(demandResult, ESS_schedule, ESS_SOC, resulting_Peak, peak_Reduction)   
      
    flag = 1;   % operation successfully end -> 1

end


