% Output files
% 1. AOS.csv (Accumulated Operation Summary)    
%      Append the new operation summary day by day
% 2. AES.csv (Accumulated ESS Schedule)
%      Append the new ESS schedule day by day
% 3. ESR_YYYYMMDDhhmm.csv (ESS Schedule Result)
%      Create a new file every time, which represents latest ESS operation

    
function csvOutput(demandResult, ESS_schedule, ESS_SOC, resulting_Peak, peak_Reduction)   
    global_var_declare

    % Get the folder path for output files
    folderPath = fileparts(demandResult); 
    
    % Set time stamps for output files
    t = datetime;   % get current time for file name
    t.Format = 'yyyyMMddHHmm'; % year, month, hour, minutes
    
    % File names for output csv files
    output(1).fname = [folderPath,'\','AOS.csv'];  % 1. Accumulated Operation Summary
    output(2).fname = [folderPath,'\','AES.csv'];  %  2. Accumulated ESS Schedule
    output(3).fname = [folderPath, '\', strcat('ESR_', char(t), '.csv')]; % 3. ESS Schedule Result
    
    % Headers for output files
    output(1).hedder = {'BuildingIndex', 'Year', 'Month', 'Day', 'Resulting peak[MW]', 'Peak reduction[MW]'};
    output(2).hedder = {'BuildingIndex', 'Year', 'Month', 'Day', 'Hour', 'Quarter', 'ESS#1 Scheule[MW]','ESS#2 Scheule[MW]', 'ESS#1 SOC[%]','ESS#2 SOC[%]' };
    output(3).hedder = {'BuildingIndex', 'Year', 'Month', 'Day', 'Hour', 'Quarter', 'ESS#1 Scheule[MW]','ESS#2 Scheule[MW]', 'ESS#1 SOC[%]','ESS#2 SOC[%]' };
    
    % Create the arry for current data to be written in AOS.csv
    output(1).data = [g_date(1, 1:end-2) resulting_Peak peak_Reduction];  
    output(2).data = [g_date(:, 1:end) ESS_schedule ESS_SOC(2:end,:)];  
    output(3).data = [g_date(:, 1:end) ESS_schedule ESS_SOC(2:end,:)];
    
    % Write down in the csv files
    for i = 1:size(output,2)
        if exist(output(i).fname) ~= 0  % If output csv file exist -> extract existing records       
            ext_data = xlsread(output(i).fname);
            output_data = [ext_data'; output(i).data'];  % Append the new data to the existing data
        else
            output_data = [output(i).data'];
        end
        fid = fopen(output(i).fname,'wt');  % open output file
        fprintf(fid,'%s,', output(i).hedder{:}); % write hedder first
        fprintf(fid,'\n');
        % Write (existing data + new data)
        switch i
            case 1  % AOS
                fprintf(fid,['%d,', '%d,', '%d,', '%d,', '%f,', '%f,' '\n'], [output_data]);
            case 2  % AES
                fprintf(fid,['%d,', '%d,', '%d,', '%d,', '%f,', '%f,', '%f,', '%f,', '%f,', '%f,' '\n'], [output_data]);
            case 3  % ESR
                fprintf(fid,['%d,', '%d,', '%d,', '%d,', '%f,', '%f,', '%f,', '%f,', '%f,', '%f,' '\n'], [output(i).data']);
        end
        fclose(fid);   
    end
end