%oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
%  Pre-processing 
% -------------------------------------------------------------------------
% 
% Inputs:  
%        im [N_h_in, N_t] = Degraded backscatter image 
%        flag_morph_grad [scalar] = Morphological gradient flag
%                                   0 : Identity
%                                   1 : Gradient  
%                                   2 : Half-Gradient
%        line_len [scalar] = Length of structuring element line
%        starting_angle_morph_grad [scalar] = Starting angle for SE rotation
%        stopping_angle_morph_grad [scalar] = Stopping angle for SE rotation
%
% -------------------------------------------------------------------------
% Outputs:
%        basic_gradient_C [N_h_out, N_t] = Pre-processed image
%
% -------------------------------------------------------------------------
% Notes:
% -------------------------------------------------------------------------
function basic_gradient_C = pre_processing(im,              ...
                                           flag_morph_grad,            ...
                                           line_len,                  ...
                                           starting_angle_morph_grad, ...
                                           stopping_angle_morph_grad)
                            
% Preallocation
basic_preprocessing_C = zeros(size(im));

% Morphological low-pass filter using a line SE in the horizontal direction
% ( 0 + starting_angle_morph_grad : 0 + stopping_angle_morph_grad) with a
% length line_len.

for ii = starting_angle_morph_grad : stopping_angle_morph_grad 
    
        se = strel('line', line_len, ii);
        basic_preprocessing = 0.5 .* (imdilate(im, se) + imerode(im, se));
        basic_preprocessing_C = max(basic_preprocessing_C, basic_preprocessing);
    
end

% Eventual Morphological Gradient in the orthogonal direction (vertical)
% ( 90 + starting_angle_morph_grad : 90 + stopping_angle_morph_grad)
%  
%  - flag_MorphGrad = 0: Identity
%  - flag_MorphGrad = 1: Gradient
%  - flag_MorphGrad = 2: Half-Gradient
%

if (flag_morph_grad == 1) || (flag_morph_grad == 2)
    
    basic_gradient_C = zeros(size(basic_preprocessing_C));
    
    for ii = starting_angle_morph_grad : stopping_angle_morph_grad 
    
        se = strel('line', line_len, 90 + ii);
    
        if flag_morph_grad == 1
    
            basic_gradient = imdilate(basic_preprocessing_C, se) - imerode(basic_preprocessing_C, se);
    
        elseif flag_morph_grad == 2
    
            basic_gradient = basic_preprocessing_C - imerode(basic_preprocessing_C, se); 
    
        end
    
            basic_gradient_C = max(basic_gradient_C, basic_gradient);
    
    end
    
else
    
        basic_gradient_C = basic_preprocessing_C;
    
end
    
% ---------
end