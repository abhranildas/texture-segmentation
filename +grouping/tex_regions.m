function tex_regions()
% TEX_REGIONS  Build and display one texture-region-grouping stimulus.
%   grouping.tex_regions()
%
%   Grows n_regions contiguous texture regions over the patch grid the same
%   way GROUPING.MK_MASKS does (one seed patch per region, then random-order
%   neighbour claiming via GROUPING.CHECK_TLST until the grid is full), but
%   for a single image rather than a whole session, and with a fixed list of
%   eight Brodatz textures rather than random draws.
%
%   Inputs
%     none (every parameter is hardcoded below).
%
%   Output
%     none (displays two figures: the region map, and the finished stimulus).
%
%   Note: like the script it replaces, this closes every open figure first.
%
%   See also GROUPING.MK_MASKS, GROUPING.CHECK_TLST, GROUPING.S_GTR_IMG.

    close all;

    % texture-sheet location comes from config(), never from the current folder
    cfg = config();

    patch_width = 64;      % 64 patch width (pixels)
    grid_size = 16;        % 16 number of patches per row and per column (pixels)
    image_width = patch_width*grid_size;  % image width (pixels)
    n_regions = 5;          % number of texture regions
    map = zeros(grid_size, grid_size);  % texture label map
    patch_list = zeros(n_regions, round(3*grid_size^2/n_regions) + 1);  % list of patches per region

    % seed the texture label map
    seeds = zeros(n_regions, 2);
    for i_region = 1:n_regions
        seed_repeat = 1;
        while seed_repeat == 1
            seed_repeat = 0;
            x = randi(grid_size);
            y = randi(grid_size);
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
    while min(min(map)) == 0  % fill the image (no background pixels)
        % while sum(patch_list(:,1)) < grid_size^2/6 % some percentage of background pixels
        region_order = randperm(n_regions);  % add to regions in a random order on each pass
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
                side_order = randperm(4);  % check four sides of patch in random order
                i_side = 0;
                while i_side < 4 && is_free == 0
                    i_side = i_side+1;
                    [is_free, x_out, y_out] = grouping.check_tlst(side_order(i_side), ...
                        x, y, map, grid_size);
                end
                if is_free == 1
                    patch_list(jj, 1) = patch_list(jj, 1) + 1;  % move on to next region
                    patch_list(jj, 2*(n_in_region+1)) = x_out;
                    patch_list(jj, 2*(n_in_region+1)+1) = y_out;
                    map(x_out, y_out) = jj;
                end
                kk = kk+1;  % if kk exceeds n_in_region then move on to next region
            end
        end
    end

    figure;
    image(map*256/n_regions-1);
    axis off;
    axis square;
    axis equal;

    % make masks
    trial_masks = zeros(image_width, image_width, n_regions);
    for i_region = 1:n_regions
        for jj = 1:grid_size
            x = (jj-1)*patch_width+1;
            for kk = 1:grid_size
                if map(jj, kk) == i_region
                    y = (kk-1)*patch_width+1;
                    trial_masks(x:x+patch_width-1, y:y+patch_width-1, i_region) = 1;
                end
            end
        end
    end

    % to save compactly: logical_masks = cast(trial_masks,'logical');
    %
    % figure;
    % image(255*trial_masks(:,:,1));
    % axis off;
    % axis square;
    % axis equal;
    % figure;
    % image(255*trial_masks(:,:,n_regions));
    % axis off;
    % axis square;
    % axis equal;

    % create texture region image
    mean_lum = 128;
    contrast = 0.25;
    n_pixels = image_width*image_width;
    tex_nums = [2, 7, 11, 24, 31, 33, 37, 42];
    % tex_nums = [2,4,10,24,37,44,55,56];
    patch_img = zeros(image_width, image_width, 3);
    for i_region = 1:n_regions  % 8
        kk = tex_nums(i_region);
        num_str = num2str(kk);
        img_file = fullfile(cfg.paths.textures, 'brodatz', ...
            append('B', num_str, '.gif'));
        img_in0 = double(imread(img_file));
        img_in = imresize(img_in0, [image_width, image_width], "bilinear");
        % normalize
        img_mean = mean(mean(img_in));
        img_sd = sqrt(sum(sum((img_in-img_mean).^2))/n_pixels);
        img_in = contrast*img_mean*(img_in-img_mean)/img_sd + img_mean;  % normalize to contrast
        img_in = max(img_in, 0)*mean_lum/img_mean;  % normalized to mean of mean_lum
        %
        % img = zeros(640,640,3);
        img = zeros(image_width, image_width, 3);
        img(:,:,1) = img_in;
        img(:,:,2) = img_in;
        img(:,:,3) = img_in;
        img = 255^(1/2.1)*lin2rgb(img, ColorSpace='adobe-rgb-1998');
        patch_img(:,:,1) = patch_img(:,:,1) + img(:,:,1).*trial_masks(:,:,i_region);
        patch_img(:,:,2) = patch_img(:,:,2) + img(:,:,2).*trial_masks(:,:,i_region);
        patch_img(:,:,3) = patch_img(:,:,3) + img(:,:,3).*trial_masks(:,:,i_region);
    end
    figure;
    image(patch_img/255); axis('square');
    axis off;

    % segment GRT image
    % [simg] = s_pimg(pimg,pw,np,ncc);
end
