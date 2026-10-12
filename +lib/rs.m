function dv = rs(patch1, patch2, patch_size)
    %RS  Spatial pattern similarity decision variable from two patches.
    %   dv = rs(patch1, patch2, patch_size)
    %
    %   Each patch is mean-subtracted and normalized to unit energy. patch1 is
    %   circularly shifted over every offset within the patch, and the largest
    %   dot product with patch2 over all shifts is taken as the two patches'
    %   best-aligned similarity. dv is the reciprocal of that maximum.
    %
    %   Inputs
    %     patch1     - first image patch, square, in gray levels.
    %     patch2     - second image patch, same size as patch1, in gray levels.
    %     patch_size - patch side length, in pixels.
    %
    %   Output
    %     dv - reciprocal of the best-aligned normalized similarity.
    %          Smaller means more evidence the two patches are similar.
    %
    %   See also RE, RS_NEW, VISLAB.NAT_STAT_BAYES.DV_POWER.

    % normalize patches
    p1 = patch1-mean(mean(patch1));
    p2 = patch2-mean(mean(patch2));
    p1 = p1/sqrt(sum(sum(p1.^2)));
    p2 = p2/sqrt(sum(sum(p2.^2)));

    dv = -1;
    for dx = 1:patch_size
        for dy = 1:patch_size
            p1s = circshift(p1, [dx, dy]);
            sm = sum(sum(p1s.*p2));
            if sm > dv
                dv = sm;
            end
        end
    end
    dv = 1/dv;
end
