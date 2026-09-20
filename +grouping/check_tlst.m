function [is_free, x_out, y_out] = check_tlst(side, x, y, map, grid_size)
% CHECK_TLST  Test whether the patch on one side of a given patch is unfilled.
%   [is_free, x_out, y_out] = grouping.check_tlst(side, x, y, map, grid_size)
%
%   The region-growing loop in GROUPING.MK_MASKS uses this to find somewhere to
%   extend a texture region: it walks the four sides of a patch already in the
%   region, in random order, and takes the first side whose neighbour is still
%   unlabelled. A side that runs off the edge of the grid counts as unavailable.
%
%   Inputs
%     side      - which side of the patch to test: 1 = x+1, 2 = y+1, 3 = x-1,
%                 4 = y-1.
%     x, y      - location of the patch being extended from, integer patch
%                 indices in 1:grid_size.
%     map       - grid_size by grid_size array of texture-region labels, 0
%                 where no region has claimed the patch yet.
%     grid_size - side length of the square patch grid, as an integer count of
%                 patches.
%
%   Outputs
%     is_free      - 1 if the neighbour on that side exists and is unlabelled,
%                    0 otherwise.
%     x_out, y_out - location of that neighbour when is_free is 1; the input
%                    x, y unchanged when it is 0.
%
%   See also GROUPING.MK_MASKS.

    x_out = x;
    y_out = y;
    is_free = 0;
    if side == 1
        if x < grid_size
            if map(x+1, y) == 0
                is_free = 1;
                x_out = x + 1;
                y_out = y;
            end
        else
            is_free = 0;
        end
    elseif side == 2
        if y < grid_size
            if map(x, y+1) == 0
                is_free = 1;
                x_out = x;
                y_out = y + 1;
            end
        else
            is_free = 0;
        end
    elseif side == 3
        if x > 1
            if map(x-1, y) == 0
                is_free = 1;
                x_out = x - 1;
                y_out = y;
            end
        else
            is_free = 0;
        end
    else
        if y > 1
            if map(x, y-1) == 0
                is_free = 1;
                x_out = x;
                y_out = y - 1;
            end
        else
            is_free = 0;
        end
    end
end
