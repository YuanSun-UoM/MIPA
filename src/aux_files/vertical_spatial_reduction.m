%oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
%  Vertical Spatial resolution reduction 
% -------------------------------------------------------------------------
% 
% Inputs:  
%        image_IRN ------------ [N_h, N_t] = Backscatter Image 
%              srf -------------- [scalar] = Spatial reduction factor (<=1)
%      mov_avg_tag -------------- [string] = Moving-average filter 
%                                            ('box', 'triangle', 'cubic')
%
% -------------------------------------------------------------------------
% Outputs:
%         image_IRN ----- [N_h_out, N_t] = Column-filtered and 
%                                              downsampled Backscatter Image 
%
% -------------------------------------------------------------------------
% Notes:
%
% -------------------------------------------------------------------------
function image_IRN = vertical_spatial_reduction(image_IRN, srf, mov_avg_tag)

% Preallocation
[~, N_t] = size(image_IRN);
Hm = [];

% Moving - average filter with downsampling 

for ii = 1 : N_t
    
    Hm = cat(2, Hm, imresize(image_IRN(:, ii), srf, mov_avg_tag));

end

% Output image
image_IRN = Hm;

end