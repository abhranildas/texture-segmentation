function imgout = mk_gRGB(imgin,itype)
%
% converts input double precision image into gray-scale 
% double precision sRGB image
%
% imgin = double precision image
% imtype: 1 = linear RGB, 2 = RGB, 3 = linear luminance (gray scale)
%
if itype == 1
  img = imgin;
  gimg = (img(:,:,1) + img(:,:,2) + img(:,:,3))/3;
  img(:,:,1) = gimg;
  img(:,:,2) = gimg;
  img(:,:,3) = gimg;
  imgout = img;  
elseif itype == 2
  img = rgb2lin(imgin,ColorSpace='adobe-rgb-1998');
  gimg = (img(:,:,1) + img(:,:,2) + img(:,:,3))/3;
  img(:,:,1) = gimg;
  img(:,:,2) = gimg;
  img(:,:,3) = gimg;
  imgout = img;
elseif itype == 3
  n = size(imgin);
  img = zeros(n(1),n(2),3);
  img(:,:,1) = imgin;
  img(:,:,2) = imgin;
  img(:,:,3) = imgin;
  imgout = img;
end    
end