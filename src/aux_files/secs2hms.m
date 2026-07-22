%oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
%  Time conversion from seconds to H(hours)M(minutes)S(Seconds)
% -------------------------------------------------------------------------
% 
% Inputs:  
%        time_in_secs --------- [scalar] = time in seconds 
%
%--------------------------------------------------------------------------
% Outputs:
%         time_string ----- [char] = time string
%            h_string ----- [char] = hours 
%            m_string ----- [char] = minutes 
%
%--------------------------------------------------------------------------
% Notes:
%--------------------------------------------------------------------------
function [time_string, hstr, mstr] = secs2hms(time_in_secs)
    
time_string='';
n_hours = 0;
n_mins = 0;

if time_in_secs >= 3600

    n_hours = floor(time_in_secs/3600);
    
    if n_hours > 1
            
        hour_string = ' hours, ';
    
    else
        
        hour_string = ' hour, ';
    
    end
    
    time_string = [num2str(n_hours) hour_string];
    
end

if time_in_secs >= 60
        
n_mins = floor((time_in_secs - 3600*n_hours)/60);

    if n_mins > 1
         
        minute_string = ' mins, ';
    else
        
        minute_string = ' min, ';
    
    end
    
    time_string = [time_string num2str(n_mins) minute_string];
    
end

n_secs = time_in_secs - 3600*n_hours - 60*n_mins;

time_string = [time_string sprintf('%2.1f', n_secs) ' secs'];

hstr = num2str(n_hours);
mstr = num2str(n_mins);

%-----------
end