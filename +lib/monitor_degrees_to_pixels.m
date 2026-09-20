function posPix = monitor_degrees_to_pixels(posDeg, monitorSize, pixPerDeg)
%MONITOR_DEGREES_TO_PIXELS Convert a position in degrees to pixels (center is
% at 0,0).
%
% Example: 
%   posPix = MONITOR_DEGREES_TO_PIXELS(ImgStats)
%   
% Outout: 
%   posPix  Absolute position in pixels
%
% v1.0, 1/19/2016, Steve Sebastian <sebastian@utexas.edu>

%% 
% Point in the center is (0,0)
zeroPointPix = round(monitorSize./2);

posPixRelative = posDeg.*pixPerDeg;

posPix = zeroPointPix + posPixRelative;