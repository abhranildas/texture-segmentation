function dv = hist_dv(patch1, patch2, edges)
% HIST_DV  Same/different decision variable from two gray-level histograms.
%   dv = lib.hist_dv(patch1, patch2, edges)
%
%   Multinomial log-likelihood ratio that the two patches' gray-level
%   histograms were drawn from different distributions rather than the same
%   one. The normalizing count n_bins cancels between the numerator and
%   denominator terms, so its value does not affect the result.
%
%   Inputs
%     patch1 - first image patch, any size, in gray levels.
%     patch2 - second image patch, any size, in gray levels.
%     edges  - histogram bin edges, in the same gray levels as the patches
%              (1-by-(n_bins+1)).
%
%   Output
%     dv - the log-likelihood ratio, in nats. Larger means more evidence the
%          two patches differ.
%
%   See also LIB.POWER_DV, LIB.EDGE_PROPS_STIM.

    counts1 = histcounts(patch1, edges);
    counts2 = histcounts(patch2, edges);
    n_bins = size(counts1, 2);
    sum_num = 0;
    sum_den = 0;
    for i_bin = 1:n_bins
        if counts1(i_bin) > 0
            sum_num = sum_num + counts1(i_bin)*log(counts1(i_bin)/n_bins);
        end
        if counts2(i_bin) > 0
            sum_num = sum_num + counts2(i_bin)*log(counts2(i_bin)/n_bins);
        end
        if (counts1(i_bin) + counts2(i_bin)) > 0
            sum_den = sum_den + (counts1(i_bin) + counts2(i_bin))*...
                log((counts1(i_bin) + counts2(i_bin))/(2*n_bins));
        end
    end

    dv = sum_num - sum_den;
end
