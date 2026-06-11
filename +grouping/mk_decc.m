function decc = mk_decc(sz)
%
% Make minimum eccentricity matrix
%
decc = zeros(sz^2,sz^2);
for x1 = 1:sz
  for y1 = 1:sz
    for x2 = 1:sz
      for y2 = 1:sz
         i = (x1-1)*sz + y1;
         j = (x2-1)*sz + y2;
         ecc1 = sqrt((x1-sz/2)^2 + (y1-sz/2)^2);
         ecc2 = sqrt((x2-sz/2)^2 + (y2-sz/2)^2);
         decc(i,j) = abs(ecc1-ecc2);
      end
    end
  end
end
%
end