%oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
%  Radiometric normalization with Percentile Clipping
% -------------------------------------------------------------------------
% 
% Inputs:  
%          im ------------ [N_row, N_col] = RCS Image 
%          p_low --------------- [scalar] = Lower-bound percentile
%          p_high -------------- [scalar] = Upper-bound percentile
%          fill_value -----------[scalar] = NetCDF fill value
%
% -------------------------------------------------------------------------
% Outputs:
%          im ------------ [N_row, N_col] = Normalized Data
%
% -------------------------------------------------------------------------
function im = rad_normalize_data_test(im, p_low, p_high, fill_value, im_ref)

    im = double(im);
    im_ref = double(im_ref);

    % Valid pixels for percentile calculation
    valid_ref = isfinite(im_ref) & (im_ref ~= fill_value);

    valid_values = im_ref(valid_ref);

    if isempty(valid_values)
        error('No valid values for normalization.');
    end

    % Global percentiles from reference image
    p_low_val = prctile(valid_values, p_low);
    p_high_val = prctile(valid_values, p_high);

    fprintf('Reference P_low  = %.6e\n', p_low_val);
    fprintf('Reference P_high = %.6e\n', p_high_val);

    if p_high_val <= p_low_val
        error('Invalid percentile range.');
    end

    % Valid pixels in analysis image
    valid_mask = isfinite(im) & (im ~= fill_value);

    % Normalize
    im = (im - p_low_val) ./ (p_high_val - p_low_val);

    % Clip to [0, 1]
    im = max(0, min(1, im));

    % Replace invalid pixels
    im(~valid_mask) = 0;

end