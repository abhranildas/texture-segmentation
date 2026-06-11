%
% find texture regions
%
clearvars; close all;
pw = 64;        % patch width (pixels)
np = 16;        % number of patches per row and per column (pixels)
imw = pw*np;    % image width (pixels)
npt = np^2;     % total number of patches
%
% load patch locations
xp = zeros(npt,1); yp = zeros(npt,1);
cpt = 0;
for j = 1:np
  for i = 1:np
    cpt = cpt + 1;  
    xp(cpt) = j; yp(cpt) = i;
  end
end
%
% initialize patch pair array
npp = npt*(npt-1)/2;
pp = zeros(npp,5); % patch pair array
%
% load patch pair indices and distances
cpp = 0; % initialize patch pair counter
for j = 1:npt
  for i = j+1:npt
    cpp = cpp+1;
    pp(cpp,1) = j; pp(cpp,2) = i; % patch numbers
    pp(cpp,3) = sqrt((xp(j)-xp(i))^2 + (yp(j)-yp(i))^2); % distances
  end
end
