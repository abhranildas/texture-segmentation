function bin = find_bin(patch_index1, patch_index2, dist, min_ecc, delta_ecc, ...
    bin_bounds_dist, bin_bounds_min_ecc, bin_bounds_delta_ecc, bin_index)
% FIND_BIN  Geometry bin of one pair of patch locations on the patch grid.
%   bin = grouping.find_bin(patch_index1, patch_index2, dist, min_ecc, ...
%       delta_ecc, bin_bounds_dist, bin_bounds_min_ecc, ...
%       bin_bounds_delta_ecc, bin_index)
%
%   Reads the pair's separation, smaller eccentricity and eccentricity
%   difference out of the three precomputed matrices, finds which bin each
%   falls in, and looks the triple up in the bin-number array. The three
%   matrices and the bin-number array all come from the GROUPING.MK_* helpers
%   below, built for the same grid_size and the same bin bounds.
%
%   Inputs
%     patch_index1         - number of the first patch of the pair; patch
%                            (x, y) is numbered (x-1)*grid_size + y.
%     patch_index2         - number of the second patch of the pair.
%     dist                 - pair separation matrix from GROUPING.MK_DIST, in
%                            patches.
%     min_ecc              - smaller-eccentricity matrix from
%                            GROUPING.MK_MECC, in patches.
%     delta_ecc            - eccentricity-difference matrix from
%                            GROUPING.MK_DECC, in patches.
%     bin_bounds_dist      - row vector of separation bin edges, in patches.
%     bin_bounds_min_ecc   - row vector of min-eccentricity bin edges, in
%                            patches.
%     bin_bounds_delta_ecc - row vector of delta-eccentricity bin edges, in
%                            patches.
%     bin_index            - bin-number array from GROUPING.MK_BINDEX.
%
%   Output
%     bin - geometry bin number of the pair, from 1 to the total bin count.
%
%   Known limitation: a pair falling outside any of the three sets of bin
%   bounds is not handled - see bug B3.2 in docs/repo-cleanup.md.
%
%   See also GROUPING.MK_BINDEX, GROUPING.MK_DIST, GROUPING.MK_MECC,
%   GROUPING.MK_DECC.

    n_dist_bins = size(bin_bounds_dist, 2) - 1;
    n_min_ecc_bins = size(bin_bounds_min_ecc, 2) - 1;
    n_delta_ecc_bins = size(bin_bounds_delta_ecc, 2) - 1;

    pair_dist = dist(patch_index1, patch_index2);
    pair_min_ecc = min_ecc(patch_index1, patch_index2);
    pair_delta_ecc = delta_ecc(patch_index1, patch_index2);

    i_dist = 0;
    for i_bin = 1:n_dist_bins
        if pair_dist >= bin_bounds_dist(i_bin) && pair_dist <= bin_bounds_dist(i_bin+1)
            i_dist = i_bin;
        end
    end
    for i_bin = 1:n_min_ecc_bins
        if pair_min_ecc >= bin_bounds_min_ecc(i_bin) && ...
                pair_min_ecc <= bin_bounds_min_ecc(i_bin+1)
            i_min_ecc = i_bin;
        end
    end
    for i_bin = 1:n_delta_ecc_bins
        if pair_delta_ecc >= bin_bounds_delta_ecc(i_bin) && ...
                pair_delta_ecc <= bin_bounds_delta_ecc(i_bin+1)
            i_delta_ecc = i_bin;
        end
    end
    if i_dist == 0
        err = 1;
    end
    bin = bin_index(i_dist, i_min_ecc, i_delta_ecc);
end
