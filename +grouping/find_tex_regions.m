function pairs = find_tex_regions()
% FIND_TEX_REGIONS  Enumerate the patch grid and every unordered patch pair.
%   pairs = grouping.find_tex_regions()
%
%   Numbers the patches of a 16 by 16 grid, then lists every unordered pair
%   of distinct patches together with the distance between them. The pair
%   array is sized for five columns but only three are filled, so the
%   function stops short of whatever it was meant to find. GROUPING.MK_DIST
%   already computes the same distances in matrix form; whether this file
%   should be kept at all is item S3.3 in docs/repo-cleanup.md.
%
%   Inputs
%     none (the grid geometry is hardcoded below).
%
%   Output
%     pairs - n_pairs by 5 array, n_pairs = n_patches*(n_patches-1)/2;
%             columns 1 and 2 are the two patch numbers, column 3 their
%             separation in patches, columns 4 and 5 unused (zero).
%
%   Note: like the script it replaces, this closes every open figure first.
%
%   See also GROUPING.MK_DIST, GROUPING.TEX_REGIONS.

    close all;
    patch_width = 64;  % patch width (pixels)
    grid_size = 16;  % patches per row and per column
    image_width = patch_width*grid_size;  % image width (pixels)
    n_patches = grid_size^2;  % total number of patches

    % load patch locations
    patch_x = zeros(n_patches, 1);
    patch_y = zeros(n_patches, 1);
    i_patch = 0;
    for index1 = 1:grid_size
        for index2 = 1:grid_size
            i_patch = i_patch + 1;
            patch_x(i_patch) = index1;
            patch_y(i_patch) = index2;
        end
    end

    % initialize patch pair array
    n_pairs = n_patches*(n_patches-1)/2;
    pairs = zeros(n_pairs, 5);  % patch pair array

    % load patch pair indices and distances
    i_pair = 0;  % initialize patch pair counter
    for index1 = 1:n_patches
        for index2 = index1+1:n_patches
            i_pair = i_pair + 1;
            % patch numbers
            pairs(i_pair, 1) = index1;
            pairs(i_pair, 2) = index2;
            % distance
            pairs(i_pair, 3) = sqrt((patch_x(index1)-patch_x(index2))^2 + ...
                (patch_y(index1)-patch_y(index2))^2);
        end
    end
end
