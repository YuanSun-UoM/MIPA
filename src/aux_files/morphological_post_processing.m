%oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
%  Morphological Post-processing
% -------------------------------------------------------------------------
% 
% Inputs:  
%          edges ------- [N_h, N_t] = Binary edge image 
%          line_pp ------- [scalar] = Length of SE line
%          max_angle_pp -- [scalar] = Maximum angle for line rotation
%
% -------------------------------------------------------------------------
% Outputs:
%          edges_pp --- [N_h, N_tl] = Post-processed edge image
%
% -------------------------------------------------------------------------
% Notes:        
%
% -------------------------------------------------------------------------
function edges_pp = morphological_post_processing(edges, line_pp, max_angle_pp)

edges_pp = zeros(size(edges));

for ii = - max_angle_pp : 2 : max_angle_pp
    
    se = strel('line', line_pp, ii);
    
    % Opening 
    im_op = imopen(edges, se);

    % Closening    
    im_cl = imclose(im_op,se);

    % Max
    edges_pp = max(edges_pp, im_cl);

end

%-----------
end