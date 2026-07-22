%oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
%  Crop the backscatter image (height-time) between start and stop heights 
% -------------------------------------------------------------------------
% 
% Inputs:  
%          img ------------------ [N_h_in, N_t] = Backscatter image
%          start --------------------- [scalar] = Start height [m]
%          stop ---------------------- [scalar] = Stop height [m]
%          spat_res ------------------ [scalar] = spatial resoution [m]
%
% -------------------------------------------------------------------------
% Outputs:
%          image_ir -------------- [N_h_out, N_t] = Cropped backscatter image 
%
% -------------------------------------------------------------------------
% Notes:
%
% -------------------------------------------------------------------------

function image_ir = crop_profile(img, start, stop, spat_res)

    if isempty(stop)
         image_ir = img(round(start./spat_res) + 1 :  end, :);
    else
        image_ir = img(round(start./spat_res) + 1 : round(stop./spat_res), :);
    end

end

