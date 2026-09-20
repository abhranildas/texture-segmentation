function is_boundary = check_xy(x, y, trial, maps, grid_size)
% CHECK_XY  Test whether a patch lies on a texture-region boundary.
%   is_boundary = grouping.check_xy(x, y, trial, maps, grid_size)
%
%   A patch is on a boundary if any of its eight neighbours on the grid carries
%   a different region label. Neighbours off the edge of the grid are skipped,
%   so a patch on the grid border is not a boundary patch just for being there.
%   GROUPING.FIND_XY draws random non-boundary locations using the same test.
%
%   Inputs
%     x, y      - patch location on the grid, integer patch indices in
%                 1:grid_size.
%     trial     - trial number, indexing the third dimension of maps.
%     maps      - grid_size by grid_size by (number of trials) array of
%                 texture-region labels, from GROUPING.MK_MASKS.
%     grid_size - side length of the square patch grid, as an integer count of
%                 patches.
%
%   Output
%     is_boundary - 1 if the patch is on a region boundary, 0 if not.
%
%   See also GROUPING.FIND_XY, GROUPING.MK_MASKS.

    region = maps(x, y, trial);
    is_boundary = 0;
    if x < grid_size
        if maps(x+1, y, trial) ~= region
            is_boundary = 1;
        end
    end
    if y < grid_size
        if maps(x, y+1, trial) ~= region
            is_boundary = 1;
        end
    end
    if x < grid_size && y < grid_size
        if maps(x+1, y+1, trial) ~= region
            is_boundary = 1;
        end
    end
    if x > 1
        if maps(x-1, y, trial) ~= region
            is_boundary = 1;
        end
    end
    if y > 1
        if maps(x, y-1, trial) ~= region
            is_boundary = 1;
        end
    end
    if x > 1 && y > 1
        if maps(x-1, y-1, trial) ~= region
            is_boundary = 1;
        end
    end
    if x > 1 && y < grid_size
        if maps(x-1, y+1, trial) ~= region
            is_boundary = 1;
        end
    end
    if x < grid_size && y > 1
        if maps(x+1, y-1, trial) ~= region
            is_boundary = 1;
        end
    end
end
