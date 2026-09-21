function [condition, cue_img, tex_img, feedback_img] = mk_trl_points(trial, ...
    grid_size, patch_width, mean_lum, tex_set, contrast, cue_locations, tex_nums, maps)
% MK_TRL_POINTS  Build the cue, stimulus and feedback images for one trial.
%   [condition, cue_img, tex_img, feedback_img] = grouping.mk_trl_points(trial, ...
%       grid_size, patch_width, mean_lum, tex_set, contrast, cue_locations, ...
%       tex_nums, maps)
%
%   Point-cue variant of the texture-segmentation task: cue_img marks the two
%   cued patch centers with a small dark square, tex_img is built by loading
%   and normalizing one texture per region and pasting it into that region's
%   mask, and feedback_img repeats the two dark squares on the finished
%   texture image. GROUPING.MK_TEXSEG_SESSION supplies trial, cue_locations
%   and tex_nums; this is called once per trial, not once per session.
%
%   Inputs
%     trial         - trial number, indexing rows of cue_locations and
%                     tex_nums and the third dimension of maps.
%     grid_size     - side length of the square patch grid, as an integer
%                     count of patches (not pixels).
%     patch_width   - patch width, in pixels.
%     mean_lum      - target mean luminance the texture image is normalized
%                     to.
%     tex_set       - which texture database to draw from: 'brodatz',
%                     'fabric', or 'pertex'. The sheets are read from that
%                     subfolder of cfg.paths.textures (see CONFIG).
%     contrast      - target RMS contrast the texture image is normalized to,
%                     as a fraction of mean_lum.
%     cue_locations - n_trials by 5 array from GROUPING.MK_TEXSEG_SESSION:
%                     column 1 is the same/different condition, columns 2-3
%                     and 4-5 are the two cued patches' (x, y) locations.
%     tex_nums      - n_trials by n_tex_regions array of texture numbers, from
%                     GROUPING.MK_TEXS.
%     maps          - grid_size by grid_size by n_trials array of
%                     texture-region labels, from GROUPING.MK_MASKS.
%
%   Outputs
%     condition    - this trial's same/different condition, copied from
%                    cue_locations(trial, 1).
%     cue_img      - image_width by image_width cue image: mid-gray, with the
%                    two cued patch centers marked dark and the image center
%                    marked light.
%     tex_img      - image_width by image_width composite texture image, one
%                    normalized texture per region.
%     feedback_img - tex_img with the two cued patch centers marked dark.
%
%   See also CONFIG, GROUPING.MK_TEXSEG_SESSION, GROUPING.MK_TEXS,
%   GROUPING.MK_MASKS.

    % make cue image for a trial
    image_width = grid_size*patch_width;
    n_pixels = image_width*image_width;
    cue_img = ones(image_width, image_width)*128;
    condition = cue_locations(trial, 1);
    x1 = cue_locations(trial, 2)*patch_width - patch_width/2;
    y1 = cue_locations(trial, 3)*patch_width - patch_width/2;
    x2 = cue_locations(trial, 4)*patch_width - patch_width/2;
    y2 = cue_locations(trial, 5)*patch_width - patch_width/2;
    cue_img(x1-4:x1+4, y1-4:y1+4, :) = 0;
    cue_img(x2-4:x2+4, y2-4:y2+4, :) = 0;
    cue_img(image_width/2-4:image_width/2+4, image_width/2-4:image_width/2+4, :) = 160;

    % make masks for a trial
    [~, n_tex_regions] = size(tex_nums);
    masks = zeros(image_width, image_width, n_tex_regions);
    for i_region = 1:n_tex_regions
        for i_row = 1:grid_size
            x = (i_row-1)*patch_width+1;
            for i_col = 1:grid_size
                if maps(i_row, i_col, trial) == i_region
                    y = (i_col-1)*patch_width+1;
                    masks(x:x+patch_width-1, y:y+patch_width-1, i_region) = 1;
                end
            end
        end
    end

    % make the texture image for a trial; the sheets live in the shared data
    % store, located by config() rather than by a relative string against the
    % current folder
    cfg = config();
    tex_img = zeros(image_width, image_width);
    for i_region = 1:n_tex_regions
        tex_num = tex_nums(trial, i_region);
        if strcmpi(tex_set, 'brodatz')
            img_file = fullfile(cfg.paths.textures, 'brodatz', ...
                ['B' num2str(tex_num) '.gif']);
            img_in = double(imread(img_file));
        elseif strcmpi(tex_set, 'fabric')
            img_file = fullfile(cfg.paths.textures, 'fabric', ...
                ['FC' num2str(tex_num) '.png']);
            img_in = double(rgb2gray(imread(img_file)));
        elseif strcmpi(tex_set, 'pertex')
            img_file = fullfile(cfg.paths.textures, 'pertex', ...
                sprintf('%03d.png', tex_num));
            img_in = double(imread(img_file));
        end

        % resize image if necessary
        if size(img_in, 1) ~= image_width
            img_in = imresize(img_in, [image_width, image_width], "bilinear");
        end

        % normalize
        img_mean = mean(mean(img_in));
        img_sd = sqrt(sum(sum((img_in-img_mean).^2))/n_pixels);
        img_in = contrast*img_mean*(img_in-img_mean)/img_sd + img_mean;  % normalize to contrast
        img_in = max(img_in, 0)*mean_lum/img_mean;  % normalize to mean_lum
        tex_img(:,:) = tex_img(:,:) + img_in(:,:).*masks(:,:,i_region);
    end

    % feedback img
    feedback_img = tex_img;
    feedback_img(x1-4:x1+4, y1-4:y1+4, :) = 0;
    feedback_img(x2-4:x2+4, y2-4:y2+4, :) = 0;
end
