%
% Contour blur estimation
%
close all;
sz = 64; sz2 = sz/2;
img = zeros(sz,sz);
r1 = 64;
dr = 10;
r2 = r1+dr;
for i = 1:sz
  for j = 1:sz
    x = j + r1 - sz2;
    y = i - sz2;
    r = sqrt(x^2+y^2);
    if (r >= r1) && (r < r2)
      img(i,j) = 255;
    end
  end
end
figure; colormap(gray(256)); image(img); axis image;
