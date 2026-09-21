function img = downsample(img_in, down_level, varargin)
% DOWNSAMPLE  Blur and downsample an image by successive factors of two.
%   img = lib.downsample(img_in, down_level, ...)
%
%   Applies a 3x3 Gaussian blur and a nearest-neighbour halving,
%   log2(down_level) times.
%
%   Note: this shadows the Signal Processing Toolbox's DOWNSAMPLE. Whether to
%   drop it in favour of vislab.lib.downsample is a Stage 3 question.
%
%   Inputs
%     img_in     - input image, any size, in whatever intensity units the
%                  caller uses (pixels).
%     down_level - downsampling factor, a power of two (1, 2, 4, 8, 16);
%                  an integer divisor, not degrees.
%
%   Name-value inputs (all parsed but unused by this function; they exist so
%   the call signature matches LIB.DOWNSAMPLE_OLD, which does use them)
%     'ppd'    - pixels per degree (default 60).
%     'pd'     - pupil diameter in mm (default 4).
%     'w'      - wavelength in nm (default 550).
%     'filter' - 1 to apply the optical filter (default 0).
%     'ncolr'  - number of color channels for the histogram, use 3 even for
%                grayscale (default 3).
%
%   Output
%     img - the downsampled image, size(img_in) / down_level in pixels along
%           each dimension.
%
%   See also LIB.DOWNSAMPLE_OLD.

    parser = inputParser;
    parser.KeepUnmatched = true;
    addRequired(parser, 'img_in');
    addRequired(parser, 'down_level');  % lev = power of two of downsampling (0, 2, 4, 8, 16)
    addParameter(parser, 'ppd', 60);  % ppd = pixels per degree
    addParameter(parser, 'pd', 4);  % pd = pupil diameter (mm)
    addParameter(parser, 'w', 550);  % w = wavelength (nm)
    addParameter(parser, 'filter', 0);  % filter = 1 then apply optical filter
    addParameter(parser, 'ncolr', 3);  % color channels (use 3 even for grayscale)

    parse(parser, img_in, down_level, varargin{:});

    img = img_in;
    kernel = [1/16 1/8 1/16; 1/8 1/4 1/8; 1/16 1/8 1/16];  % small gaussian blurring kernel

    for i_level = 1:log2(down_level)
        img = conv2(img, kernel, 'same');
        img = imresize(img, 1/2, 'nearest');
        % img = uint8(imresize(img, 2, 'nearest'));
    end
end
