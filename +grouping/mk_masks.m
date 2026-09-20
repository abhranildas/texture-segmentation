function [masks, maps] = mk_masks(grid_size, n_regions, n_trials, seed_radius_frac, fill_fraction)
% MK_MASKS  Grow random texture-region maps and masks for a whole session.
%   [masks, maps] = grouping.mk_masks(grid_size, n_regions, n_trials, ...
%       seed_radius_frac, fill_fraction)
%
%   Each trial gets its own partition of the patch grid into n_regions
%   contiguous texture regions. One distinct seed patch is drawn per region,
%   inside a disc about the grid center, and the regions then take turns
%   claiming a free neighbouring patch - in a fresh random region order on
%   every pass, so no region gets a systematic head start - until the
%   requested fraction of the grid is claimed. GROUPING.CHECK_TLST does the
%   per-side "is this neighbour still free" test.
%
%   Inputs
%     grid_size        - side length of the square patch grid, as an integer
%                        count of patches (not pixels).
%     n_regions        - number of texture regions per trial.
%     n_trials         - number of trials in the session.
%     seed_radius_frac - radius of the disc the region seeds are drawn from,
%                        as a fraction of half the grid width, so 1.0 means a
%                        disc inscribed in the grid.
%     fill_fraction    - fraction of the grid's patches to claim before
%                        growing stops; 1.0 leaves no unlabelled patch.
%
%   Outputs
%     masks - grid_size by grid_size by (n_trials*n_regions) array of 0/1
%             region masks, region varying fastest. Despite the header the
%             original author left, these come back as double, not logical.
%             The preallocated third dimension is wrong - see bug B3.3 in
%             docs/repo-cleanup.md - and every current caller discards this
%             output and uses maps instead.
%     maps  - grid_size by grid_size by n_trials array of region labels, each
%             patch holding its region number in 1:n_regions, or 0 if growing
%             stopped before it was claimed.
%
%   See also GROUPING.CHECK_TLST, GROUPING.CHECK_XY, GROUPING.FIND_XY.

    seed_radius = seed_radius_frac*grid_size/2;
    masks = zeros(grid_size, grid_size, grid_size*n_regions);
    maps = zeros(grid_size, grid_size, n_trials);
    for trial = 1:n_trials
        map = zeros(grid_size, grid_size);  % texture label map
        % list of patches for a region
        patch_list = zeros(n_regions, round(3*grid_size^2/n_regions) + 1);

        % seed the texture label map
        seeds = zeros(n_regions, 2);
        for i_region = 1:n_regions
            seed_repeat = 1;
            while seed_repeat == 1
                seed_repeat = 0;
                in_radius = 0;
                while in_radius == 0
                    x = randi(grid_size);
                    y = randi(grid_size);
                    if sqrt((x-grid_size/2)^2 + (y-grid_size/2)^2) < seed_radius
                        in_radius = 1;
                    end
                end
                for jj = 1:n_regions
                    if seeds(jj, 1) == x && seeds(jj, 2) == y
                        seed_repeat = 1;
                    end
                end
            end
            seeds(i_region, 1) = x;
            seeds(i_region, 2) = y;
            map(x, y) = i_region;  % write first patch label to map
            % save coordinates of first patch label
            patch_list(i_region, 1) = 1;
            patch_list(i_region, 2) = x;
            patch_list(i_region, 3) = y;
        end

        % grow the texture regions
        % while min(min(map)) == 0 % fill the image (no background pixels)
        while sum(patch_list(:,1)) < fill_fraction*grid_size^2
            % add to regions in a random order on each pass
            region_order = randperm(n_regions);
            for i_region = 1:n_regions
                jj = region_order(i_region);
                n_in_region = patch_list(jj, 1);
                % check patches in region for a free side in random order
                patch_order = randperm(n_in_region);
                kk = 1;
                is_free = 0;
                while n_in_region == patch_list(jj, 1) && kk <= n_in_region
                    x = patch_list(jj, 2*patch_order(kk));
                    y = patch_list(jj, 2*patch_order(kk)+1);
                    side_order = randperm(4);  % check the four sides in order
                    i_side = 0;
                    while i_side < 4 && is_free == 0
                        i_side = i_side + 1;
                        [is_free, x_out, y_out] = ...
                            grouping.check_tlst(side_order(i_side), x, y, map, grid_size);
                    end
                    if is_free == 1
                        % when 1 is added move on to the next region
                        patch_list(jj, 1) = patch_list(jj, 1) + 1;
                        patch_list(jj, 2*(n_in_region+1)) = x_out;
                        patch_list(jj, 2*(n_in_region+1)+1) = y_out;
                        map(x_out, y_out) = jj;
                    end
                    kk = kk + 1;  % if kk exceeds n_in_region, next region
                end
            end
        end

        % figure;
        % image(map*256/n_regions-1);
        % axis off;
        % axis square;
        % axis equal;

        % make masks and maps
        for i_region = 1:n_regions
            for jj = 1:grid_size
                for kk = 1:grid_size
                    if map(jj, kk) == i_region
                        masks(jj, kk, (trial-1)*n_regions+i_region) = 1;
                    end
                end
            end
            % figure;
            % image(masks(:,:,1)*256/n_regions-1);
            % axis off;
            % axis square;
            % axis equal;
        end
        maps(:,:,trial) = map;

        % lmsks = cast(msks,'logical');
    end
end
