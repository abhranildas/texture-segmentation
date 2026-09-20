function filt = steerable_filter(kernel_size)
% STEERABLE_FILTER  Build a pair of first-derivative-of-Gaussian kernels.
%   filt = lib.steerable_filter(kernel_size)
%
%   The two kernels are the x- and y-derivatives of an isotropic Gaussian,
%   zeroed outside a disk of radius kernel_sd*kernel_nsd. Filtering an image
%   with both gives the steerable gradient at that scale.
%
%   Inputs
%     kernel_size - two-element vector [kernel_sd kernel_nsd]:
%                     kernel_sd  - Gaussian standard deviation, in pixels.
%                     kernel_nsd - truncation radius as a count of standard
%                                  deviations (dimensionless).
%
%   Output
%     filt - filter_width-by-filter_width-by-2 array of kernel weights, where
%            filter_width = 2*ceil(kernel_sd*kernel_nsd) + 1 pixels;
%            filt(:,:,1) is the x-derivative kernel, filt(:,:,2) the
%            y-derivative one. The kernels are antisymmetric, so each sums to
%            zero. Units are 1/pixel, since these are spatial derivatives.
%
%   See also LIB.STEERABLE_GRAD, LIB.LOCAL_SD.

    % kernel_sd: gaussian kernel sd
    kernel_sd = kernel_size(1);
    % kernel_nsd: number of kernel SDs for truncation
    kernel_nsd = kernel_size(2);

    filter_radius = kernel_nsd*kernel_sd;
    filter_width = 2*ceil(filter_radius) + 1;
    filt = zeros(filter_width, filter_width, 2);
    filter_center = (floor(filter_width/2) + 1)*[1 1];
    for i_row = 1:filter_width
        for i_col = 1:filter_width
            if norm([i_row, i_col] - filter_center) <= filter_radius
                filt(i_row, i_col, 1) = (i_col - filter_center(2))/kernel_sd^2*...
                    exp(-(norm([i_row, i_col] - filter_center)/kernel_sd)^2/2);
                filt(i_row, i_col, 2) = (filter_center(1) - i_row)/kernel_sd^2*...
                    exp(-(norm([i_row, i_col] - filter_center)/kernel_sd)^2/2);
            end
        end
    end

    % normalize by their L2 norm (so that larger filter responses aren't bigger
    % simply due to size
    % filt_1=filt(:,:,1); filt_1=filt_1(:);
    % filt=filt/norm(filt_1(:));

    % display filter
    % img = filt(:,:,2)- min(min(filt(:,:,2)));
    % img = sqrt(img);                           % gamma correct for display
    % img = 256*img/max(max(img));               % scale to max of 256
    % figure; colormap(gray(256));image(img);axis image;
end
