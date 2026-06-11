function [cue,cuemap] = shape_cue(map,sz,regn)
%
% make shape cue for a given region number
%
bkgl = 128;
trgl = 112;
imin = 0;
for i = 1:sz
  for j = 1:sz
    if map(i,j) == regn && imin == 0
      imin = i;
    end
  end
end
imax = 0;
for i = sz:-1:1
  for j = 1:sz
    if map(i,j) == regn && imax == 0
      imax = i;
    end
  end
end
jmin = 0;
for i = 1:sz
  for j = 1:sz
    if map(j,i) == regn && jmin == 0
      jmin = i;
    end
  end
end
jmax = 0;
for i = sz:-1:1
  for j = 1:sz
    if map(j,i) == regn && jmax == 0
      jmax = i;
    end
  end
end
%
tmp = map(imin:imax,jmin:jmax);
szcue = size(tmp);
for i = 1:szcue(1)
  for j = 1:szcue(2)
    if tmp(i,j) ~= regn
      tmp(i,j) = bkgl;
    else
      tmp(i,j) = trgl;
    end
  end
end
dx = floor((sz-szcue(1))/2);
dy = floor((sz-szcue(2))/2);
cue = ones(sz,sz,3)*128;
cue(dx+1:dx+szcue(1),dy+1:dy+szcue(2),1) = tmp;
cue(dx+1:dx+szcue(1),dy+1:dy+szcue(2),2) = tmp;
cue(dx+1:dx+szcue(1),dy+1:dy+szcue(2),3) = tmp;
%
cuemap = ones(sz,sz);
for i=1:sz
  for j=1:sz
    if map(i,j) == regn
      cuemap(i,j) = 0;
    end
  end
end
% figure;
% image(cue/255); axis('square');
%
end