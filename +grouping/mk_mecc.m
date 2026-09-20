function min_ecc = mk_mecc(grid_size)
% MK_MECC  Smaller of the two eccentricities of every patch pair on the grid.
%   min_ecc = grouping.mk_mecc(grid_size)
%
%   A patch's eccentricity is its distance from the grid center, which this
%   function takes to be the lattice point (grid_size/2, grid_size/2). Patch
%   (x, y) is numbered (x-1)*grid_size + y, and that patch number indexes both
%   dimensions of the result, so min_ecc is symmetric. Paired with
%   GROUPING.MK_DECC, which gives the difference of the same two
%   eccentricities.
%
%   Inputs
%     grid_size - side length of the square patch grid, as an integer count of
%                 patches (not pixels, not degrees).
%
%   Output
%     min_ecc - grid_size^2 by grid_size^2 matrix holding, for each patch pair,
%               the smaller of the two patches' eccentricities, in patches.
%
%   See also GROUPING.MK_DECC, GROUPING.MK_DIST, GROUPING.MK_BINDEX,
%   GROUPING.FIND_BIN.

    min_ecc = zeros(grid_size^2, grid_size^2);
    for x1 = 1:grid_size
        for y1 = 1:grid_size
            for x2 = 1:grid_size
                for y2 = 1:grid_size
                    patch_index1 = (x1-1)*grid_size + y1;
                    patch_index2 = (x2-1)*grid_size + y2;
                    ecc1 = sqrt((x1-grid_size/2)^2 + (y1-grid_size/2)^2);
                    ecc2 = sqrt((x2-grid_size/2)^2 + (y2-grid_size/2)^2);
                    min_ecc(patch_index1, patch_index2) = min(ecc1, ecc2);
                end
            end
        end
    end
end
