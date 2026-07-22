%oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
%  Check variability of ABL
% -------------------------------------------------------------------------
% Inputs:  
%          ABL -------- [N_h, N_t] = ABL map
%          th_dim_objs -- [scalar] = Threshold object dimension
%          th_variation - [scalar] = Maximum variation between 2 adjacent
%                                    objects
%          W ------------ [scalar] = Horizontal window size around each object
%                                    used to compare the object with its 
%                                    background
%          w_time_min --- [scalar] = Minimum temporal width for an object
%
% -------------------------------------------------------------------------
% Outputs:
%          ABL -------- [N_h, N_t] = Updated ABL map
%
% -------------------------------------------------------------------------
% Notes:
% -------------------------------------------------------------------------
function [ABL] = check_variability_abl(ABL, th_dim_objs, th_variation, W, w_time_min)

BW_ABL = bwlabel(ABL); % 8-connected components

% Loop over all labeled objects

for ii = 1 : max(BW_ABL(:))
    
    % Check if the object is smaller than the minimum size threshold

    if (numel(find(BW_ABL == ii)) < th_dim_objs)
        
        % Get the pixel coordinates of the current object
        [x1, y1] = find(BW_ABL == ii);
        
        % Create a copy of ABL with the current object removed
        ABL_FB = ABL;        
        ABL_FB(BW_ABL == ii) = 0;
        
        % Extract the background in a horizontal window around the object
        BW_ABL_Background = bwlabel(ABL_FB(:, max(1, round(min(y1)- W)) : min(size(ABL, 2), round(max(y1) + W))));
        
        % Find the row positions of remaining background pixels
        [x2, ~] = find(BW_ABL_Background > 0);
        
        % Remove the object if its mean vertical position deviates too much from the background
        % The threshold is: th_variation + 3*std(x1)

        if abs(mean(x1) - mean(x2)) > (th_variation + 3*std(x1)) 
            
            ABL(BW_ABL == ii) = 0;
        
        end
        
        % Remove the object if its temporal width is too small
        if abs(max(y1) - min(y1)) < w_time_min 
        
            ABL(BW_ABL == ii) = 0;
        
        end
    end
end

% --------
end