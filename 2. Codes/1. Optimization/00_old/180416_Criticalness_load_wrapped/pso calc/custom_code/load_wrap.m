function [label] = load_wrap(boundary)

% 24hours are devided into 3groups
for position = 1:5
    for j = 1:3
        for i = 1:8 
%             [load(j,i), time] = max(boundary(position,:));
            [M, time] = max(boundary(position,:));
            label(position,time) = j;
            boundary(position, time) = NaN;
        end
    end
end
    
end