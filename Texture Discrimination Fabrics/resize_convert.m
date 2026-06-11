close all;
clearvars;
nmin = 1;
nmax = 60;
for i = nmin:nmax
  num = num2str(i);
  namein = append('F',num,'.png');
  img = imread(namein);
  img = imresize(img,[640 640],"bilinear");
  nameout = append('FC',num,'.png');
  imwrite(img,nameout);
  r = double(img(:,:,1));
  g = double(img(:,:,2));
  b = double(img(:,:,3));
  aveimg = (r+g+b)/3;
  gimg = uint8(aveimg);
  nameout = append('FG',num,'.png');
  imwrite(gimg,nameout);
  % figure; colormap(gray(256)); image(gimg); axis image;
end
