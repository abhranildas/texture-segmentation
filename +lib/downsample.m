function img=downsample(img_in,down_level,varargin)
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

img=img_in;
kern = [1/16 1/8 1/16; 1/8 1/4 1/8; 1/16 1/8 1/16]; % small gaussian blurring kernel

for iter=1:log2(down_level)
    img=conv2(img,kern,'same');
    img=imresize(img,1/2,'nearest');
    % img=uint8(imresize(img,2,'nearest'));
end