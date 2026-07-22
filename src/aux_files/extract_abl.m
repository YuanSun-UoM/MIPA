%oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
%  Extraction of ABL
% -------------------------------------------------------------------------
% 
% Inputs:  
%          edges_pp ----------- [N_h, N_t] = Edge detection result image
%          th_ext_abl ----------- [scalar] = Threshold 
%          w_ext_abl ------------ [scalar] = Window width for extraction
%          perc_null_ABL_pxls --- [scalar] = Max percentage of null pixels 
%
% -------------------------------------------------------------------------
% Outputs:
%          ABL ---------------- [N_h, N_t] = Final ABL binary map
%          ABL_raw ------------ [N_h, N_t] = Raw ABL binary map
%
% -------------------------------------------------------------------------
% Notes:
%
% -------------------------------------------------------------------------
function [ABL, ABL_raw] = extract_abl(edges_pp, th_ext_abl, w_ext_abl, perc_null_ABL_pxls)

% Preallocation
ABL_raw = zeros(size(edges_pp));

for ii = 1 : size(edges_pp, 2)
    
    v = edges_pp(:, ii);
    indv = find(v == 1);
    res = zeros(numel(v), 1);
    
    if ~isempty(indv)
    
        res(indv(1)) = 1; 
    
    end
    
    ABL_raw(:, ii) = res;

end

% Find heights

y = zeros(1, size(ABL_raw, 2));
for ii = 1 : size(ABL_raw, 2)
    
    v = ABL_raw(:, ii);
    indv = find(v == 1);
    
    if ~isempty(indv)
    
        y(ii) = indv(1);
    
    else
    
        y(ii) = -100;
    
    end
end

% Build final ABL
ABL = zeros(size(ABL_raw));

% Check variability on other points
for ii = 1 : numel(y) 
  
    xmin = ii - round(w_ext_abl / 2);
    xmax = ii + round(w_ext_abl / 2);
    
    if xmin < 1
    
        xmin = 1;
    
    end
    
    if xmax > numel(y)
    
        xmax = numel(y);
    
    end
    
    if numel(find(y(xmin : xmax) == -100)) > (perc_null_ABL_pxls * numel(y(xmin : xmax)))
    
        ABL(:, ii) = zeros(size(ABL, 1), 1);
    
    else
    
        ys = y(xmin : xmax);
        ys(abs(ys - median(ys(:))) > th_ext_abl) = [];

        if numel(ys) >= 3

            y(ii) = round(mean(ys(:))); 

        end
        
        if (y(ii) > 0) && (y(ii) <= size(ABL_raw, 1))
        
            ABL(y(ii),ii) = 1;
        
        end
    
    end

end

%---------
end