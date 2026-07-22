%oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
%  Delete unfeasible detections
% -------------------------------------------------------------------------
% 
% Inputs:  
%          edges --------------- [N_h_in, N_t] = Edge Image
%          time --------------------- [N_t, 1] = Time vector
%          stop_analysis_meters ----- [scalar] = Stop Analysis meters
%          spatial_resolution ------- [scalar] = Spatial resolution
%          spatial_reduction_factor - [scalar] = Spatial reduction factor
%
% -------------------------------------------------------------------------
% Outputs:
%          edges -------------- [N_h_out, N_t] = Edge map with removed 
%                                                unfeasible detections
%
% -------------------------------------------------------------------------
% Notes:
%
% -------------------------------------------------------------------------
function edges = delete_unfeas_detection(edges,                ...
                                         time,                 ...
                                         stop_analysis_meters, ...
                                         spatial_resolution,   ...
                                         spatial_reduction_factor)

% Compute the maximum height in m
vect_max_heights = calculate_max_height(time, stop_analysis_meters);

% Maximum height in pixel
pxl_stop = round((vect_max_heights./spatial_resolution) .* spatial_reduction_factor);
    
    for ii = 1 : size(edges, 2)

        edges(pxl_stop(ii) : end, ii) = 0;
    
    end

% ---------
end