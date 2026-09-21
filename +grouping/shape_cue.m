function [cue, cue_map] = shape_cue(map, grid_size, region)
% SHAPE_CUE  Crop one texture region's outline into a small cue thumbnail.
%   [cue, cue_map] = grouping.shape_cue(map, grid_size, region)
%
%   Finds the bounding box of the given region on the label map, recolors
%   that box to a two-level (background/target) image, and centers it in a
%   grid_size by grid_size by 3 thumbnail. GROUPING.MK_TEXSEG_STIM_SHAPE and
%   GROUPING.MK_TEXSEG_STIM_SHAPE_OLD use this as the shape cue shown before a
%   trial's stimulus.
%
%   Inputs
%     map       - grid_size by grid_size array of texture-region labels, from
%                 GROUPING.MK_MASKS.
%     grid_size - side length of the square patch grid, as an integer count
%                 of patches (not pixels).
%     region    - region label to build the cue for.
%
%   Outputs
%     cue     - grid_size by grid_size by 3 cue thumbnail: mid-gray outside
%               the region's bounding box, background level inside the box
%               but outside the region, target level inside the region.
%     cue_map - grid_size by grid_size mask, 0 where map equals region, 1
%               elsewhere.
%
%   See also GROUPING.MK_TEXSEG_STIM_SHAPE, GROUPING.MK_TEXSEG_STIM_SHAPE_OLD,
%   GROUPING.MK_MASKS.

    bg_lum = 128;
    target_lum = 112;

    % bounding box of the region (ii, jj swap row/column role between the
    % row and column searches below, since check_stage1's rename map cannot
    % split one old name into two new ones - see tranche 3's rule C-6)
    row_min = 0;
    for ii = 1:grid_size
        for jj = 1:grid_size
            if map(ii, jj) == region && row_min == 0
                row_min = ii;
            end
        end
    end
    row_max = 0;
    for ii = grid_size:-1:1
        for jj = 1:grid_size
            if map(ii, jj) == region && row_max == 0
                row_max = ii;
            end
        end
    end
    col_min = 0;
    for ii = 1:grid_size
        for jj = 1:grid_size
            if map(jj, ii) == region && col_min == 0
                col_min = ii;
            end
        end
    end
    col_max = 0;
    for ii = grid_size:-1:1
        for jj = 1:grid_size
            if map(jj, ii) == region && col_max == 0
                col_max = ii;
            end
        end
    end

    region_crop = map(row_min:row_max, col_min:col_max);
    crop_size = size(region_crop);
    for ii = 1:crop_size(1)
        for jj = 1:crop_size(2)
            if region_crop(ii, jj) ~= region
                region_crop(ii, jj) = bg_lum;
            else
                region_crop(ii, jj) = target_lum;
            end
        end
    end
    row_offset = floor((grid_size-crop_size(1))/2);
    col_offset = floor((grid_size-crop_size(2))/2);
    cue = ones(grid_size, grid_size, 3)*128;
    cue(row_offset+1:row_offset+crop_size(1), col_offset+1:col_offset+crop_size(2), 1) = ...
        region_crop;
    cue(row_offset+1:row_offset+crop_size(1), col_offset+1:col_offset+crop_size(2), 2) = ...
        region_crop;
    cue(row_offset+1:row_offset+crop_size(1), col_offset+1:col_offset+crop_size(2), 3) = ...
        region_crop;

    cue_map = ones(grid_size, grid_size);
    for ii = 1:grid_size
        for jj = 1:grid_size
            if map(ii, jj) == region
                cue_map(ii, jj) = 0;
            end
        end
    end
    % figure;
    % image(cue/255); axis('square');
end
