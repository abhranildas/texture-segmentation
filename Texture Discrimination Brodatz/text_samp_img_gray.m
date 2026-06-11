%
% sample test patches from texture sheets and arrange in to image
%
close all; clearvars;
texnums = [2,7,11,24,31,33,37,42,52,55];
pimg = ones(350,350,3)*255;
sz = 640; psz = 64;
itype = 2;
for i = 1:10
  k = texnums(i);
  num = num2str(k);
  namein = append('B',num,'.gif');
  imgin = double(imread(namein));
  img = zeros(640,640,3);
  img(:,:,1) = imgin;
  img(:,:,2) = imgin;
  img(:,:,3) = imgin;
  % img = sqrt(255)*(img.^0.5);
  img = 255^(1/2.1)*lin2rgb(img,ColorSpace='adobe-rgb-1998');  
  x = randi(sz-psz);
  y = randi(sz-psz);
  if i <= 5
    xloc = (i-1)*70 + 1;
    yloc = 1;
    pimg(yloc:yloc+63,xloc:xloc+63,:) = img(x:x+psz-1,y:y+psz-1,:);
  else
    xloc = (i-6)*70 + 1;
    yloc = 71;
    pimg(yloc:yloc+63,xloc:xloc+63,:) = img(x:x+psz-1,y:y+psz-1,:);    
  end
end
image(pimg/255); axis('square');