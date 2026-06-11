%
% convert 16 bit ppm camera RGB images to RGB png images
%
% Designed for use with the CPS natural image database
% The numbering convention here for the twelve data sets
% is from Set 1 to Set 12; whereas on the website there is Set 1 to Set 9
% and then three sets that are labelled Set 1; here these last three are
% 10, 11 and 12.
%
clearvars; close all;
%
% parameters
bits = 8; % 8 bit or 16 bit
space = 1; % 1 = sRGB, 2 = linear RGB
%
% set matrix for converting camera RGB to XYZ
f = 10; T = 1/400; 
xyz = [6.155,1.376,.9558;3.174,7.723,-1.152;0.1819,-1.3,9.951]; % rgb to xyz
xyzs = 10^-9*683*f^2/T;
xyz = xyz*xyzs;
%
% read in an image
imagefiles = dir('*.ppm');      
nfiles = length(imagefiles);    % Number of files found
for k=1:nfiles
  currentfilename = imagefiles(k).name;
  img = imread(currentfilename);
  %
  % distribution of R, G and B values
  cntR = zeros(2^16,1);
  cntG = zeros(2^16,1);
  cntB = zeros(2^16,1);
  sz = size(img);
  npix = sz(1)*sz(2); % number of pixels in the image
  cutoff = 0.99*npix;
  for i = 1:sz(1)
    for j = 1:sz(2)
      R = img(i,j,1);
      G = img(i,j,2);
      B = img(i,j,3);
      cntR(R+1) = cntR(R+1) + 1;
      cntG(G+1) = cntG(G+1) + 1;
      cntB(B+1) = cntB(B+1) + 1;
    end
  end
  % find rmx
  Rmx = 0; cnt = 0;
  while cnt <= cutoff
    Rmx = Rmx + 1;
    cnt = cnt + cntR(Rmx);
  end
  % find gmx
  Gmx = 0; cnt = 0;
  while cnt <= cutoff
    Gmx = Gmx + 1;
    cnt = cnt + cntG(Gmx);
  end
  % find bmx
  Bmx = 0; cnt = 0;
  while cnt <= cutoff
    Bmx = Bmx + 1;
    cnt = cnt + cntB(Bmx);
  end
  %
  % clip image values to max values
  img(:,:,1) = min(img(:,:,1),Rmx);
  img(:,:,2) = min(img(:,:,2),Gmx);
  img(:,:,3) = min(img(:,:,3),Bmx);
  Vmx = max([Rmx;Gmx;Bmx]);
  dimg = double(img)/Vmx; % convert to double and scale
  %
  % covert to XYZ space
  rgbv = double(zeros(3,1));
  imgxyz = zeros(sz(1),sz(2),3);
  for i = 1:sz(1)
    for j = 1:sz(2)
      rgbv(1) = dimg(i,j,1);
      rgbv(2) = dimg(i,j,2);
      rgbv(3) = dimg(i,j,3);
      imgxyz(i,j,:) = xyz*rgbv;
    end
  end
  %
  % convert to rgb
  if bits == 8
    if space == 1
      imgrgb = xyz2rgb(imgxyz,'OutputType','uint8',...
          ColorSpace = 'adobe-rgb-1998');
    elseif space == 2
      imgrgb = xyz2rgb(imgxyz,'OutputType','uint8',...
          ColorSpace = "linear-rgb");      
    end
  elseif bits == 16
    if space == 1
      imgrgb = xyz2rgb(imgxyz,'OutputType','uint16',...
          ColorSpace = 'adobe-rgb-1998');
    elseif space == 2
      imgrgb = xyz2rgb(imgxyz,'OutputType','uint16',...
          ColorSpace = "linear-rgb");      
    end      
  end
  num = num2str(k);
  name = append('Set10_8_',num,'.png');
  imwrite(imgrgb,name);
end
%
% convert to lab space for computing color distance
% imglab = rgb2lab(imgrgb,'WhitePoint','d65');






