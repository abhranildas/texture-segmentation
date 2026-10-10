% EFFECTIVE_DISTANCE  Shortest indirect path length between patch pairs.
%   run('+grouping/effective_distance.m')
%
%   Script, not a function, so it cannot be called as
%   grouping.effective_distance; whether to finish it as a function or
%   delete it is item S3.3 in docs/repo-cleanup.md. For each connected patch pair it walks the other
%   pairs looking for a shorter route, and keeps the smallest distance found -
%   an "effective" rather than straight-line separation.
%
%   Unfinished, and it does not run as written: the adjacency matrix a and the
%   distance matrix d are read but never built, abs(i1, k2) calls abs with two
%   arguments, and the inner test and the assignment disagree about which pair
%   they refer to. See bug B3.9 in docs/repo-cleanup.md; nothing in the repo
%   calls this script.
%
%   Inputs
%     none (n_patches is hardcoded below; a and d are missing).
%
%   Output
%     eff_dist - n_patches by n_patches matrix of effective distances, in
%                patches, upper triangle only.
%
%   See also GROUPING.MK_DIST, GROUPING.FIND_TEX_REGIONS.

n_patches = 16;
dist_max = sqrt(2*(n_patches-1)^2);
eff_dist = zeros(n_patches, n_patches);
for i1 = 1:n_patches
    for i2 = i1+1:n_patches
        if a(i1, i2) > 0
            dist_min = d(i1, i2);
            for k1 = i1+1:n_patches
                for k2 = k1+1:n_patches
                    if abs(i1, k2) > 0
                        if d(k1, k2) < dist_min
                            dist_min = d(i1, k2);
                        end
                    end
                end
            end
            eff_dist(i1, i2) = dist_min;
        end
    end
end
