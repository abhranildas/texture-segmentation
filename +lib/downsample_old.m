function img_out = downsample(img_in,down_level,varargin)
%
% filter and downsample image

parser = inputParser;
parser.KeepUnmatched = true;
addRequired(parser,'img_in');
addRequired(parser,'down_level'); % lev = power of two of downsampling (0, 2, 4, 8, 16)
addParameter(parser,'ppd',60); % ppd = pixels per degree
addParameter(parser,'pd',4); % pd = pupil diameter (mm)
addParameter(parser,'w',550); % w = wavelength (nm)
addParameter(parser,'filter',0); % filter = 1 then apply optical filter
addParameter(parser,'ncolr',3); % number of color channels for histogram (use 3 even for grayscale)

parse(parser,img_in,down_level,varargin{:});
ppd=parser.Results.ppd;
pd=parser.Results.pd;
w=parser.Results.w;
filter=parser.Results.filter;
ncolr=parser.Results.ncolr;

% convert greyscale to rgb by replicating
if size(img_in,3)==1
    img=repmat(img_in,[1 1 3]);
end

img_out = img;
%
% apply 3 x 3 gaussian kernals and downsample
kern = [1/16 1/8 1/16; 1/8 1/4 1/8; 1/16 1/8 1/16];
if down_level >= 1 % no downsample
  if filter == 1
    if ncolr == 1
      img_out = aply_otf(img,ppd,pd,w); % apply otf
    else
      imin1 = img(:,:,1);
      imout1 = aply_otf(imin1,ppd,pd,w); % apply otf
      imin2 = img(:,:,2);
      imout2 = aply_otf(imin2,ppd,pd,w); % apply otf
      imin3 = img(:,:,3);
      imout3 = aply_otf(imin3,ppd,pd,w); % apply otf
      img_out(:,:,1) = imout1;
      img_out(:,:,2) = imout2;
      img_out(:,:,3) = imout3;
    end
  else
    img_out = img;
  end
end
%
if down_level >= 2 % factor of 2
  if ncolr == 1
    img_out = conv2(img_out,kern,'same');    
    img_out = imresize(img_out,0.5,'nearest');
  else
    imin1 = img_out(:,:,1);
    imout1 = conv2(imin1,kern,'same');
    imout1 = imresize(imout1,0.5,'nearest');
    imin2 = img_out(:,:,2);
    imout2 = conv2(imin2,kern,'same');
    imout2 = imresize(imout2,0.5,'nearest');
    imin3 = img_out(:,:,3);
    imout3 = conv2(imin3,kern,'same');
    imout3 = imresize(imout3,0.5,'nearest');
    img_out = imresize(img_out,0.5,'nearest');    
    img_out(:,:,1) = imout1;
    img_out(:,:,2) = imout2;
    img_out(:,:,3) = imout3;      
  end
end
%
if down_level >= 4 % factor of 4
  if ncolr == 1
    img_out = conv2(img_out,kern,'same');    
    img_out = imresize(img_out,0.5,'nearest');
  else
    imin1 = img_out(:,:,1);
    imout1 = conv2(imin1,kern,'same');
    imout1 = imresize(imout1,0.5,'nearest');
    imin2 = img_out(:,:,2);
    imout2 = conv2(imin2,kern,'same');
    imout2 = imresize(imout2,0.5,'nearest');
    imin3 = img_out(:,:,3);
    imout3 = conv2(imin3,kern,'same');
    imout3 = imresize(imout3,0.5,'nearest');
    img_out = imresize(img_out,0.5,'nearest');    
    img_out(:,:,1) = imout1;
    img_out(:,:,2) = imout2;
    img_out(:,:,3) = imout3;            
  end
end
%
if down_level >= 8 % factor of 8
  if ncolr == 1
    img_out = conv2(img_out,kern,'same');    
    img_out = imresize(img_out,0.5,'nearest');
  else
    imin1 = img_out(:,:,1);
    imout1 = conv2(imin1,kern,'same');
    imout1 = imresize(imout1,0.5,'nearest');
    imin2 = img_out(:,:,2);
    imout2 = conv2(imin2,kern,'same');
    imout2 = imresize(imout2,0.5,'nearest');
    imin3 = img_out(:,:,3);
    imout3 = conv2(imin3,kern,'same');
    imout3 = imresize(imout3,0.5,'nearest');
    img_out = imresize(img_out,0.5,'nearest');    
    img_out(:,:,1) = imout1;
    img_out(:,:,2) = imout2;
    img_out(:,:,3) = imout3;      
  end
end
%
if down_level >= 16 % factor of 16
  if ncolr == 1
    img_out = conv2(img_out,kern,'same');    
    img_out = imresize(img_out,0.5,'nearest');
  else
    imin1 = img_out(:,:,1);
    imout1 = conv2(imin1,kern,'same');
    imout1 = imresize(imout1,0.5,'nearest');
    imin2 = img_out(:,:,2);
    imout2 = conv2(imin2,kern,'same');
    imout2 = imresize(imout2,0.5,'nearest');
    imin3 = img_out(:,:,3);
    imout3 = conv2(imin3,kern,'same');
    imout3 = imresize(imout3,0.5,'nearest');
    img_out = imresize(img_out,0.5,'nearest');    
    img_out(:,:,1) = imout1;
    img_out(:,:,2) = imout2;
    img_out(:,:,3) = imout3;      
  end
end

% if imgin was greyscale, convert back to greyscale
if size(img_in,3)==1
    img_out=mean(img_out,3);
end