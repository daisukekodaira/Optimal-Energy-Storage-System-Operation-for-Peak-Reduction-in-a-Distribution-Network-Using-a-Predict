function Cost = calc_procurement_cost(Cost)

% Parameters definition:
needed_power = 2; % How much power[MW] need to be procured

% Coefficients definition: 
% how to distribute the needed power into three sources. 
% total of Éø, É¿, É¡ should be 1 as 100%.
Cost(1).coef = 0.4; % Éø
Cost(2).coef = 0.4; % É¿
Cost(3).coef = 0.2; % É¡

% Procurement cost from market and customer
for i= 1:2
    Cost(i).upddata = needed_power*Cost(i).coef.*Cost(i).data;
end

% Procurement cost from ess
% Note: Just constant value as a example. At least, the cost is not propotion to
% the amount of procurement
Cost(3).upddata = Cost(3).data; 

% Combined cost histogram data
Cost(4).upddata = horzcat(Cost(1).upddata, Cost(2).upddata, Cost(3).upddata);

end