function dist = mk_dist(grid_size)
% MK_DIST  Distance between every ordered pair of patches on the patch grid.
%   dist = grouping.mk_dist(grid_size)
%
%   Patch (x, y) of the grid is numbered (x-1)*grid_size + y, and that patch
%   number indexes both dimensions of the result, so dist is symmetric with a
%   zero diagonal. GROUPING.FIND_BIN reads one entry of this matrix, together
%   with the matching entries of GROUPING.MK_MECC and GROUPING.MK_DECC, to
%   place a patch pair in a geometry bin.
%
%   Inputs
%     grid_size - side length of the square patch grid, as an integer count of
%                 patches (not pixels, not degrees).
%
%   Output
%     dist - grid_size^2 by grid_size^2 matrix of center-to-center distances
%            between patch pairs, in patches.
%
%   See also GROUPING.MK_MECC, GROUPING.MK_DECC, GROUPING.MK_BINDEX,
%   GROUPING.FIND_BIN.

    dist = zeros(grid_size^2, grid_size^2);
    for x1 = 1:grid_size
        for y1 = 1:grid_size
            for x2 = 1:grid_size
                for y2 = 1:grid_size
                    patch_index1 = (x1-1)*grid_size + y1;
                    patch_index2 = (x2-1)*grid_size + y2;
                    dist(patch_index1, patch_index2) = sqrt((x1-x2)^2 + (y1-y2)^2);
                end
            end
        end
    end
end
