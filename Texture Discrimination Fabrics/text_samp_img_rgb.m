%
% sample test patches from texture sheets and arrange in to image
%
close all; clearvars;
texnums = [3,4,14,22,25,32,38,45,56,58];
pimg = ones(350,350,3)*255;
sz = 640; psz = 64;
itype = 2;
for i = 1:10
  k = texnums(i);
  num = num2str(k);
  namein = append('FC',num,'.png');
  img = double(imread(namein));
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