%----------------------------------------------------------------------------
% Morphological Image Processing Approach (MIPA) for ABLH estimation from 
% Lidar/Ceilometer data
%--------------------------------------------------------------------------
%   The MIPA pipeline comprises the following steps:
%
%       [1] Loading data and setting the configuration file
%        |
%        |  The required input file must be a NetCDF file containing the 
%        |  following mandatory fields:
%        |
%        |    input signal------------- [time × altitude]: attenuated 
%        |                              backscatter or range corrected
%        |                              signal
%        |    time -------------------- [time × 1]: time vector             
%        |    altitude ---------------- [altitude × 1]: altitude vector 
%        |
%        |  where:
%        |    time dimension = N_t samples
%        |    altitude dimension = N_h bins
%        |    nv dimension = 2 (for bounds variables)
%        |
%        |  For more information, see the documentation file in the docs
%        |  folder.
%        |        
%        |  Before running the code, check and set the configuration file 
%        |  (config_MIPA.m), specifically the following parameters:
%        |
%        |  [1] Change with the name of the NetCDF file inside the folder 
%        |      data/input, such as:
%        |      cfg.filename = 'bella_lidar_1064_bck_slot4_abl'
%        |  
%        |  [2] Specify the name of the variable containing the measurement
%        |      in the NetCDF file, such as:
%        |      cfg.variable_filename = 'attenuated_backscatter' or 
%        |      cfg.variable_filename = 'range_corrected_signal'
%        |
%        |  [3] Specify the type of measurement
%        |      cfg.measurement_tag = 'lidar'; % or 'ceilometer'
%        |
%        |  [4] Specify the original vertical resolution in meters:
%        |      cfg.spatial_resolution 
%        |
%        |  [5] Specify the altitude of the instrument in meters above 
%        |      ground level:
%        |      cfg.surface_altitude
%        |
%        |  [6] Specify the altitude interval used for processing: 
%        |      cfg.start_analysis_meters
%        |      cfg.stop_analysis_meters
%        |
%       [2] MIPA [Actual algorithm]
%        |
%        |-> [2.1] Radiometric Normalization
%              |
%              | Percentile clipping of the backscatter signal to reduce 
%              | dynamic range and enhance aerosol layer contrast for 
%              | improved edge detection and ABLH estimation.
%              |
%            [2.2] Vertical spatial resolution degradation
%              |
%              |  The vertical resolution is degraded to a desired lower 
%              |  resolution. A vertical moving average is applied with 
%              |  downscaling factor R = desired resolution / original 
%              |  resolution.
%              |
%            [2.3] Pre-processing
%              |
%              |  Low-pass filtering using Half-Gradient filters in the 
%              |  horizontal (time) direction to directionally reduce 
%              |  unintended fluctuations and preserve the vertical edges. 
%              |
%            [2.4] Edge detection
%              | 
%              |  In this step, any edge detector might be employed. The 
%              |  Canny detector is employed in its default MATLAB version.
%              |  Sobel, Prewitt and WCT are also available.
%              | 
%            [2.5] Post-processing
%              | 
%           [2.5.1] Morphological filters
%              | 
%              |   Directional low-pass morphological filters
%              |   to remove unrealistic, rapidly fluctuating edges.
%              |
%           [2.5.2] Object-based Analysis
%              | 
%              |   Group 8-connected edge pixels into objects, 
%              |   remove outliers based on height differences, and
%              |   interpolate remaining objects to estimate ABLH.
%              |
%        <-| [2.6] ABLH estimate
%        |
%       [3] Saving results
%        |
%        |  The output file is generated as a copy of the original NetCDF 
%        |  file, with the addition of a new variable containing the 
%        |  estimated ABLH (ablh). The file is saved in the 
%        |  data/output folder with the name "Output_<original_filename>.nc"
%        |
%      [End]
%
%--------------------------------------------------------------------------

% ----------
close all;
clear all;
clc;
% ----------

