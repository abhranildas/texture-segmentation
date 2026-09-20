function bin_index = mk_bindex(bin_bounds_dist, bin_bounds_min_ecc, bin_bounds_delta_ecc)
% MK_BINDEX  Number the geometry bins formed by three sets of bin bounds.
%   bin_index = grouping.mk_bindex(bin_bounds_dist, bin_bounds_min_ecc, ...
%       bin_bounds_delta_ecc)
%
%   A patch pair's geometry is described by three quantities - separation,
%   smaller eccentricity, and eccentricity difference - each cut into bins by
%   its own vector of bounds. This builds the lookup that turns a triple of
%   per-quantity bin numbers into a single bin number running from 1 to the
%   total number of bins. GROUPING.FIND_BIN is the only reader.
%
%   Inputs
%     bin_bounds_dist      - increasing row vector of bin edges for the pair
%                            separation, in patches; n edges give n-1 bins.
%     bin_bounds_min_ecc   - bin edges for the smaller of the pair's two
%                            eccentricities, in patches.
%     bin_bounds_delta_ecc - bin edges for the difference of the pair's two
%                            eccentricities, in patches.
%
%   Output
%     bin_index - array of bin numbers, sized (number of distance bins) by
%                 (number of min-eccentricity bins) by (number of
%                 delta-eccentricity bins), holding 1 to the total bin count.
%
%   See also GROUPING.FIND_BIN, GROUPING.MK_DIST, GROUPING.MK_MECC,
%   GROUPING.MK_DECC.

    n_dist_bins = size(bin_bounds_dist, 2) - 1;
    n_min_ecc_bins = size(bin_bounds_min_ecc, 2) - 1;
    n_delta_ecc_bins = size(bin_bounds_delta_ecc, 2) - 1;

    bin_index = zeros(n_dist_bins, n_min_ecc_bins, n_delta_ecc_bins);
    bin = 0;
    for i_dist = 1:n_dist_bins
        for i_min_ecc = 1:n_min_ecc_bins
            for i_delta_ecc = 1:n_delta_ecc_bins
                bin = bin + 1;
                bin_index(i_dist, i_min_ecc, i_delta_ecc) = bin;
            end
        end
    end
end
