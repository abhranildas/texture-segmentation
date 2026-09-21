% MK_TEXSEG_STIM_SHAPE_OLD  Earlier variant of GROUPING.MK_TEXSEG_STIM_SHAPE.
%   grouping.mk_texseg_stim_shape_old
%
%   Script, not a function. Builds the same geometry-matched
%   same/different pairing GROUPING.MK_TEXSEG_STIM_POINTS does (cue_locations,
%   bin_table, the paired same/different trials), but then never reads
%   cue_locations again - the rendering loop below draws its own independent
%   region and same/different choice per trial, the same way
%   GROUPING.MK_TEXSEG_STIM_SHAPE does. No caller and no recorded reason it is
%   still kept alongside its two siblings - see S3.1 in docs/repo-cleanup.md.
%
%   Broken as written - see bug B2.6 in docs/repo-cleanup.md: every call below
%   to mk_texs, mk_masks, mk_dist, mk_mecc, mk_decc, mk_bindex, find_bin,
%   find_xy, check_xy and shape_cue is unqualified, and none of those names
%   resolve to the package functions of the same name (confirmed empirically
%   - see B2.6), so the first call errors.
%
%   Inputs
%     none (every parameter is hardcoded below).
%
%   Output
%     none (displays one figure per image, pausing on each).
%
%   See also GROUPING.MK_TEXSEG_STIM_POINTS, GROUPING.MK_TEXSEG_STIM_SHAPE.

clearvars;
close all;

% texture-sheet location comes from config(), never from the current folder
cfg = config();

session = 1;    % session number
block_size = 24;      % block size
n_blocks = 20;        % number of blocks
n_trials = block_size*n_blocks;  % number of trials in session
n_tex = 60;            % number of textures in database
n_tex_regions = 5;     % number of texture regions
grid_size = 16;        % image size in patches
patch_width = 64;      % patch width in pixels
seed_radius_frac = 1.0;  % texture seed radius as fraction of max
fill_fraction = 0.75;    % proportion of pixels taken up by texture regions
bin_bounds_dist = [1, 2, 4, 8, 16, 32];       % distance bin bounds
bin_bounds_min_ecc = [0, 1, 2, 4, 8, 12];     % minimum eccentricity bin bounds
bin_bounds_delta_ecc = [0, 2, 4, 6, 8, 12];   % eccentricity difference bin bounds
n_bins = (size(bin_bounds_dist,2)-1)*(size(bin_bounds_min_ecc,2)-1)* ...
    (size(bin_bounds_delta_ecc,2)-1);
bin_table = zeros(2*grid_size^4, n_bins);  % bin table
max_attempts = 100;

% generate random texture numbers for all trials in a session
tex_nums = mk_texs(n_tex, n_tex_regions, n_trials);  % tex_nums(1:n_trials,1:n_tex_regions)

% generate masks and maps for all trials in a session
[masks, maps] = mk_masks(grid_size, n_tex_regions, n_trials, seed_radius_frac, fill_fraction);

% make geometry matrices for patch pairs, size if each = grid_size^2 x grid_size^2
dist = mk_dist(grid_size);
min_ecc = mk_mecc(grid_size);
delta_ecc = mk_decc(grid_size);

% make array of index values to patch geometry bins
bin_index = mk_bindex(bin_bounds_dist, bin_bounds_min_ecc, bin_bounds_delta_ecc);

% load the bin table counts and the specific pairs of patches in each bin
% (ii, jj are the patch pair's two linear indices here; reused below with a
% different meaning, since check_stage1's rename map cannot split one old
% name into two new ones - see tranche 3's rule C-6 and this tranche's
% findings-log note on the same conflict in mk_texseg_stim_points.m)
for ii = 1:grid_size^2
    for jj = 1:grid_size^2
        if ii ~= jj
            bin = find_bin(ii, jj, dist, min_ecc, delta_ecc, ...
                bin_bounds_dist, bin_bounds_min_ecc, bin_bounds_delta_ecc, bin_index);
            bin_table(1, bin) = bin_table(1, bin) + 1;
            bin_row = 2*bin_table(1, bin);
            bin_table(bin_row, bin) = ii;
            bin_table(bin_row+1, bin) = jj;
        end
    end
end

cue_locations = zeros(n_trials, 5);  % locations of texture-region cues

