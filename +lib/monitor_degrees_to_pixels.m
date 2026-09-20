function pos_pix = monitor_degrees_to_pixels(pos_deg, monitor_size, pix_per_deg)
% MONITOR_DEGREES_TO_PIXELS  Convert a screen position from degrees to pixels.
%   pos_pix = lib.monitor_degrees_to_pixels(pos_deg, monitor_size, pix_per_deg)
%
%   The origin of the degree coordinate system is the center of the monitor,
%   so (0, 0) deg maps to the middle pixel.
%
%   Inputs
%     pos_deg      - position relative to screen center, in degrees of visual
%                    angle; [x y] or an array of such.
%     monitor_size - monitor size in pixels, [width height].
%     pix_per_deg  - pixels per degree of visual angle.
%
%   Output
%     pos_pix - absolute position in pixels, measured from the screen's own
%               origin, same size as pos_deg.
%
%   See also LIB.GAMMA_CORRECT.
%
%   v1.0, 1/19/2016, Steve Sebastian <sebastian@utexas.edu>

    % Point in the center is (0,0)
    zero_point_pix = round(monitor_size./2);

    pos_pix_relative = pos_deg.*pix_per_deg;

    pos_pix = zero_point_pix + pos_pix_relative;
end
