function [dist, min_ecc, delta_ecc, bin_index] = mk_pair_geometry(grid_size, ...
    bin_bounds_dist, bin_bounds_min_ecc, bin_bounds_delta_ecc)
% MK_PAIR_GEOMETRY  Build the patch-pair geometry matrices and the bin index.
%   [dist, min_ecc, delta_ecc, bin_index] = grouping.mk_pair_geometry( ...
%       grid_size, bin_bounds_dist, bin_bounds_min_ecc, bin_bounds_delta_ecc)
%
%   The whole setup a session builder needs before it can place a patch pair
%   in a geometry bin with GROUPING.FIND_BIN: the three pair matrices, each
%   indexed on both dimensions by patch number, and the lookup that turns a
%   triple of per-quantity bin numbers into one bin number. It computes
%   nothing of its own - it is exactly GROUPING.MK_DIST, GROUPING.MK_MECC,
%   GROUPING.MK_DECC and GROUPING.MK_BINDEX, called with these arguments, in
%   that order. It exists because all three session builders need all four,
%   and each used to call them separately.
%
%   Inputs
%     grid_size            - side length of the square patch grid, as an
%                            integer count of patches (not pixels, not
%                            degrees).
%     bin_bounds_dist      - increasing row vector of bin edges for the pair
%                            separation, in patches; n edges give n-1 bins.
%     bin_bounds_min_ecc   - bin edges for the smaller of the pair's two
%                            eccentricities, in patches.
%     bin_bounds_delta_ecc - bin edges for the difference of the pair's two
%                            eccentricities, in patches.
%
%   Outputs
%     dist      - grid_size^2 by grid_size^2 matrix of center-to-center
%                 distances between patch pairs, in patches.
%     min_ecc   - grid_size^2 by grid_size^2 matrix holding, for each patch
%                 pair, the smaller of the two patches' eccentricities, in
%                 patches.
%     delta_ecc - grid_size^2 by grid_size^2 matrix holding, for each patch
%                 pair, the absolute difference of the two patches'
%                 eccentricities, in patches.
%     bin_index - array of bin numbers, sized (number of distance bins) by
%                 (number of min-eccentricity bins) by (number of
%                 delta-eccentricity bins), holding 1 to the total bin count.
%
%   See also GROUPING.MK_DIST, GROUPING.MK_MECC, GROUPING.MK_DECC,
%   GROUPING.MK_BINDEX, GROUPING.FIND_BIN.

    dist = grouping.mk_dist(grid_size);
    min_ecc = grouping.mk_mecc(grid_size);
    delta_ecc = grouping.mk_decc(grid_size);
    bin_index = grouping.mk_bindex(bin_bounds_dist, bin_bounds_min_ecc, ...
        bin_bounds_delta_ecc);
end