% Folders -----------------------------------------------------------------
here = pwd;
aux_files_folder   = genpath(fullfile(here, 'aux_files'));  
input_data_folder  = fullfile(here, '..', 'data/input/');  
output_data_folder = fullfile(here, '..', 'data/output');  
addpath(aux_files_folder);

% [1] Import configuration parameters and load NetCDF file -----------------

cfg = config_MIPA(); % ---------------- Configuration parameters extraction
cfg = metadata_MIPA(cfg); % ------------------------------- Adding metadata

cd(input_data_folder)
data = reading_netcdf(cfg); % ------------------------- Reading NetCDF file

if ~isempty(data.spatial_resolution)
    cfg.spatial_resolution = data.spatial_resolution;
end
if ~isempty(data.surface_altitude)
    cfg.surface_altitude = data.surface_altitude;
end

% If no upper analysis limit is specified, use the highest available
% altitude in the input dataset.
if isempty(cfg.stop_analysis_meters)
    cfg.stop_analysis_meters = max(data.altitude);
end

cd(here)


% MIPA --------------------------------------------------------------------

% [2.1] --- Radiometric normalization 

% Read fill value from input variable
ncfile = fullfile(input_data_folder, [cfg.filename '.nc']);
fill_value = ncreadatt(ncfile, cfg.variable_filename, '_FillValue');

image_ir = crop_profile(data.rcs,...
                        cfg.start_analysis_meters,...
                        cfg.stop_analysis_meters, ...
                        cfg.spatial_resolution);


image_ir(image_ir < 0) = 0; % ---------------------- Remove negative values
image_ir_norm = rad_normalize_data(image_ir,  ...
                                   cfg.p_low, ...
                                   cfg.p_high, ...
                                   fill_value);
% keyboard
% Figure display
if strcmp(cfg.figures_disp_flag, 'true')

    figure('Units','normalized',                             ...
           'InnerPosition',[0.0078, 0.4870, 0.9760, 0.3490], ...
           'OuterPosition',[0.0036, 0.4796, 0.9843, 0.4370]);

    t = tiledlayout(1, 5);  
    
    % First plot
    ax1 = nexttile;
    h1 = pcolor(ax1, image_ir_norm);
    shading flat; 
    colormap(ax1, turbo);
    colorbar(ax1);
    title(ax1, 'Normalized');
    ax1.XTick = [];
    ax1.YTick = [];
    
end 

% Save mat file into data/input 
cd(input_data_folder)
save(sprintf('%s.mat', cfg.filename), 'image_ir_norm', 'data')
cd(here)

% Step [2.2] --- Vertical spatial resolution reduction --------------------
image_ir_norm_deg = vertical_spatial_reduction(image_ir_norm,          ...
                                               cfg.spatial_red_factor, ...
                                               cfg.mov_avg_tag);
    

% Figure display    
if strcmp(cfg.figures_disp_flag, 'true')
    
    % Second plot
    ax2 = nexttile;
    h2 = pcolor(ax2, image_ir_norm_deg);
    shading flat;
    colormap(ax2, turbo);
    colorbar(ax2);
    title(ax2, 'Degraded');
    ax2.XTick = [];
    ax2.YTick = [];

end 
    
% Step [2.3] --- Preprocessing  -------------------------------------------

if cfg.flag_preprocessing_mf == 1
        
    output_preproc = pre_processing(image_ir_norm_deg,               ...
                                      cfg.flag_morph_grad,           ...
                                      cfg.line_length,               ...
                                      cfg.starting_angle_morph_grad, ...
                                      cfg.stopping_angle_morph_grad);
else
    
    % No pre-processing
    output_preproc = image_ir_norm_deg;

end

% Figure display
if strcmp(cfg.figures_disp_flag, 'true')
    
    % Third plot
    ax3 = nexttile;
    h3 = pcolor(ax3, output_preproc);
    shading flat;
    colormap(ax3, turbo);
    colorbar(ax3);
    title(ax3, 'Preprocessed');
    ax3.XTick = [];
    ax3.YTick = [];

