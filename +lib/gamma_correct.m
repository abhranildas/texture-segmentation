function img_out = gamma_correct(img_in, gamma_value, bit_depth_out)
% GAMMA_CORRECT  Gamma-compress an image and scale it to integer pixel values.
%   img_out = lib.gamma_correct(img_in, gamma_value, bit_depth_out)
%
%   Raises the image to the power 1/gamma_value, then scales to the full range
%   of an unsigned integer of the given bit depth, so that the monitor's own
%   gamma expansion reproduces the requested luminances.
%
%   Inputs
%     img_in        - image in normalized luminance units, 0 (black) to 1
%                     (white), any size.
%     gamma_value   - the monitor's gamma exponent, dimensionless (2.089 for
%                     the lab monitor, per LOAD_CURRENT_SESSION).
%     bit_depth_out - bit depth of the output, a count of bits (8 for the lab
%                     monitor).
%
%   Output
%     img_out - gamma-compressed image, same size as img_in, rounded to
%               integer pixel values in [0, 2^bit_depth_out - 1]. Returned as
%               double; callers cast it to uint8 themselves.
%
%   See also LIB.MONITOR_DEGREES_TO_PIXELS.
%
%   v1.0, 2/24/2016, Steve Sebastian <sebastian@utexas.edu>

    max_pixel_val_out = 2^bit_depth_out - 1;

    %% Gamma correct
    img_out = img_in.^(1/gamma_value);
    img_out = max_pixel_val_out*img_out;
    img_out = round(img_out);
end
