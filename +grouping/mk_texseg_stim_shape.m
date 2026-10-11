function mk_texseg_stim_shape()
% MK_TEXSEG_STIM_SHAPE  Build and display a session of shape-cue stimuli.
%   grouping.mk_texseg_stim_shape()
%
%   Same texture-region generation as GROUPING.MK_TEXSEG_STIM_POINTS, but the
%   cue is a thumbnail of one region's shape (from GROUPING.SHAPE_CUE) rather
%   than two point markers, and the same/different judgment is between that
%   shape and the region shown in the stimulus rather than between two cued
%   patches. A white or black square in the corner of the feedback image
%   marks the correct answer.
%
%   Inputs
%     none (every parameter is hardcoded below).
%
%   Output
%     none (displays one figure per image, pausing on each).
%
%   Note: like the script it replaces, this closes every open figure first.
%
%   See also GROUPING.MK_TEXSEG_STIM_POINTS, GROUPING.SHAPE_CUE.

    close all;

    % texture-sheet location comes from config(), never from the current folder
    cfg = config();

    block_size = 24;      % block size
    n_blocks = 20;        % number of blocks
    n_trials = block_size*n_blocks;  % number of trials in session
    n_tex = 60;            % number of textures in database
    n_tex_regions = 5;     % number of texture regions
    grid_size = 16;        % image size in patches
    patch_width = 64;      % patch width in pixels
    seed_radius_frac = 0.75;  % texture seed radius as fraction of max
    fill_fraction = 0.5;      % proportion of pixels taken up by texture regions

    % generate random texture numbers for all trials in a session
    % (tex_nums is n_trials x n_tex_regions)
    tex_nums = grouping.mk_texs(n_tex, n_tex_regions, n_trials);

    % generate masks and maps for all trials in a session
    [masks, maps] = grouping.mk_masks(grid_size, n_tex_regions, n_trials, ...
        seed_radius_frac, fill_fraction);

    % make all images for the trials
    image_width = patch_width*grid_size;
    mean_lum = 128;
    contrast = 0.25;
    n_pixels = image_width*image_width;  % c0 = 0.25
    trial_order = randperm(n_trials);
    for i_trial = 1:n_trials
        t = trial_order(i_trial);

        % make cue image for a trial
        cue_img = ones(image_width, image_width, 3)*128;

        % region number of cue
        region = randi(n_tex_regions);

        % same/different flag for current trial
        is_diff = 0;
        if rand() > 0.5
            is_diff = 1;
        end
        if is_diff == 0
            [cue, cue_map] = grouping.shape_cue(maps(1:grid_size, 1:grid_size, t), ...
                grid_size, region);
        else
            [cue, cue_map] = grouping.shape_cue(maps(1:grid_size, 1:grid_size, randi(n_trials)), ...
                grid_size, region);
        end
        figure;
        image(cue/255); axis('square');
        x0 = 900;
        y0 = 100;
        width = 1000;
        height = 1000;
        set(gcf, 'position', [x0, y0, width, height]);
        axis off;
        pause;
        close all;

        % make masks for a trial
        trial_masks = zeros(image_width, image_width, n_tex_regions);
        for ii = 1:n_tex_regions
            for jj = 1:grid_size
                x = (jj-1)*patch_width+1;
                for kk = 1:grid_size
                    if maps(jj, kk, t) == ii
                        y = (kk-1)*patch_width+1;
                        trial_masks(x:x+patch_width-1, y:y+patch_width-1, ii) = 1;
                    end
                end
            end
        end

        % make the texure image for a trial
        patch_img = zeros(image_width, image_width, 3);
        for ii = 1:n_tex_regions
            kk = tex_nums(t, ii);
            num_str = num2str(kk);
            img_file = fullfile(cfg.paths.textures, 'brodatz', ...
                append('B', num_str, '.gif'));
            % num_str = num2str(6);
            % img_file = append('00',num_str,'.png');
            img_in0 = double(imread(img_file));
            img_in = imresize(img_in0, [image_width, image_width], "bilinear");
            % normalize
            img_mean = mean(mean(img_in));
            img_sd = sqrt(sum(sum((img_in-img_mean).^2))/n_pixels);
            img_in = contrast*img_mean*(img_in-img_mean)/img_sd + img_mean;  % normalize to contrast
            img_in = max(img_in, 0)*mean_lum/img_mean;  % normalized to mean of mean_lum
            img = zeros(image_width, image_width, 3);
            img(:,:,1) = img_in;
            img(:,:,2) = img_in;
            img(:,:,3) = img_in;
            img = 255^(1/2.1)*lin2rgb(img, ColorSpace='adobe-rgb-1998');
            patch_img(:,:,1) = patch_img(:,:,1) + img(:,:,1).*trial_masks(:,:,ii);
            patch_img(:,:,2) = patch_img(:,:,2) + img(:,:,2).*trial_masks(:,:,ii);
            patch_img(:,:,3) = patch_img(:,:,3) + img(:,:,3).*trial_masks(:,:,ii);
        end
        trial_mask_sum = zeros(image_width, image_width);
        for ii = 1:n_tex_regions
            trial_mask_sum(:,:) = trial_mask_sum(:,:) + trial_masks(:,:,ii);
        end
        for x = 1:image_width
            for y = 1:image_width
                if trial_mask_sum(x, y) == 0
                    patch_img(x, y, 1) = 128;
                    patch_img(x, y, 2) = 128;
                    patch_img(x, y, 3) = 128;
                end
            end
        end
        figure;
        image(patch_img/255); axis('square');
        x0 = 900;
        y0 = 100;
        width = 1000;
        height = 1000;
        set(gcf, 'position', [x0, y0, width, height]);
        axis off;
        pause;
        close all;

        if is_diff == 0
            patch_img(1:16, 1:16, :) = 255;  % yes cue is present/same
            % patch_img(1:16,1:16,:) = patch_img(1:16,1:16,:).*cue_map; % yes cue is present/same
        else
            patch_img(1:16, 1:16, :) = 0;  % no cue is not present/different
        end
        figure;
        image(patch_img/255); axis('square');
        x0 = 900;
        y0 = 100;
        width = 1000;
        height = 1000;
        set(gcf, 'position', [x0, y0, width, height]);
        axis off;
        pause;
        close all;
    end
end
