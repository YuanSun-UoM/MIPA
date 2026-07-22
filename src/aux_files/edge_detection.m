%oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
%  Edge detection 
% -------------------------------------------------------------------------
% Inputs:  
%         im_2analyze ------ [N_h, N_t] = Image to analyze
%         flag_edge_detector - [scalar] = flag for Edge Detection
%                                                1 : Canny
%                                                2 : Sobel  
%                                                3 : Prewitt
%                                                4 : WCT
%         spatial_res -------- [scalar] = degraded spatial resolution 
%                                         (only for WCT)
%
% -------------------------------------------------------------------------
% Outputs:
%          edges ----------- [N_h, N_t] = Edge map 
%
% -------------------------------------------------------------------------
% Notes:
% -------------------------------------------------------------------------
function edges = edge_detection(im_2analyze, flag_edge_detector, spatial_res)

% Edge detector selection -------------------------------------------------
if flag_edge_detector == 1

    edges = edge(im_2analyze, 'canny');

elseif flag_edge_detector == 2

    edges = edge(im_2analyze, 'sobel');    

elseif flag_edge_detector == 3
    
    edges = edge(im_2analyze, 'prewitt');   

elseif flag_edge_detector == 4
       
    edges = wct_detection(im_2analyze, spatial_res);
    
end

%---------
end


% Add. function (WCT)
function detections = wct_detection(image, sr)

    a = round(sr);
    a = a + mod(a, 2);% adapt for convolution

    harrconv = zeros(1, a + 1);
    harrconv(1 : round(a/2)) = -1;
    harrconv(round(a/2) + 1 : a + 1) = 1;
    
    c = zeros(size(image, 1), size(image, 2));
    for jj = 1 : size(image, 2)
        
        fz = image(:, jj);
        
        %%% Normalization
        max1000 = max(fz(1 : round(1000./sr)));
        fzn = fz./max1000;

        %%%% Implementation: convolution
        h = 1/a .* conv(fzn, harrconv);
        c(:, jj) = h(round(numel(harrconv)/2) : (end - round(numel(harrconv)/2) + 1));
   
    end    

    detections = zeros(size(c));
    cth = 0.05;
    detections(c >= cth) = 1;

end
