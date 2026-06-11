function dist = mk_dist(sz)
%
% Make distance matrix
%
dist = zeros(sz^2,sz^2);
for x1 = 1:sz
  for y1 = 1:sz
    for x2 = 1:sz
      for y2 = 1:sz
         i = (x1-1)*sz + y1;
         j = (x2-1)*sz + y2;
         dist(i,j) = sqrt((x1-x2)^2 + (y1-y2)^2);
      end
    end
  end
end
%
end