function dv = re(patch1, patch2, patch_size, log_sigma, n_kernels, threshold)
    %RE  Edge similarity decision variable from two patches' zero-crossing contours.
    %   dv = re(patch1, patch2, patch_size, log_sigma, n_kernels, threshold)
    %
    %   Each patch is contrast-normalized, then its Laplacian-of-Gaussian zero
    %   crossings are found and thresholded by local gradient magnitude to keep
    %   only strong edges. Each patch's surviving zero-crossing pixels are
    %   grouped into connected contours (MK_CONTOUR orders each contour's
    %   pixels into a walk), and the mean absolute gradient-orientation change
    %   between consecutive contour pixels is computed per patch. dv is the
    %   difference of these two per-patch means.
    %
    %   Inputs
    %     patch1     - first image patch, square, in gray levels.
    %     patch2     - second image patch, same size as patch1, in gray levels.
    %     patch_size - patch side length, in pixels.
    %     log_sigma  - Gaussian sigma of the LoG edge detector, in pixels
    %                  (passed as EDGE(...,'log',0,log_sigma)).
    %     n_kernels  - nominally the number of orientation kernels; only
    %                  appears in a dead `0*n_kernels` expression below (see
    %                  the findings log), so its value has no effect.
    %     threshold  - gradient-magnitude threshold below which a zero-crossing
    %                  pixel is discarded, in the same units as IMGRADIENT's
    %                  magnitude output.
    %
    %   Output
    %     dv - mean gradient-orientation-change difference (patch2 minus
    %          patch1), in degrees. Larger means more evidence the two
    %          patches' contours differ in local curvature/orientation.
    %
    %   See also RS, RS_NEW, RP, MK_CONTOUR.

    % normalize patches to have same mean and standard deviation
    patch1 = patch1*128/mean(mean(patch1)) - 128;
    patch2 = patch2*128/mean(mean(patch2)) - 128;
    sd1 = sqrt(sum(sum(patch1.*patch1))/patch_size^2);
    sd2 = sqrt(sum(sum(patch2.*patch2))/patch_size^2);
    patch1 = patch1*42/sd1 + 128;
    patch2 = patch2*42/sd2 + 128;

    % find zero crossings
    zero_cross1 = edge(patch1, 'log', 0, log_sigma);
    zero_cross2 = edge(patch2, 'log', 0, log_sigma);

    % compute image gradient magnitude and direction
    [grad_mag1, grad_dir1] = imgradient(patch1);
    [grad_mag2, grad_dir2] = imgradient(patch2);

    % find gradient magnitudes at zero crossings
    grad_mag1 = grad_mag1.*zero_cross1;
    grad_mag2 = grad_mag2.*zero_cross2;

    % threshold zero crossings based on gradient magnitude
    for ii = 1:patch_size
        for jj = 1:patch_size
            if grad_mag1(ii, jj) < threshold
                grad_mag1(ii, jj) = 0;
                zero_cross1(ii, jj) = 0;
                grad_dir1(ii, jj) = 0*n_kernels;
            end
            if grad_mag2(ii, jj) < threshold
                grad_mag2(ii, jj) = 0;
                zero_cross2(ii, jj) = 0;
                grad_dir2(ii, jj) = 0;
            end
        end
    end

    % find contours and contour properties for patch 1
    max_pixels = 500;
    cc = bwconncomp(zero_cross1);
    label_map1 = labelmatrix(cc);
    n_contours1 = cc.NumObjects;         % number of contours
    n_pixels = zeros(n_contours1, 1);
    pixel_row = zeros(n_contours1, max_pixels);
    pixel_col = zeros(n_contours1, max_pixels);
    for ii = 1:patch_size
        for jj = 1:patch_size
            region_label = label_map1(ii, jj);
            if region_label > 0
                n_pixels(region_label) = n_pixels(region_label) + 1;   % pixels in this contour
                pixel_row(region_label, n_pixels(region_label)) = ii;  % row of this pixel
                pixel_col(region_label, n_pixels(region_label)) = jj;  % col of this pixel
            end
        end
    end
    mismatch_count = 0; sum_orient_diff = 0; n_segments = 0;
    for kk = 1:n_contours1
        [contour_pts, links, n_contour_pts] = ...
            mk_contour(n_pixels(kk), pixel_row(kk, :), pixel_col(kk, :));
        if n_contour_pts < n_pixels(kk)
            mismatch_count = mismatch_count + 1;
        end
        for ii = 1:n_contour_pts-1
            y = pixel_row(kk, contour_pts(ii));       % coordinates of pixel i
            x = pixel_col(kk, contour_pts(ii));
            yp1 = pixel_row(kk, contour_pts(ii+1));    % coordinates of pixel i+1
            xp1 = pixel_col(kk, contour_pts(ii+1));
            % cosine of orientation difference
            cos_orient_diff = sind(grad_dir1(x, y))*sind(grad_dir1(xp1, yp1)) + ...
                cosd(grad_dir1(x, y))*cosd(grad_dir1(xp1, yp1));
            sum_orient_diff = sum_orient_diff + acosd(cos_orient_diff);  % sum of orient diffs
            n_segments = n_segments + 1;
        end
    end
    mean_orient_diff1 = sum_orient_diff/n_segments;

    % find contours and contour properties for patch 2
    max_pixels = 500;
    cc = bwconncomp(zero_cross2);
    label_map2 = labelmatrix(cc);
    n_contours2 = cc.NumObjects;         % number of contours
    n_pixels = zeros(n_contours2, 1);
    pixel_row = zeros(n_contours2, max_pixels);
    pixel_col = zeros(n_contours2, max_pixels);
    for ii = 1:patch_size
        for jj = 1:patch_size
            region_label = label_map2(ii, jj);
            if region_label > 0
                n_pixels(region_label) = n_pixels(region_label) + 1;   % pixels in this contour
                pixel_row(region_label, n_pixels(region_label)) = ii;  % row of this pixel
                pixel_col(region_label, n_pixels(region_label)) = jj;  % col of this pixel
            end
        end
    end
    mismatch_count = 0; sum_orient_diff = 0; n_segments = 0;
    for kk = 1:n_contours1
        [contour_pts, links, n_contour_pts] = ...
            mk_contour(n_pixels(kk), pixel_row(kk, :), pixel_col(kk, :));
        if n_contour_pts < n_pixels(kk)
            mismatch_count = mismatch_count + 1;
        end
        for ii = 1:n_contour_pts-1
            y = pixel_row(kk, contour_pts(ii));       % coordinates of pixel i
            x = pixel_col(kk, contour_pts(ii));
            yp1 = pixel_row(kk, contour_pts(ii+1));    % coordinates of pixel i+1
            xp1 = pixel_col(kk, contour_pts(ii+1));
            % cosine of orientation difference
            cos_orient_diff = sind(grad_dir2(x, y))*sind(grad_dir2(xp1, yp1)) + ...
                cosd(grad_dir2(x, y))*cosd(grad_dir2(xp1, yp1));
            sum_orient_diff = sum_orient_diff + acosd(cos_orient_diff);  % sum of orient diffs
            n_segments = n_segments + 1;
        end
    end
    mean_orient_diff2 = sum_orient_diff/n_segments;

    % find contours and contour properties for patch 2
    % cc = bwconncomp(zc2);
    % lcc2 = labelmatrix(cc);
    % nc2 = cc.NumObjects;         % number of contours
    % eps2 = zeros(nc2,7);
    % for i = 1:psz
    %   for j = 1:psz
    %     en = lcc2(i,j);
    %     if en > 0
    %       eps2(en,1) = eps2(en,1) + 1; % number of pixels in contour
    %       eps2(en,2) = eps2(en,2) + gm2(i,j);   % gradient magnitude
    %       eps2(en,3) = eps2(en,3) + gm2(i,j)^2; % gradient magnitude squared
    %     end
    %   end
    % end
    % for i = 1:nc2
    %   eps2(i,2) = eps2(i,2)/eps2(i,1);
    %   eps2(i,3) = eps2(i,3)/eps2(i,1);
    % end
    % ml1 = mean(eps1(:,1));
    % ml2 = mean(eps2(:,1));
    % mg1 = mean(eps1(:,2));
    % mg2 = mean(eps2(:,2));
    % msg1 = mean(eps1(:,3));
    % msg2 = mean(eps2(:,3));
    % vg1 = msg1 - mg1^2;
    % vg2 = msg2 - mg2^2;

    % figure; colormap(gray(256)); image(patch1); axis image;
    % figure; colormap(gray(256)); image(patch2); axis image;
    % figure; colormap(gray(256)); image(zero_cross1*255); axis image;
    % figure; colormap(gray(256)); image(grad_mag1); axis image;
    % figure; colormap(gray(256)); image(zero_cross2*255); axis image;
    % figure; colormap(gray(256)); image(grad_mag2); axis image;
    dv = mean_orient_diff2-mean_orient_diff1;
end