end 
    
% Step [2.4] --- Edge detection -------------------------------------------

edges = edge_detection(output_preproc,     ...
                       cfg.flag_edge_detector, ...
                       cfg.des_res);
    
% Step [2.4.1] --- Delete unfeasible detections
    
if isfield(data, 'time')
        
    edges_refined = delete_unfeas_detection(edges,                    ...
                                            data.time,                ...
                                            cfg.stop_analysis_meters, ...
                                            cfg.spatial_resolution,   ...
                                            cfg.spatial_red_factor);
else

    edges_refined = edges;
end

% Figure display
if strcmp(cfg.figures_disp_flag, 'true')
    
    ax4 = nexttile;
    h4 = pcolor(ax4, edges_refined);
    shading flat;
    colormap(ax4, bone(2));
    colorbar(ax4);
    title(ax4, 'Edge map');
    ax4.XTick = [];
    ax4.YTick = [];

end 
    
% Step [2.5] --- Post-processing ------------------------------------------
    
if cfg.flag_postprocessing == 1
    
   edges_post = morphological_post_processing(edges_refined,            ...
                                              cfg.line_postprocessing,  ...
                                              cfg.max_angle_postprocessing);
    
else
        
    edges_post = edges_refined;
    
end

% Figure display
if strcmp(cfg.figures_disp_flag, 'true')
    
    ax5 = nexttile;
    h5 = pcolor(ax5, edges_post);
    shading flat;
    colormap(ax5, bone(2));
    colorbar(ax5);
    title(ax5, 'Edge map post-processed');
    ax5.XTick = [];
    ax5.YTick = [];
end 

% Final ABL extraction ----------------------------------------------------

[abl_tmp, ~] = extract_abl(edges_post,        ...
                           cfg.th_ext_abl,    ...
                           cfg.w_ext_abl,     ...
                           cfg.perc_null_abl_pxls);

ABL = check_variability_abl(abl_tmp,             ...
                            cfg.thr_dim_objs,    ...
                            cfg.thr_variation,   ...
                            cfg.w_obj_check,     ...
                            cfg.w_time_min);


 ABL_xy = show_ABL_Evora(image_ir_norm,             ...
                         ABL,                       ...
                         cfg.spatial_red_factor,    ...
                         cfg.spatial_resolution,    ...
                         cfg.start_analysis_meters, ...
                         cfg.figures_disp_flag);
 

if strcmp(cfg.figures_save_flag, 'true') && strcmp(cfg.figures_disp_flag, 'true')
    
    cd(output_data_folder)
    figHandles = findall(0, 'Type', 'figure');

    figure(figHandles(1));
    saveas(figHandles(1), sprintf('Intermediate_steps_%s.png', cfg.filename));

    figure(figHandles(2));
    saveas(figHandles(2), sprintf('ABL_evolution_%s.png', cfg.filename));

end

% Output file (NetCDF) creation and save 

cd(output_data_folder)
% write_heights_netcdf(ABL_xy,                         ...
%                      cfg.start_analysis_meters,      ...
%                      cfg.spatial_resolution,         ...
%                      cfg.spatial_red_factor,         ...
%                      cfg.filename,                   ...
%                      cfg.variable_filename,          ...
%                      input_data_folder,              ...
%                      output_data_folder,             ...
%                      cfg.baseline,                   ...
%                      size(edges_post, 2),            ...
%                      cfg.p_high);
missing_info = write_heights_netcdf_spec(ABL_xy, cfg, ...
                                         input_data_folder, ...
                                         output_data_folder);

if ~isempty(missing_info)
    disp('Fields still missing or needing verification:')
    disp(missing_info(:))
end
cd(here)

disp(' NetCDF with ABLH estimate saved!')
disp('-------------------------------------------------------------------')

% -------------
