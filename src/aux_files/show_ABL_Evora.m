%oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
%  Show ABL evolution
% ------------------------------------------------------------------------- 
% Inputs:  
%          data --------- [N_h_orig, N_t] = Original image 
%          ABL --------------- [N_h, N_t] = ABL map
%          spatial_red_factor -- [scalar] = Spatial reduction factor [-]
%          spatial_res --------- [scalar] = spatial resolution [m]
%          start_analysis_meters [scalar] = starting height [m]
%          disp_tag ------------ [string] = Display flag ('true'/'false')
%
% -------------------------------------------------------------------------
% Outputs:
%          ABL_xy [2, N_t_out] = ABL height coordinates
%                                    Row 1: Time axis
%                                    Row 2: Estimated ABL height
%
% -------------------------------------------------------------------------
% Notes:
% -------------------------------------------------------------------------
function ABL_xy = show_ABL_Evora(data,                  ...
                                 ABL,                   ...
                                 spatial_red_factor,    ...
                                 spatial_resolution,    ...
                                 start_analysis_meters, ...
                                 disp_tag)


x = [];
y = [];

for ii = 1 : size(ABL,2)
    
    vh = ABL(:,ii);
    
    if sum(vh) > 0
    
        x = cat(2, x, ii);
        y = cat(2, y, find(vh));
    
    end

end

ABL_xy = [x; y];

if strcmp(disp_tag, 'true')
    
    hf = figure;
    set(hf, 'units','normalized');
    set(hf,'outerposition',[0 0 1 1]);

    % pxl_min_visualization = round(start_analysis_meters/spatial_resolution);
    % pxl_max_visualization = round(10000/spatial_resolution);


    % pcolor(data(pxl_min_visualization : pxl_max_visualization, :));
    pcolor(data);
    shading flat; 
    colormap(turbo(16));
    colorbar
    pbaspect([16 9 1])

%%% Do not linearly interpolate when there is a big lack in the estimated ABL (more than 300 mins)

inddiffx = find(diff(x) > 300);

if ~isempty(inddiffx)

    for ii = 1 : numel(inddiffx)
    
        if ii == 1
        
            hold on, plot(x(1 : inddiffx(ii)), (y(1 : inddiffx(ii)))./spatial_red_factor, '-k', 'LineWidth', 5);
        
        else
            hold on, plot(x(inddiffx(ii - 1) : inddiffx(ii)), (y(inddiffx(ii - 1) : inddiffx(ii)))./spatial_red_factor, '-k', 'LineWidth', 5);
        end
    end
    hold on, h1 = plot(x(inddiffx(end) + 1 : end), (y(inddiffx(end) + 1 : end))./spatial_red_factor, '-k', 'LineWidth', 5);
else
    hold on, h1 = plot(x, y./spatial_red_factor, '-k', 'LineWidth', 5);
end

lgd = legend(h1, 'Layer 1');
lgd.FontSize = 14;

ax=gca;
ax.XTick = ceil(ax.XLim(1))-1 : 720 : floor(ax.XLim(2)); 

v = cell(1, numel(ax.XTick));

for ii = 1 : numel(ax.XTick)
    
    [~,hstr,mstr] = secs2hms(ax.XTick(ii) .* 30);
    
    if isscalar(hstr)
    
        hstr = cat(2, '0', hstr);
    
    end

    if isscalar(mstr)
    
        mstr = cat(2, '0', mstr);
    
    end
    
    v{ii} = [hstr, ':', mstr];

end

set(gca, 'XtickLabel', v)
set(gca, 'YtickLabel', 0.2 + (start_analysis_meters./10^3) + (ax.YTick .* (spatial_resolution./(10^3))))

xlabel('UTC Time [hh:mm]', 'FontSize', 14);
ylabel('Altitude [km]', 'FontSize', 14);

else

end

% ------------
end