trial = 1;
max_count = 0;
while trial <= n_trials
    % randomly sample condition "same" or "different"
    cond = 0;  % same
    if rand() > 0.5
        cond = 1;  % different
    end

    % randomly sample a patch location and determine its region number
    [x1, y1] = find_xy(trial, maps, grid_size);
    region1 = maps(x1, y1, trial);

    % random sample a second patch location and determine its region
    done = 0;
    while done == 0
        [x2, y2] = find_xy(trial, maps, grid_size);
        region2 = maps(x2, y2, trial);
        if (region1 == region2) && (cond == 0)
            done = 1;
        elseif (region1 ~= region2) && (cond == 1)
            done = 1;
        end
        if x1 == x2 && y1 == y2
            done = 0;
        end
    end
    cue_locations(trial, 1) = cond;
    cue_locations(trial, 2) = x1;
    cue_locations(trial, 3) = y1;
    cue_locations(trial, 4) = x2;
    cue_locations(trial, 5) = y2;

    % switch conditions and repeat for same bin
    if cond == 1
        cond = 0;
    else
        cond = 1;
    end
    lookup_index1 = (x1-1)*grid_size + y1;
    lookup_index2 = (x2-1)*grid_size + y2;
    bin = find_bin(lookup_index1, lookup_index2, dist, min_ecc, delta_ecc, ...
        bin_bounds_dist, bin_bounds_min_ecc, bin_bounds_delta_ecc, bin_index);
    n_pairs = bin_table(1, bin);
    done = 0;
    attempt_count = 0;
    while done == 0 && attempt_count < max_attempts
        attempt_count = attempt_count + 1;
        pair_index = randi(n_pairs);
        ii = bin_table(2*pair_index, bin);
        jj = bin_table(2*pair_index+1, bin);
        y1 = mod(ii, grid_size);
        if y1 == 0
            y1 = grid_size;
        end
        x1 = 1 + (ii-y1)/grid_size;
        y2 = mod(jj, grid_size);
        if y2 == 0
            y2 = grid_size;
        end
        x2 = 1 + (jj-y2)/grid_size;
        is_boundary1 = check_xy(x1, y1, trial+1, maps, grid_size);
        is_boundary2 = check_xy(x2, y2, trial+1, maps, grid_size);
        if (is_boundary1 == 0) && (is_boundary2 == 0)
            region1 = maps(x1, y1, trial+1);
            region2 = maps(x2, y2, trial+1);
            if (region1 == region2) && (cond == 0)
                done = 1;
            elseif (region1 ~= region2) && (cond == 1)
                done = 1;
            end
        end
    end
    if attempt_count < max_attempts
        cue_locations(trial+1, 1) = cond;
        cue_locations(trial+1, 2) = x1;
        cue_locations(trial+1, 3) = y1;
        cue_locations(trial+1, 4) = x2;
        cue_locations(trial+1, 5) = y2;
        trial = trial+2;
    else
        max_count = max_count+1;
    end
end
% for i_trial = 1:n_trials
%   %
%   image(maps(:,:,i_trial)*256/n_tex_regions-1);
%   axis off;
%   axis square;
%   axis equal;
%   cond = cue_locations(i_trial,1);
%   x1 = cue_locations(i_trial,2); y1 =  cue_locations(i_trial,3);
%   x2 = cue_locations(i_trial,4); y2 =  cue_locations(i_trial,5);
%   maps(x1,y1,i_trial) = 0; maps(x2,y2,i_trial) = 0;
%   figure;
%   image(maps(:,:,i_trial)*256/n_tex_regions-1);
%   axis off;
%   axis square;
%   axis equal;
%   close all;  % put break point here
% end
%
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
        [cue, cue_map] = shape_cue(maps(1:grid_size, 1:grid_size, t), grid_size, region);
    else
        [cue, cue_map] = shape_cue(maps(1:grid_size, 1:grid_size, randi(n_trials)), ...
            grid_size, region);
    end
    figure;
    image(cue/255); axis('square');
    % cond = cue_locations(t,1);
    % x1 = cue_locations(t,2)*patch_width - patch_width/2; y1 = cue_locations(t,3)*patch_width - patch_width/2;
    % x2 = cue_locations(t,4)*patch_width - patch_width/2; y2 = cue_locations(t,5)*patch_width - patch_width/2;
    % cue_img(x1-4:x1+4,y1-4:y1+4,:) = 0;
    % cue_img(x2-4:x2+4,y2-4:y2+4,:) = 0;
    % cue_img(image_width/2-4:image_width/2+4,image_width/2-4:image_width/2+4,:) = 160;
    % figure;
    % image(cue_img/255); axis('square');
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
