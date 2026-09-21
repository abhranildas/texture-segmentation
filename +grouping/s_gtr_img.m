function [simg] = s_gtr_img(patch_img, patch_width, grid_size, n_channels)
% S_GTR_IMG  Segment a GTR (grouping) stimulus image into patch pairs.
%   [simg] = grouping.s_gtr_img(patch_img, patch_width, grid_size, n_channels)
%
%   Numbers the patches of the grid, then lists every unordered pair of
%   distinct patches together with the distance between them - the same
%   enumeration GROUPING.FIND_TEX_REGIONS builds. Declares simg as its output
%   but never assigns it, so a call requesting that output errors; see bug
%   B3.11 in docs/repo-cleanup.md. patch_img, patch_width and n_channels are
%   accepted but not used by the body (patch_width's only former use, a local
%   image-width computation, was itself unused and was removed in Stage 2 -
%   see this tranche's findings-log note). No caller exists anywhere in the
%   repo.
%
%   Inputs
%     patch_img   - image to segment (unused).
%     patch_width - patch width, in pixels (unused).
%     grid_size   - side length of the square patch grid, as an integer count
%                   of patches (not pixels).
%     n_channels  - number of color channels (unused).
%
%   Output
%     simg - never assigned; see B3.11.
%
%   See also GROUPING.FIND_TEX_REGIONS, GROUPING.MK_DIST, GROUPING.TEX_REGIONS.

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
            i_pair = i_pair+1;
            pairs(i_pair, 1) = index1;
            pairs(i_pair, 2) = index2;  % patch numbers
            pairs(i_pair, 3) = sqrt((patch_x(index1)-patch_x(index2))^2 + ...
                (patch_y(index1)-patch_y(index2))^2);  % distances
        end
    end
end
