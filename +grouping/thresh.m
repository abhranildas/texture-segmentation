function rthresh = thresh(response, n_patches, threshold)
    %THRESH  Threshold a square patch-pair response matrix, forcing the diagonal true.
    %   rthresh = thresh(response, n_patches, threshold)
    %
    %   Inputs
    %     response  - square matrix of pairwise patch response values, size
    %                 n_patches-by-n_patches.
    %     n_patches - total number of patches (response's side length, in
    %                 elements; e.g. grid_size^2 for a square patch grid).
    %     threshold - value response must exceed to be kept.
    %
    %   Output
    %     rthresh - logical-valued (0/1) matrix, same size as response;
    %               rthresh(i,j) = 1 where response(i,j) > threshold, or
    %               where i == j (the diagonal is always set true).
    %
    %   See also NLSAME.

    rthresh = zeros(n_patches, n_patches);
    for i_row = 1:n_patches
        for i_col = 1:n_patches
            if response(i_row, i_col) > threshold
                rthresh(i_row, i_col) = 1;
            end
            if i_row == i_col
                rthresh(i_row, i_col) = 1;
            end
        end
    end
end
