function img_out = downsample_old(img_in, down_level, varargin)
% DOWNSAMPLE_OLD  Optically filter and downsample an image, channel by channel.
%   img_out = lib.downsample_old(img_in, down_level, ...)
%
%   The earlier, explicit version of LIB.DOWNSAMPLE: it unrolls one block per
%   downsampling factor and handles the three color channels separately, and
%   it can apply the eye's optical transfer function first. Nothing in this
%   repo calls it. Note that the optical-filter branch calls APLY_OTF, which
%   does not exist anywhere in this repo; and the RGB input path leaves img
%   unassigned. Both are recorded as bugs, not fixed here.
%
%   Inputs
%     img_in     - input image, grayscale or RGB, in whatever intensity units
%                  the caller uses (pixels).
%     down_level - downsampling factor: 1, 2, 4, 8 or 16. An integer divisor,
%                  not degrees.
%
%   Name-value inputs
%     'ppd'    - pixels per degree (default 60).
%     'pd'     - pupil diameter in mm (default 4).
%     'w'      - wavelength in nm (default 550).
%     'filter' - 1 to apply the optical transfer function before downsampling
%                (default 0).
%     'ncolr'  - number of color channels to process, use 3 even for
%                grayscale (default 3).
%
%   Output
%     img_out - the downsampled image, size(img_in) / down_level in pixels
%               along each dimension. Grayscale in, grayscale out: an RGB
%               intermediate is averaged back down to one channel at the end.
%
%   See also LIB.DOWNSAMPLE.

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
    ppd = parser.Results.ppd;
    pd = parser.Results.pd;
    w = parser.Results.w;
    apply_filter = parser.Results.filter;
    ncolr = parser.Results.ncolr;

    % convert greyscale to rgb by replicating
    if size(img_in, 3) == 1
        img = repmat(img_in, [1 1 3]);
    end

    img_out = img;

    % apply 3 x 3 gaussian kernels and downsample
    kernel = [1/16 1/8 1/16; 1/8 1/4 1/8; 1/16 1/8 1/16];
    if down_level >= 1  % no downsample
        if apply_filter == 1
            if ncolr == 1
                img_out = aply_otf(img, ppd, pd, w);  % apply otf
            else
                chan_in_1 = img(:,:,1);
                chan_out_1 = aply_otf(chan_in_1, ppd, pd, w);  % apply otf
                chan_in_2 = img(:,:,2);
                chan_out_2 = aply_otf(chan_in_2, ppd, pd, w);  % apply otf
                chan_in_3 = img(:,:,3);
                chan_out_3 = aply_otf(chan_in_3, ppd, pd, w);  % apply otf
                img_out(:,:,1) = chan_out_1;
                img_out(:,:,2) = chan_out_2;
                img_out(:,:,3) = chan_out_3;
            end
        else
            img_out = img;
        end
    end

    if down_level >= 2  % factor of 2
        if ncolr == 1
            img_out = conv2(img_out, kernel, 'same');
            img_out = imresize(img_out, 0.5, 'nearest');
        else
            chan_in_1 = img_out(:,:,1);
            chan_out_1 = conv2(chan_in_1, kernel, 'same');
            chan_out_1 = imresize(chan_out_1, 0.5, 'nearest');
            chan_in_2 = img_out(:,:,2);
            chan_out_2 = conv2(chan_in_2, kernel, 'same');
            chan_out_2 = imresize(chan_out_2, 0.5, 'nearest');
            chan_in_3 = img_out(:,:,3);
            chan_out_3 = conv2(chan_in_3, kernel, 'same');
            chan_out_3 = imresize(chan_out_3, 0.5, 'nearest');
            img_out = imresize(img_out, 0.5, 'nearest');
            img_out(:,:,1) = chan_out_1;
            img_out(:,:,2) = chan_out_2;
            img_out(:,:,3) = chan_out_3;
        end
    end

    if down_level >= 4  % factor of 4
        if ncolr == 1
            img_out = conv2(img_out, kernel, 'same');
            img_out = imresize(img_out, 0.5, 'nearest');
        else
            chan_in_1 = img_out(:,:,1);
            chan_out_1 = conv2(chan_in_1, kernel, 'same');
            chan_out_1 = imresize(chan_out_1, 0.5, 'nearest');
            chan_in_2 = img_out(:,:,2);
            chan_out_2 = conv2(chan_in_2, kernel, 'same');
            chan_out_2 = imresize(chan_out_2, 0.5, 'nearest');
            chan_in_3 = img_out(:,:,3);
            chan_out_3 = conv2(chan_in_3, kernel, 'same');
            chan_out_3 = imresize(chan_out_3, 0.5, 'nearest');
            img_out = imresize(img_out, 0.5, 'nearest');
            img_out(:,:,1) = chan_out_1;
            img_out(:,:,2) = chan_out_2;
            img_out(:,:,3) = chan_out_3;
        end
    end

    if down_level >= 8  % factor of 8
        if ncolr == 1
            img_out = conv2(img_out, kernel, 'same');
            img_out = imresize(img_out, 0.5, 'nearest');
        else
            chan_in_1 = img_out(:,:,1);
            chan_out_1 = conv2(chan_in_1, kernel, 'same');
            chan_out_1 = imresize(chan_out_1, 0.5, 'nearest');
            chan_in_2 = img_out(:,:,2);
            chan_out_2 = conv2(chan_in_2, kernel, 'same');
            chan_out_2 = imresize(chan_out_2, 0.5, 'nearest');
            chan_in_3 = img_out(:,:,3);
            chan_out_3 = conv2(chan_in_3, kernel, 'same');
            chan_out_3 = imresize(chan_out_3, 0.5, 'nearest');
            img_out = imresize(img_out, 0.5, 'nearest');
            img_out(:,:,1) = chan_out_1;
            img_out(:,:,2) = chan_out_2;
            img_out(:,:,3) = chan_out_3;
        end
    end

    if down_level >= 16  % factor of 16
        if ncolr == 1
            img_out = conv2(img_out, kernel, 'same');
            img_out = imresize(img_out, 0.5, 'nearest');
        else
            chan_in_1 = img_out(:,:,1);
            chan_out_1 = conv2(chan_in_1, kernel, 'same');
            chan_out_1 = imresize(chan_out_1, 0.5, 'nearest');
            chan_in_2 = img_out(:,:,2);
            chan_out_2 = conv2(chan_in_2, kernel, 'same');
            chan_out_2 = imresize(chan_out_2, 0.5, 'nearest');
            chan_in_3 = img_out(:,:,3);
            chan_out_3 = conv2(chan_in_3, kernel, 'same');
            chan_out_3 = imresize(chan_out_3, 0.5, 'nearest');
            img_out = imresize(img_out, 0.5, 'nearest');
            img_out(:,:,1) = chan_out_1;
            img_out(:,:,2) = chan_out_2;
            img_out(:,:,3) = chan_out_3;
        end
    end

    % if img_in was greyscale, convert back to greyscale
    if size(img_in, 3) == 1
        img_out = mean(img_out, 3);
    end
end
