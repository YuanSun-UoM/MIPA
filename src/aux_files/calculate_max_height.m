%oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
%  Calculation of Maximum Height
% -------------------------------------------------------------------------
% Inputs:  
%          time ------------------- [N, 1] = Time vector
%          stop_analysis_meters - [scalar] = Stop Analysis meters
%
% -------------------------------------------------------------------------
% Outputs:
%          vect_max_heights [1, N] = Vector Maximum Heights 
% -------------------------------------------------------------------------
% Notes:
%
% -------------------------------------------------------------------------
function vect_max_heights = calculate_max_height(time, stop_analysis_meters)

month_id = datetime(time(1), 'ConvertFrom', 'posixtime');

vect_time = zeros(1, numel(time));

for ii = 1 : numel(time)

     h = datetime(time(ii), 'ConvertFrom', 'posixtime');
     vect_time(ii) = h.Hour;

end

vect_max_heights = stop_analysis_meters .* ones(1, numel(time));

switch month_id.Month
    
    case {1, 2, 3, 11, 12}
        
        vect_max_heights(vect_time > 17 | vect_time < 8) = 1000;  
    
    otherwise
        
        vect_max_heights(vect_time > 19 | vect_time < 7) = 2000;  

end

% --------
end