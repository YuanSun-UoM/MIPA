%oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
% NetCDF File Reader
% -------------------------------------------------------------------------
%
% Inputs:  
%          cfg ----------- [struct] = Structure containing all
%                                     configuration parameters
%
% -------------------------------------------------------------------------
% Outputs:
%          data ---------- [struct] = Structure containing all extracted 
%                                     data from the NetCDF file including
%                                     measurements, coordinates, and
%                                     metadata.
%
% -------------------------------------------------------------------------
% Notes:
%
% -------------------------------------------------------------------------
function data = reading_netcdf(cfg)

ncid = netcdf.open(sprintf('%s.nc',cfg.filename), 'NC_NOWRITE');

% Get basic info about the file
[n_dims, n_vars, ~, ~] = netcdf.inq(ncid);

disp('-------------------------------------------------------------------')
disp('NetCDF reading')
disp(' ')
% List the dimensions of the file
for dimid = 0: n_dims - 1
    
    [dimname, dimlen] = netcdf.inqDim(ncid, dimid);
    disp(['Dimension ', dimname, ' (size: ', num2str(dimlen), ')']);

end

% Read variables into a struct
variables = struct();
for varid = 0:n_vars-1
    [varname, ~] = netcdf.inqVar(ncid, varid);
    disp(['Variable: ', varname]);
    variables.(varname) = double(netcdf.getVar(ncid, varid));
end

disp('-------------------------------------------------------------------')

% Vertical resolution extraction
[vert_resolution, ~] = min(round(diff(variables.altitude)));

% Map variables to standard field names

rcs_data = variables.(cfg.variable_filename);

if isempty(rcs_data)

    error(['Variable filename not found in the NetCDF file. ...' ...
        'Please modify the config file with correct variable filename (i.e., range_corrected_signal, attenuated_backscatter']);
else
    
end

netcdf.close(ncid);    

% Check if pbl_reference exists in variables
if isfield(variables, 'pbl_reference')
    data.reference = variables.pbl_reference;
else
    data.reference = [];  
end


% Check if surface_altitude exists in variables
if isfield(variables, 'surface_altitude')
    data.surface_altitude = variables.surface_altitude;
else
    data.surface_altitude = [];  
end

data.rcs      = rcs_data;
data.time     = variables.time;
data.altitude = variables.altitude;
data.wavelength = variables.wavelength;
data.spatial_resolution = vert_resolution;


%---------    
end


