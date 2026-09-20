function stim_sd = local_sd(stim, kernel_size, varargin)
% LOCAL_SD  Local standard deviation of an image over a disk neighborhood.
%   stim_sd = lib.local_sd(stim, kernel_size, ...)
%
%   A measure of local luminance times contrast, used by LIB.STEERABLE_GRAD to
%   normalize its gradients. The neighborhood is the same disk that
%   LIB.STEERABLE_FILTER truncates its kernels to, so the two are computed
%   over matching supports.
%
%   Inputs
%     stim        - input image, in gray levels (any size).
%     kernel_size - two-element vector [kernel_sd kernel_nsd], as for
%                   LIB.STEERABLE_FILTER: Gaussian standard deviation in
%                   pixels, and truncation radius as a count of standard
%                   deviations. Their product is the disk radius in pixels.
%
%   Name-value inputs
%     'pad_val' - gray level to pad the image with before filtering, so the
%                 output is defined at the border (default NaN, meaning do not
%                 pad, and let stdfilt use its own edge handling).
%
%   Output
%     stim_sd - local standard deviation at each pixel, same size as stim, in
%               the same gray levels.
%
%   See also LIB.STEERABLE_GRAD, LIB.STEERABLE_FILTER.

    parser = inputParser;
    parser.KeepUnmatched = true;
    addRequired(parser, 'stim');
    addParameter(parser, 'pad_val', nan, @isscalar);

    % parse inputs
    parse(parser, stim, varargin{:});
    pad_val = parser.Results.pad_val;

    % define local patch neighbourhood
    filter_radius = kernel_size(1)*kernel_size(2);
    filter_size = 2*ceil(filter_radius) + 1;
    nhood = false(filter_size);
    nhood_center = (floor(filter_size/2) + 1)*[1 1];
    for i_row = 1:filter_size
        for i_col = 1:filter_size
            if norm([i_row, i_col] - nhood_center) <= filter_radius
                nhood(i_row, i_col) = true;
            end
        end
    end

    if isnan(pad_val)
        stim_sd = stdfilt(stim, nhood);
    else
        % pad the image
        pad_len = floor(filter_size/2);
        stim_padded = padarray(stim, [pad_len, pad_len], pad_val, 'both');

        % filter and keep valid region
        stim_sd_padded = stdfilt(stim_padded, nhood);
        stim_sd = stim_sd_padded(pad_len+1:end-pad_len, pad_len+1:end-pad_len);
    end
end
