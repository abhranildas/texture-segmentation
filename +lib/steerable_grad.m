function grad = steerable_grad(stim, varargin)
% STEERABLE_GRAD  Image gradient from a pair of steerable filters.
%   grad = lib.steerable_grad(stim, ...)
%
%   Filters the image with LIB.STEERABLE_FILTER's x- and y-derivative kernels
%   and, optionally, divides the result by the local standard deviation
%   (LIB.LOCAL_SD) so the gradient is normalized for local luminance and
%   contrast.
%
%   Inputs
%     stim - input image, in gray levels (n_rows-by-n_cols).
%
%   Name-value inputs
%     'kernel_size'   - two-element vector [kernel_sd kernel_nsd] passed to
%                       LIB.STEERABLE_FILTER: Gaussian standard deviation in
%                       pixels, and truncation radius as a count of standard
%                       deviations. Ignored if 'filter_kernel' is supplied.
%     'filter_kernel' - a prebuilt kernel pair from LIB.STEERABLE_FILTER, to
%                       avoid rebuilding it on every call (default [], meaning
%                       build it here).
%     'pad_val'       - gray level to pad the image with, so the gradient is
%                       defined at the border (default NaN, meaning do not
%                       pad and leave the border NaN).
%     'normalize'     - false to skip normalization; true to divide by the
%                       local standard deviation; or a numeric k to divide by
%                       sqrt(sd^2 + k) (default 2e-4, the smallest offset
%                       that removes division artifacts). In the same
%                       squared gray levels as sd^2.
%
%   Output
%     grad - n_rows-by-n_cols-by-2 gradient array; grad(:,:,1) is the
%            x-component and grad(:,:,2) the y-component, in gray levels per
%            pixel (dimensionless if normalized). Pixels within half a kernel
%            width of the border are NaN when 'pad_val' is NaN.
%
%   See also LIB.STEERABLE_FILTER, LIB.LOCAL_SD, LIB.EDGE_PROPS_STIM.

    parser = inputParser;
    parser.KeepUnmatched = true;
    addRequired(parser, 'stim');
    addParameter(parser, 'kernel_size', [], @isnumeric);
    addParameter(parser, 'filter_kernel', [], @isnumeric);
    addParameter(parser, 'pad_val', nan, @isscalar);
    addParameter(parser, 'normalize', 2e-4);  % smallest offset to remove artifacts
    % if normalize = false, don't normalize
    % if = true, normalize by sd
    % if = k (numeric value), normalize by sqrt(sd^2+k)

    % parse inputs
    parse(parser, stim, varargin{:});
    stim = parser.Results.stim;
    kernel_size = parser.Results.kernel_size;
    filter_kernel = parser.Results.filter_kernel;
    pad_val = parser.Results.pad_val;
    normalize = parser.Results.normalize;

    if isempty(filter_kernel)
        filter_kernel = lib.steerable_filter(kernel_size);
    end

    % assume stim is n_rows x n_cols, filter_kernel is filt_rows x filt_cols
    [n_rows, n_cols] = size(stim);
    [filt_rows, filt_cols, ~] = size(filter_kernel);

    grad = nan(n_rows, n_cols, 2);

    if isnan(pad_val)
        % get the valid output
        valid_1 = filter2(filter_kernel(:,:,1), stim, 'valid');
        valid_2 = filter2(filter_kernel(:,:,2), stim, 'valid');

        % locate where to paste it
        row_first = ceil(filt_rows/2);        % first row index in grad
        row_last = n_rows - floor(filt_rows/2);  % last row index in grad
        col_first = ceil(filt_cols/2);        % first col index in grad
        col_last = n_cols - floor(filt_cols/2);  % last col index in grad

        grad(row_first:row_last, col_first:col_last, 1) = valid_1;
        grad(row_first:row_last, col_first:col_last, 2) = valid_2;

        % leave out the edges of the image
        % padsize=kernel_size(1)*kernel_size(2);
        % grad(padsize+1:end-padsize,padsize+1:end-padsize,1)=filter2(filter_kernel(:,:,1),stim,'valid');
        % grad(padsize+1:end-padsize,padsize+1:end-padsize,2)=filter2(filter_kernel(:,:,2),stim,'valid');
    else
        % pad the image
        pad_len = floor(size(filter_kernel, 1)/2);
        stim_padded = padarray(stim, [pad_len, pad_len], pad_val, 'both');

        % filter and keep valid region
        grad(:,:,1) = filter2(filter_kernel(:,:,1), stim_padded, 'valid');
        grad(:,:,2) = filter2(filter_kernel(:,:,2), stim_padded, 'valid');
    end

    % normalize by local luminance and contrast, i.e. by local std
    if normalize
        stim_sd = lib.local_sd(stim, kernel_size, varargin{:});
        % stim_sd=std(stim(:));
        if normalize == true
            grad = grad./stim_sd;
            grad(isnan(grad)) = 0;  % change 0/0 to 0
        else
            grad = grad./sqrt(stim_sd.^2 + normalize);
        end
    end
end
