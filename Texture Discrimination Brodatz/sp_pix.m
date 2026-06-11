function sp = sp_pix(i,j,fy,fx,scl,ppd)
%
% returns the ganglion cell spacing in pixels given
% fixation at location fx,fy.  Uses the average spacing function of human
% midget ganglion cells.
%
% i,j = image location in pixels
% fy,fx = fixation location in pixels
% scl = scale factor to change magnification
% ppd = image pixels per degree (e.g., 30, 60 or 120)
%
% sp = output spacing in units of display pixels
%
es = scl*1.13*ppd; ei = scl*1.49*ppd;   % constants from Curio data in pixels
en = scl*1.63*ppd; et = scl*1.67*ppd;
s0 = ppd/120;                   % spacing in center of fovea in pixels
x0 = j-fx; y0 = i-fy;
%
if x0 == 0 && y0 == 0
  sp = s0;
elseif x0 >= 0 && y0 >= 0
  sp = s0*(sqrt(x0^2/et^2 + y0^2/es^2) + 1);
elseif x0 < 0 && y0 >= 0
  sp = s0*(sqrt(x0^2/en^2 + y0^2/es^2) + 1);
elseif x0 >= 0 && y0 < 0
  sp = s0*(sqrt(x0^2/et^2 + y0^2/ei^2) + 1);
elseif x0 < 0 && y0 < 0
  sp = s0*(sqrt(x0^2/en^2 + y0^2/ei^2) + 1);
end
%
end

