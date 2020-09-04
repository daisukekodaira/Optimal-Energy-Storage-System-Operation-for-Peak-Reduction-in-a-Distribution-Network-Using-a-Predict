% This function to be modified later (8th Jan 2019 Koda)
%  - Duplicated codes
%  - Too many input variables (8 variables)


function overWriteOrNot(demandResult, ESS_schedule, ESS_SOC, resulting_Peak, peak_Reduction, ESS_total_ch, ESS_total_disch)   
    global_var_declare
    folderPath = fileparts(demandResult); % Get the folder path
    t = datetime;   % get current time for file name

    % File names for csv files
    filename_w1 = [folderPath,'\','Acc_Op_Sum.csv'];
    filename_w2 = [folderPath,'\','Acc_ESS_Schedule.csv'];
    filename_w3 = [folderPath, '\', strcat('ESS_Schedule_', mat2str(t.Year), mat2str(t.Month),mat2str(t.Day), mat2str(t.Hour), mat2str(t.Minute), '.csv')];
    
    % Headers for output file
    hedder1 = {'BuildingIndex', 'Year', 'Month', 'Day', 'Resulting peak[MW]', 'Peak reduction[MW]', 'ESS Total charged Energy[MWh]',...
                        'ESS Total Discharged Energy [MWh]', 'TOU cost savings', 'Peak cost savings', 'Total cost'};
    hedder2 = {'BuildingIndex', 'Year', 'Month', 'Day', 'Hour', 'Quarter', 'ESS#1 Scheule[MW]','ESS#2 Scheule[MW]', 'ESS#1 SOC[%]','ESS#2 SOC[%]' };

    % 1. Acc_Op_Sum.csv                
    if exist(filename_w1) ~= 0  % If output csv file exist -> extract existing records       
        ext_data1 = xlsread(filename_w1);
    else  % if output csv doesn't exist -> flag = -99
        ext_data1 = -99;
    end
    fid = fopen(filename_w1,'wt');
    fprintf(fid,'%s,',hedder1{:});
    fprintf(fid,'\n');
    if ext_data1 ~= -99   % if the file if not empty, write the existing data
        fprintf(fid,['%d,', '%d,', '%d,', '%d,', '%f,', '%f,', '%f,', '%f,', '%f,', '%f,','%f,' '\n'], ext_data1');
    end
    new_op_sum = [g_date(1, 1:end-2) resulting_Peak peak_Reduction ESS_total_ch ESS_total_disch 0 0 0];  % Create the arry for current data to be written in ACC csv file
    fprintf(fid,['%d,', '%d,', '%d,', '%d,', '%f,', '%f,', '%f,', '%f,', '%f,', '%f,','%f,' '\n'], new_op_sum');
    fclose(fid);
    
    % 2. Acc_ESS_Schedule.csv
    if exist(filename_w2) ~= 0    % If output csv file doesn't exist -> create new file
        ext_data2 = xlsread(filename_w2);    
    else
         ext_data2 = -99;
    end
    fid = fopen(filename_w2,'wt');
    fprintf(fid,'%s,',hedder2{:});
    fprintf(fid,'\n');
    if  ext_data2 ~= -99 % if the file if not empty, write the existing data
        fprintf(fid,['%d,', '%d,', '%d,', '%d,', '%d,', '%d,', '%f,', '%f,', '%f,', '%f,' '\n'], ext_data2');
    end
    new_ESS_sum = [g_date(:, 1:end) ESS_schedule ESS_SOC(2:end,:)];  % Create the arry for current data to be written in ACC csv file
    fprintf(fid,['%d,', '%d,', '%d,', '%d,', '%d,', '%d,', '%f,', '%f,', '%f,', '%f,' '\n'], new_ESS_sum');
    fclose(fid);
    
    % 3. ESS_Schedule_YYYYMMDDhhmm.csv
    fid = fopen(filename_w3,'wt');
    fprintf(fid,'%s,',hedder2{:});
    fprintf(fid,'\n');    
    fprintf(fid,['%d,', '%d,', '%d,', '%d,', '%d,', '%d,', '%f,', '%f,', '%f,', '%f,' '\n'], new_ESS_sum');
    fclose(fid);
end