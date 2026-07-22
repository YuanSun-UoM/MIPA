function missing_info = write_heights_netcdf_spec(ABL_xy, cfg, input_folder, output_folder)
%oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
% Write output NetCDF file according to target specification
%
% Inputs:
%   ABL_xy -------- [2 x N]
%                    row 1 = time indices
%                    row 2 = ABL heights in reduced coordinates
%
%   cfg ----------- configuration structure
%   input_folder --- folder of source NetCDF
%   output_folder -- folder where output NetCDF will be written
%
% Output:
%   missing_info --- cell array with metadata fields still missing
%
% Notes:
%   - ablh is written as altitude above sea level
%   - surface_altitude must be present in input NetCDF
%oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo

    missing_info = {};

    % ---------------------------------------------------------------------
    % Paths
    % ---------------------------------------------------------------------
    nc_in  = fullfile(input_folder,  [cfg.filename '.nc']);
    nc_out = fullfile(output_folder, ['Output_' cfg.filename '.nc']);

    if exist(nc_out, 'file')
        delete(nc_out);
    end

    info_in = ncinfo(nc_in);

    % ---------------------------------------------------------------------
    % Mandatory configuration checks
    % ---------------------------------------------------------------------
    required_cfg = {'filename', 'variable_filename', ...
                    'start_analysis_meters', 'stop_analysis_meters', ...
                    'spatial_red_factor', 'spatial_resolution'};

    for i = 1:numel(required_cfg)
        f = required_cfg{i};
        if ~isfield(cfg, f) || isempty(cfg.(f))
            error('Missing required cfg field: cfg.%s', f);
        end
    end

    % ---------------------------------------------------------------------
    % Read mandatory input variables
    % ---------------------------------------------------------------------
    time        = must_read_var(nc_in, 'time');
    altitude    = must_read_var(nc_in, 'altitude');
    time_bounds = try_read_var(nc_in, 'time_bounds');
    wavelength  = try_read_var(nc_in, 'wavelength');

    latitude         = try_read_var(nc_in, 'latitude');
    longitude        = try_read_var(nc_in, 'longitude');
    surface_altitude = try_read_var(nc_in, 'surface_altitude');

    if isempty(surface_altitude)
        error('surface_altitude not found in input NetCDF');
    end

    input_dataset_raw = must_read_var(nc_in, cfg.variable_filename);

    % ---------------------------------------------------------------------
    % Read reference variable if available
    % ---------------------------------------------------------------------
    if has_var(info_in, 'ablh_reference')
        ablh_reference = ncread(nc_in, 'ablh_reference');
        ablh_reference_src = 'ablh_reference';
        ablh_ref_fill = get_var_fillvalue(nc_in, 'ablh_reference', 9.96920996838687e+36);

    elseif has_var(info_in, 'pbl_reference')
        ablh_reference = ncread(nc_in, 'pbl_reference');
        ablh_reference_src = 'pbl_reference';
        ablh_ref_fill = get_var_fillvalue(nc_in, 'pbl_reference', 9.96920996838687e+36);

    else
        ablh_reference = [];
        ablh_reference_src = '';
        ablh_ref_fill = 9.96920996838687e+36;
        missing_info{end+1} = 'ablh_reference / pbl_reference not found in input NetCDF';
    end

    input_fill = get_var_fillvalue(nc_in, cfg.variable_filename, 9.96920996838687e+36);
    len_time   = numel(time);
    n_alt      = numel(altitude);

    % ---------------------------------------------------------------------
    % Reconstruct full ABL time series
    % ---------------------------------------------------------------------
    ABL_xy_I = reconstruct_full_abl_series(ABL_xy, len_time, input_fill);

    valid_values = (ABL_xy_I(2,:) ~= input_fill);

    ABL_xy_I(2, valid_values) = ...
        double(surface_altitude) + ...
        cfg.start_analysis_meters + ...
        (ABL_xy_I(2, valid_values) ./ cfg.spatial_red_factor) .* cfg.spatial_resolution;

    down_sampling_factor = round(1 / cfg.spatial_red_factor);

    if size(ABL_xy_I,2) ~= len_time
        error('Reconstructed ABL series length (%d) does not match len_time (%d).', ...
              size(ABL_xy_I,2), len_time);
    end

    % ---------------------------------------------------------------------
    % Ensure input_dataset orientation matches spec: (time, altitude)
    % ---------------------------------------------------------------------
    sz_input = size(input_dataset_raw);

    if numel(sz_input) ~= 2
        error('Input dataset "%s" is not 2D.', cfg.variable_filename);
    end

    if isequal(sz_input, [len_time, n_alt])
        input_dataset = input_dataset_raw;
    elseif isequal(sz_input, [n_alt, len_time])
        input_dataset = input_dataset_raw.';
    else
        error(['Input dataset "%s" has size [%d %d], incompatible with ' ...
               'time=%d and altitude=%d.'], ...
               cfg.variable_filename, sz_input(1), sz_input(2), len_time, n_alt);
    end

    % ---------------------------------------------------------------------
    % Ensure time_bounds orientation matches spec: (time, nv)
    % ---------------------------------------------------------------------
    if isempty(time_bounds)
        time_bounds = derive_time_bounds(time);
        missing_info{end+1} = 'time_bounds missing in input -> derived automatically';
    else
        sz_tb = size(time_bounds);
        if isequal(sz_tb, [len_time, 2])
            % ok
        elseif isequal(sz_tb, [2, len_time])
            time_bounds = time_bounds.';
        else
            error('time_bounds has incompatible size.');
        end
    end

    % ---------------------------------------------------------------------
    % Create dimensions and variables
    % ---------------------------------------------------------------------
    nccreate(nc_out, 'time', ...
             'Dimensions', {'time', len_time}, ...
             'Datatype', 'double');

    nccreate(nc_out, 'time_bounds', ...
         'Dimensions', {'nv', 2, 'time', len_time}, ...
         'Datatype', 'double');

    nccreate(nc_out, 'altitude', ...
             'Dimensions', {'altitude', n_alt}, ...
             'Datatype', 'double');

    nccreate(nc_out, 'wavelength', ...
             'Datatype', 'double', ...
             'FillValue', input_fill);

    nccreate(nc_out, 'latitude', 'Datatype', 'double');
    nccreate(nc_out, 'longitude', 'Datatype', 'double');
    nccreate(nc_out, 'surface_altitude', 'Datatype', 'double');

    nccreate(nc_out, 'input_dataset', ...
             'Dimensions', {'altitude', n_alt, 'time', len_time}, ...%{'time', len_time, 'altitude', n_alt}, ...
             'Datatype', 'double', ...
             'FillValue', input_fill);

    if ~isempty(ablh_reference)
        nccreate(nc_out, 'ablh_reference', ...
                 'Dimensions', {'time', len_time}, ...
                 'Datatype', 'double', ...
                 'FillValue', ablh_ref_fill);
    end

    nccreate(nc_out, 'ablh', ...
             'Dimensions', {'time', len_time}, ...
             'Datatype', 'double', ...
             'FillValue', input_fill);

    create_scalar_int_var(nc_out, 'mipa_upper_percentile');
    create_scalar_int_var(nc_out, 'mipa_lower_percentile');
    create_scalar_int_var(nc_out, 'mipa_down_sampling_factor');
    create_scalar_int_var(nc_out, 'mipa_pre_processing_structuring_element_length_factor');
    create_scalar_int_var(nc_out, 'mipa_post_processing_structuring_element_length_factor');
    create_scalar_int_var(nc_out, 'mipa_post_processing_structuring_element_minimum_angle');
    create_scalar_int_var(nc_out, 'mipa_post_processing_structuring_element_maximum_angle');
    create_scalar_int_var(nc_out, 'mipa_euclidean_distance_threshold');

    nccreate(nc_out, 'mipa_altitude_range', ...
             'Dimensions', {'altitude_range', 2}, ...
             'Datatype', 'double');

    % ---------------------------------------------------------------------
    % Write variables
    % ---------------------------------------------------------------------
    ncwrite(nc_out, 'time', time);
    ncwrite(nc_out, 'time_bounds', time_bounds.');
    ncwrite(nc_out, 'altitude', altitude);

    if ~isempty(wavelength)
        ncwrite(nc_out, 'wavelength', wavelength);
    else
        ncwrite(nc_out, 'wavelength', input_fill);
        missing_info{end+1} = 'wavelength missing in input NetCDF';
    end

    if ~isempty(latitude)
        ncwrite(nc_out, 'latitude', latitude);
    else
        ncwrite(nc_out, 'latitude', NaN);
        missing_info{end+1} = 'latitude missing in input NetCDF';
    end

    if ~isempty(longitude)
        ncwrite(nc_out, 'longitude', longitude);
    else
        ncwrite(nc_out, 'longitude', NaN);
        missing_info{end+1} = 'longitude missing in input NetCDF';
    end

    ncwrite(nc_out, 'surface_altitude', double(surface_altitude));
    ncwrite(nc_out, 'input_dataset', input_dataset.');

    if ~isempty(ablh_reference)
        ncwrite(nc_out, 'ablh_reference', ablh_reference);
    end

    ncwrite(nc_out, 'ablh', ABL_xy_I(2,:));

    ncwrite(nc_out, 'mipa_altitude_range', ...
            double([cfg.start_analysis_meters; cfg.stop_analysis_meters]));

    % ---------------------------------------------------------------------
    % Copy local attributes from input variables where possible
    % ---------------------------------------------------------------------
    copy_variable_attributes(nc_in, 'time', nc_out, 'time', ...
        {'units','long_name','calendar','axis','bounds'});

    if has_var(info_in, 'time_bounds')
        copy_variable_attributes(nc_in, 'time_bounds', nc_out, 'time_bounds', {});
    end

    copy_variable_attributes(nc_in, 'altitude', nc_out, 'altitude', ...
        {'units','axis','positive','standard_name','long_name'});

    if ~isempty(wavelength) && has_var(info_in, 'wavelength')
        copy_variable_attributes(nc_in, 'wavelength', nc_out, 'wavelength', ...
            {'units','long_name','_FillValue'});
    end

    if has_var(info_in, 'latitude')
        copy_variable_attributes(nc_in, 'latitude', nc_out, 'latitude', ...
            {'units','standard_name','long_name'});
    end

    if has_var(info_in, 'longitude')
        copy_variable_attributes(nc_in, 'longitude', nc_out, 'longitude', ...
            {'units','standard_name','long_name'});
    end

    if has_var(info_in, 'surface_altitude')
        copy_variable_attributes(nc_in, 'surface_altitude', nc_out, 'surface_altitude', ...
            {'units','standard_name','long_name'});
    end

    copy_variable_attributes(nc_in, cfg.variable_filename, nc_out, 'input_dataset', ...
        {'units','long_name','coordinates','_FillValue'});

    if ~isempty(ablh_reference)
        copy_variable_attributes(nc_in, ablh_reference_src, nc_out, 'ablh_reference', ...
            {'units','long_name','_FillValue'});
    end

    % ---------------------------------------------------------------------
    % Write MIPA scalar parameters from cfg
    % ---------------------------------------------------------------------
    write_scalar_int(nc_out, 'mipa_upper_percentile', ...
                     get_cfg_value(cfg, 'p_high', []));

    write_scalar_int(nc_out, 'mipa_lower_percentile', ...
                     get_cfg_value(cfg, 'p_low', []));

    write_scalar_int(nc_out, 'mipa_down_sampling_factor', ...
                     down_sampling_factor);

    write_scalar_int(nc_out, 'mipa_pre_processing_structuring_element_length_factor', ...
                     get_cfg_value(cfg, 'line_length', []));

    write_scalar_int(nc_out, 'mipa_post_processing_structuring_element_length_factor', ...
                     get_cfg_value(cfg, 'line_postprocessing', []));

    write_scalar_int(nc_out, 'mipa_post_processing_structuring_element_minimum_angle', ...
                     get_cfg_value(cfg, 'starting_angle_morph_grad', []));

    write_scalar_int(nc_out, 'mipa_post_processing_structuring_element_maximum_angle', ...
                     get_cfg_value(cfg, 'max_angle_postprocessing', []));

    write_scalar_int(nc_out, 'mipa_euclidean_distance_threshold', ...
                     get_cfg_value(cfg, 'delta_0', []));

    % ---------------------------------------------------------------------
    % Variable attributes required by spec
    % ---------------------------------------------------------------------
    ncwriteatt(nc_out, 'time', 'units', 'seconds since 1970-01-01T00:00:00Z');
    ncwriteatt(nc_out, 'time', 'long_name', 'time');
    ncwriteatt(nc_out, 'time', 'calendar', 'standard');
    ncwriteatt(nc_out, 'time', 'axis', 'T');
    ncwriteatt(nc_out, 'time', 'bounds', 'time_bounds');

    if ~isempty(ablh_reference)
        ncwriteatt(nc_out, 'ablh_reference', 'units', 'm');
        ncwriteatt(nc_out, 'ablh_reference', 'long_name', ...
                   'reference atmospheric boundary layer altitude');
    end

    ncwriteatt(nc_out, 'altitude', 'units', 'm');
    ncwriteatt(nc_out, 'altitude', 'axis', 'Z');
    ncwriteatt(nc_out, 'altitude', 'positive', 'up');
    ncwriteatt(nc_out, 'altitude', 'standard_name', 'altitude');
    ncwriteatt(nc_out, 'altitude', 'long_name', 'altitude above sea level');

    ncwriteatt(nc_out, 'wavelength', 'units', 'nm');
    ncwriteatt(nc_out, 'wavelength', 'long_name', 'detection data wavelength');

    ncwriteatt(nc_out, 'latitude', 'standard_name', 'latitude');
    ncwriteatt(nc_out, 'latitude', 'long_name', 'measurement site latitude');
    ncwriteatt(nc_out, 'latitude', 'units', 'degrees_north');

    ncwriteatt(nc_out, 'longitude', 'standard_name', 'longitude');
    ncwriteatt(nc_out, 'longitude', 'long_name', 'measurement site longitude');
    ncwriteatt(nc_out, 'longitude', 'units', 'degrees_east');

    ncwriteatt(nc_out, 'surface_altitude', 'units', 'm');
    ncwriteatt(nc_out, 'surface_altitude', 'standard_name', 'surface_altitude');
    ncwriteatt(nc_out, 'surface_altitude', 'long_name', ...
               'measurement site altitude above sea level');

    ncwriteatt(nc_out, 'input_dataset', 'units', '1');
    ncwriteatt(nc_out, 'input_dataset', 'long_name', ...
               'input remote sensing dataset in arbitrary units');
    ncwriteatt(nc_out, 'input_dataset', 'coordinates', 'time altitude');

    ncwriteatt(nc_out, 'ablh', 'long_name', 'atmospheric boundary layer altitude');
    ncwriteatt(nc_out, 'ablh', 'units', 'm');

    set_int_var_attrs(nc_out, 'mipa_upper_percentile', ...
        'applied percentile upper limit for clipping', '1', false);

    set_int_var_attrs(nc_out, 'mipa_lower_percentile', ...
        'applied percentile lower limit for clipping', '1', false);

    set_int_var_attrs(nc_out, 'mipa_down_sampling_factor', ...
        'applied image down-sampling factor', '1', false);

    set_int_var_attrs(nc_out, 'mipa_pre_processing_structuring_element_length_factor', ...
        'applied pre-processing structuring element length factor in units of down-sampled resolution', ...
        '1', false);

    set_int_var_attrs(nc_out, 'mipa_post_processing_structuring_element_length_factor', ...
        'applied post-processing structuring element length factor in units of down-sampled resolution', ...
        '1', false);

    set_int_var_attrs(nc_out, 'mipa_post_processing_structuring_element_minimum_angle', ...
        'applied post-processing structuring element minimum angle with respect to horizontal direction', ...
        'degrees', false);

    set_int_var_attrs(nc_out, 'mipa_post_processing_structuring_element_maximum_angle', ...
        'applied post-processing structuring element maximum angle with respect to horizontal direction', ...
        'degrees', false);

    set_int_var_attrs(nc_out, 'mipa_euclidean_distance_threshold', ...
        ['reference Euclidean distance threshold used during object-based ' ...
     'analysis, expressed in range bins at the original vertical resolution'], ...
        '1', false);

    ncwriteatt(nc_out, 'mipa_altitude_range', 'units', 'm');
    ncwriteatt(nc_out, 'mipa_altitude_range', 'long_name', ...
               'applied altitude range for MIPA analysis');
    ncwriteatt(nc_out, 'mipa_altitude_range', 'description', ...
               'lower and upper altitude limits used for the MIPA analysis');
    ncwriteatt(nc_out, 'mipa_altitude_range', 'bounds_order', ...
               'start_analysis_meters, stop_analysis_meters');

    % ---------------------------------------------------------------------
    % Copy global attributes
    % ---------------------------------------------------------------------
    copy_global_attributes(nc_in, nc_out, {});

    % ---------------------------------------------------------------------
    % Overwrite / complete global attributes
    % ---------------------------------------------------------------------
    write_global_attr(nc_out, 'title', 'Atmospheric Boundary Layer Dataset');
    write_global_attr(nc_out, 'source', get_cfg_value(cfg, 'source', '__MISSING__'));
    write_global_attr(nc_out, 'references', get_cfg_value(cfg, 'references', '__MISSING__'));
    write_global_attr(nc_out, 'citation', get_cfg_value(cfg, 'citation', '__MISSING__'));
    write_global_attr(nc_out, 'data_processing_institution', ...
        get_cfg_value(cfg, 'data_processing_institution', '__MISSING__'));
    write_global_attr(nc_out, 'data_processing_institution_ror', ...
        get_cfg_value(cfg, 'data_processing_institution_ror', '__MISSING__'));
    write_global_attr(nc_out, 'PI', get_cfg_value(cfg, 'PI', '__MISSING__'));
    write_global_attr(nc_out, 'PI_affiliation', get_cfg_value(cfg, 'PI_affiliation', '__MISSING__'));
    write_global_attr(nc_out, 'PI_affiliation_acronym', get_cfg_value(cfg, 'PI_affiliation_acronym', '__MISSING__'));
    write_global_attr(nc_out, 'PI_address', get_cfg_value(cfg, 'PI_address', '__MISSING__'));
    write_global_attr(nc_out, 'PI_phone', get_cfg_value(cfg, 'PI_phone', '__MISSING__'));
    write_global_attr(nc_out, 'PI_email', get_cfg_value(cfg, 'PI_email', '__MISSING__'));
    write_global_attr(nc_out, 'PI_orcid', get_cfg_value(cfg, 'PI_orcid', '__MISSING__'));
    write_global_attr(nc_out, 'acknowledgements', ...
        get_cfg_value(cfg, 'acknowledgements', '__MISSING__'));
    write_global_attr(nc_out, 'processor_name', 'MIPA');
    write_global_attr(nc_out, 'processor_longname', 'Morphological Image Processing Approach');
    write_global_attr(nc_out, 'processor_version', ...
        get_cfg_value(cfg, 'processor_version', '1.0.0'));

    % ---------------------------------------------------------------------
    % Collect missing processing metadata
    % ---------------------------------------------------------------------
    required_processing_fields = { ...
        'source', 'references', 'citation', 'data_processing_institution', ...
        'data_processing_institution_ror', 'PI', 'PI_affiliation', ...
        'PI_affiliation_acronym', 'PI_address', 'PI_phone', ...
        'PI_email', 'PI_orcid', 'acknowledgements', 'processor_version'};

    for i = 1:numel(required_processing_fields)
        f = required_processing_fields{i};
        v = get_cfg_value(cfg, f, '__MISSING__');
        if ischar(v) || isstring(v)
            if strcmp(string(v), "__MISSING__")
                missing_info{end+1} = ['Missing processing metadata in cfg: ' f];
            end
        end
    end

    if ~isfield(cfg, 'base_variation')
        missing_info{end+1} = 'mipa_euclidean_distance_threshold mapping is uncertain';
    end

    if has_decimal(get_cfg_value(cfg, 'p_high', [])) || has_decimal(get_cfg_value(cfg, 'p_low', []))
        missing_info{end+1} = ['Percentiles are written as rounded integers. ' ...
                               'If decimal preservation is required, the writer must be adapted.'];
    end
end


% =========================================================================
% Helper functions
% =========================================================================

function out = must_read_var(ncfile, varname)
    try
        out = ncread(ncfile, varname);
    catch
        error('Required variable "%s" not found in input NetCDF.', varname);
    end
end

function out = try_read_var(ncfile, varname)
    try
        out = ncread(ncfile, varname);
    catch
        out = [];
    end
end

function tf = has_var(info_in, varname)
    tf = false;
    if isfield(info_in, 'Variables') && ~isempty(info_in.Variables)
        vars = info_in.Variables;
        for k = 1:numel(vars)
            if strcmp(vars(k).Name, varname)
                tf = true;
                return
            end
        end
    end
end

function fill_value = get_var_fillvalue(ncfile, varname, default_value)
    try
        fill_value = ncreadatt(ncfile, varname, '_FillValue');
    catch
        fill_value = default_value;
    end
end

function ABL_xy_I = reconstruct_full_abl_series(ABL_xy, len_time, fill_value)
    if isempty(ABL_xy) || size(ABL_xy,1) ~= 2
        error('ABL_xy must be a non-empty 2xN matrix.');
    end

    ABL_xy_I = [];

    if ABL_xy(1,1) > 1
        start_times = 1:(ABL_xy(1,1)-1);
        start_vals  = fill_value * ones(1, numel(start_times));
        ABL_xy_I = [start_times; start_vals];
    end

    delta_t = diff(ABL_xy(1,:));

    for ii = 1:numel(delta_t)
        ABL_xy_I = cat(2, ABL_xy_I, ABL_xy(:,ii));

        if delta_t(ii) > 1
            gap_times = (ABL_xy(1,ii) + 1) : (ABL_xy(1,ii+1) - 1);
            gap_vals  = fill_value * ones(1, numel(gap_times));
            ABL_xy_I = cat(2, ABL_xy_I, [gap_times; gap_vals]);
        end
    end

    ABL_xy_I = cat(2, ABL_xy_I, ABL_xy(:,end));

    if ABL_xy(1,end) < len_time
        end_times = (ABL_xy(1,end) + 1) : len_time;
        end_vals  = fill_value * ones(1, numel(end_times));
        ABL_xy_I = cat(2, ABL_xy_I, [end_times; end_vals]);
    end
end

function create_scalar_int_var(nc_out, varname)
    nccreate(nc_out, varname, ...
             'Datatype', 'int32', ...
             'FillValue', int32(-2147483647));
end

function write_scalar_int(nc_out, varname, value)
    if isempty(value)
        ncwrite(nc_out, varname, int32(-2147483647));
    else
        ncwrite(nc_out, varname, int32(round(value)));
    end
end

function set_int_var_attrs(nc_out, varname, long_name, units, add_scale_attrs)
    ncwriteatt(nc_out, varname, 'long_name', long_name);
    ncwriteatt(nc_out, varname, 'units', units);

    if add_scale_attrs
        ncwriteatt(nc_out, varname, 'scale_factor', 100);
        ncwriteatt(nc_out, varname, 'add_offset', 0);
    end
end

function tb = derive_time_bounds(time)
    n = numel(time);
    tb = zeros(n, 2);

    if n == 1
        tb(1,:) = [time(1), time(1)];
        return
    end

    dt = diff(time);
    dt_med = median(dt);

    tb(:,1) = time - dt_med/2;
    tb(:,2) = time + dt_med/2;
end

function val = get_cfg_value(cfg, fieldname, default_value)
    if isfield(cfg, fieldname) && ~isempty(cfg.(fieldname))
        val = cfg.(fieldname);
    else
        val = default_value;
    end
end

function write_global_attr(nc_out, name, value)
    ncwriteatt(nc_out, '/', name, value);
end

function tf = has_decimal(x)
    if isempty(x)
        tf = false;
    else
        tf = abs(x - round(x)) > 0;
    end
end

function copy_variable_attributes(nc_in, var_in, nc_out, var_out, skip_attrs)
    if nargin < 5
        skip_attrs = {};
    end

    try
        info = ncinfo(nc_in, var_in);
    catch
        warning('Cannot read variable info for "%s".', var_in);
        return
    end

    if ~isfield(info, 'Attributes') || isempty(info.Attributes)
        return
    end

    attrs = info.Attributes;

    for k = 1:numel(attrs)
        att_name = attrs(k).Name;

        if any(strcmp(att_name, skip_attrs))
            continue
        end

        try
            att_val = ncreadatt(nc_in, var_in, att_name);
            ncwriteatt(nc_out, var_out, att_name, att_val);
        catch
            warning('Could not copy attribute "%s" from "%s" to "%s".', ...
                    att_name, var_in, var_out);
        end
    end
end

function copy_global_attributes(nc_in, nc_out, skip_attrs)
    if nargin < 3
        skip_attrs = {};
    end

    try
        info = ncinfo(nc_in);
    catch
        warning('Cannot read input NetCDF info for global attributes.');
        return
    end

    if ~isfield(info, 'Attributes') || isempty(info.Attributes)
        warning('No global attributes found in input NetCDF.');
        return
    end

    attrs = info.Attributes;

    for k = 1:numel(attrs)
        att_name = attrs(k).Name;

        if any(strcmp(att_name, skip_attrs))
            continue
        end

        try
            att_val = ncreadatt(nc_in, '/', att_name);
            ncwriteatt(nc_out, '/', att_name, att_val);
        catch
            warning('Could not copy global attribute "%s".', att_name);
        end
    end
end