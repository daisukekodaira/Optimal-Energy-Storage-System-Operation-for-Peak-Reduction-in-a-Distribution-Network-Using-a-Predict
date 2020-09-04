clear;

%% Read Input File
f1 = 'load.xlsx';
raw_load = xlsread(f1);
Nan_matrix = isnan(raw_load);

for j = 1:size(raw_load,2)
    for i = 1:size(raw_load,1)
        
        if Nan_matrix(i,j) == 1
            search_row = i;
            
            % FInd the not NaN value before NaN
            while Nan_matrix(search_row,j) ==1
                search_row = search_row - 1;
            end
            bef_row = search_row;
            ave_bef = raw_load(bef_row,j);

            % FInd the not NaN value after NaN
            search_row = i;
            while Nan_matrix(search_row,j) ==1
                search_row = search_row + 1;
            end
            aft_row = search_row;
            ave_aft = raw_load(aft_row,j);

            % Replace the NaNs with average value
            for k = bef_row+1:aft_row-1
                raw_load(k,j) = mean([ave_bef ave_aft], 2);
                Nan_matrix(k,j) = 0;
            end        
        end
    end
end

% File output
filename = 'Filled_load.xlsx';
xlswrite(filename, raw_load,1); % 2min data*days
    
  