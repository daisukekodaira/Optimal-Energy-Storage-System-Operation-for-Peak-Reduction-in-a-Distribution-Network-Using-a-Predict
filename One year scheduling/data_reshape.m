function [reshaped_load] = data_reshape(raw_load)

days = size(raw_load,2);   % how many days compose the one group(class)
steps = size(raw_load,1);  % how many time steps in a day : e.x) 2min data =720, 15min data = 96

for i = 1:days
    reshaped_load(:,i) = repelem(raw_load(:,i), 24*60/steps);   % if steps = 720, 24*60/720 = 2min data
end

end