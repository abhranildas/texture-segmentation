function dv = rs_new(patch1, patch2, patch_size, n_subpatches)
    %RS_NEW  Spatial pattern similarity decision variable, subpatch-correlation variant.
    %   dv = rs_new(patch1, patch2, patch_size, n_subpatches)
    %
    %   An alternative to RS: patch1 and patch2 are each mean-subtracted and
    %   normalized to unit energy, then tiled into an n_subpatches-by-
    %   n_subpatches grid of sub-blocks. Each sub-block is cross-correlated
    %   against both patches, and the four resulting correlation surfaces are
    %   combined through VISLAB.NAT_STAT_BAYES.DV_POWER's power-difference
    %   measure and summed over all sub-blocks.
    %
    %   Inputs
    %     patch1       - first image patch, square, in gray levels.
    %     patch2       - second image patch, same size as patch1, in gray
    %                    levels.
    %     patch_size   - patch side length, in pixels.
    %     n_subpatches - number of sub-blocks per patch side (patch_size must
    %                    be evenly divisible by n_subpatches).
    %
    %   Output
    %     dv - summed DV_POWER power-difference measure over all sub-blocks.
    %
    %   See also RS, RE, VISLAB.NAT_STAT_BAYES.DV_POWER.

    % normalize patches
    p1 = patch1-mean(mean(patch1));
    p2 = patch2-mean(mean(patch2));
    p1 = p1/sqrt(sum(sum(p1.^2)));
    p2 = p2/sqrt(sum(sum(p2.^2)));

    subpatch_size = patch_size/n_subpatches;
    xsz = patch_size+subpatch_size-1;
    pszc = patch_size-subpatch_size;
    a = subpatch_size;
    threshold = 0;
    noise_const = 10;
    dv = 0;
    % s11 = 0; s22 = 0; s12 = 0; s21 = 0;
    for ii = 1:subpatch_size:patch_size-subpatch_size
        for jj = 1:subpatch_size:patch_size-subpatch_size
            p1k = p1(ii:ii+subpatch_size-1, jj:jj+subpatch_size-1);
            p1k = p1k-mean(mean(p1k));
            p1k = p1k/sum(sum(p1k.*p1k));
            p11 = xcorr2(p1, p1k);
            p11c = p11(a:xsz-a, a:xsz-a);
            %    p11c = abs(p11(a:xsz-a,a:xsz-a));
            p12 = xcorr2(p2, p1k);
            p12c = p12(a:xsz-a, a:xsz-a);
            %    p12c = abs(p12(a:xsz-a,a:xsz-a));
            p2k = p2(ii:ii+subpatch_size-1, jj:jj+subpatch_size-1);
            p2k = p2k-mean(mean(p2k));
            p2k = p2k/sum(sum(p2k.*p2k));
            p22 = xcorr2(p2, p2k);
            p22c = p22(a:xsz-a, a:xsz-a);
            %    p22c = abs(p22(a:xsz-a,a:xsz-a));
            p21 = xcorr2(p1, p2k);
            p21c = p21(a:xsz-a, a:xsz-a);
            %    p21c = abs(p21(a:xsz-a,a:xsz-a));

            p11c = max(p11c, threshold)-threshold;
            p22c = max(p22c, threshold)-threshold;
            p12c = max(p12c, threshold)-threshold;
            p21c = max(p21c, threshold)-threshold;

            r1 = vislab.nat_stat_bayes.dv_power(p11c, p21c, noise_const, pszc);
            r2 = vislab.nat_stat_bayes.dv_power(p22c, p12c, noise_const, pszc);
            dv = dv + r1 + r2;
            %
            %    s11 = s11 + sum(sum(p11c));
            %    s12 = s12 + sum(sum(p12c));
            %    s22 = s22 + sum(sum(p22c));
            %    s21 = s21 + sum(sum(p21c));
        end
    end
    % dv = s12/s11 + s21/s22;
end
