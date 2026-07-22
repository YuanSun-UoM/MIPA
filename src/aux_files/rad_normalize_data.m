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
function im = rad_normalize_data(im, p_low, p_high, fill_value)
    
    im = double(im);
    valid_mask = (im ~= fill_value) & isfinite(im) ;%& (im > 0);
    valid_values = im(valid_mask);
    if isempty(valid_values)
        error('rad_normalize_data:NoValidValues', ...
              'No valid values available for percentile computation.');
    end

    % Percentiles computed only on valid values
    p_low_val = prctile(valid_values, p_low);
    p_high_val = prctile(valid_values, p_high);

    if p_high_val <= p_low_val
        error('rad_normalize_data:InvalidPercentiles', ...
              'Computed percentiles are invalid: p_high_val <= p_low_val.');
    end

    % Normalize whole image
    im = (im - p_low_val) ./ (p_high_val - p_low_val);

    % Clamp to [0, 1]
    im(im < 0) = 0;
    im(im > 1) = 1;

    % Put invalid values to 0 in the normalized output
    im(~valid_mask) = 0;
end