function [x, y] = find_xy(trial, maps, grid_size)
% FIND_XY  Draw a random patch location that is not on a region boundary.
%   [x, y] = grouping.find_xy(trial, maps, grid_size)
%
%   Samples locations uniformly over the grid and rejects any whose eight
%   neighbours are not all in the same texture region, so the returned patch
%   sits in the interior of one region. The rejection test is the same one
%   GROUPING.CHECK_XY applies, written out inline here.
%
%   Inputs
%     trial     - trial number, indexing the third dimension of maps.
%     maps      - grid_size by grid_size by (number of trials) array of
%                 texture-region labels, from GROUPING.MK_MASKS.
%     grid_size - side length of the square patch grid, as an integer count of
%                 patches.
%
%   Output
%     x, y - patch location on the grid, integer patch indices in 1:grid_size.
%
%   See also GROUPING.CHECK_XY, GROUPING.MK_MASKS.

    is_boundary = 1;
    while is_boundary == 1
        x = randi(grid_size);
        y = randi(grid_size);
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
end
