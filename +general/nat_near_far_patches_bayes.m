%NAT_NEAR_FAR_PATCHES_BAYES  Cut near and far patch pairs from natural images.
%   run('+general/nat_near_far_patches_bayes.m')
%
%   For each image in the three CPS natural-image sets (9, 10 and 12), draws
%   n_samples reference patches at random, and for each one builds two patch
%   pairs: a "near" pair, whose second patch abuts the reference (to its right
%   and below it), and a "far" pair, whose second patch is drawn at least
%   dist_min pixels away. Both orientations (right and down) are produced, the
%   down pair by transposing, so each reference patch yields two near pairs and
%   two far pairs. Results are written as three .mat files, one per image set.
%
%   This is a script, not a function: it clears the workspace and hardcodes
%   every parameter below. Converting it into a proper function is Stage 3
%   item S2.5. Every path it reads or writes is built from CONFIG -- with one
%   exception, the two cdfs files of B2.13, which are not in the shared data
%   store and so have no cfg.paths.* home to point at.
%
%   Inputs: none. The parameters are the constants at the top of the file --
%     level           - resolution scale-down factor (1, 2, 4 or 8;
%                       dimensionless)
%     base_patch_size - patch size at level 1 (pixels)
%     patch_size      - patch size at the chosen level (pixels)
%     pair_width      - width of a patch pair, 2*patch_size (pixels)
%     ppd             - pixels per degree
%     pupil_diameter  - pupil diameter (mm), for the optical transfer function
%     wavelength      - wavelength (nm), for the optical transfer function
%     apply_filter    - 1 to apply the optical transfer function, 0 to skip it
%     n_samples       - reference patches drawn per image (count)
%     max_pix_val     - largest pixel value in the 16-bit source images
%
%   Reads the three CPS natural-image sets from cfg.paths.natural_images and
%   the camera RGB->LMS matrix from cfg.paths.data_root (see CONFIG).
%
%   Outputs (three files in cfg.paths.stimuli, one per image set):
%     patch_pairs_9<level>.mat   - ptchn9, ptchf9, pcnt9
%     patch_pairs_10<level>.mat  - ptchn10, ptchf10, pcnt10
%     patch_pairs_12<level>.mat  - ptchn12, ptchf12, pcnt12
%   where ptchn* / ptchf* are patch_size x pair_width x n_channels x count
%   arrays of near / far patch pairs in LMS cone coordinates, and pcnt* is the
%   number of pairs in that set. These variable names are frozen (they appear
%   as save string literals), so the locals feeding them keep their original
%   spelling while every other local is renamed.
%
%   Note: this script still does not run as written. It calls three functions
%   that are not on this repo's path (B2.12), and the two histogram .mat files
%   it loads are not in the shared data store (B2.13). Its image-set-12 slice
%   bounds are also wrong (B1.3). Its data paths, however, are now correct:
%   the two machine-specific addpath calls (B2.3) are gone.
%
%   See also CONFIG, GENERAL.SIMULATE_DISCRIMINATION.

clearvars;
close all;

% All data locations come from config(), never from the current folder or the
% MATLAB path. Two hardcoded addpath calls used to sit here (B2.3): one for
% the natural images, replaced by cfg.paths.natural_images below, and one for
% a "Texture Discrimination Code" folder on the original author's machine,
% which is presumably where aply_otf / rgb2lms / dsmp lived -- repointing
% those three calls is B2.12's job, not a path-routing fix.
cfg = config();

rng(0);  % random number generator seed
% rng('shuffle');

% normalization parameters
cnorm = 1;
m0 = 128;
c0 = 0.25;
ntype = 3;

% optical filter
apply_filter = 1;  % 1 = apply optical filter, 0 = no filter
pupil_diameter = 4;  % pupil diameter (mm)
wavelength = 550;  % wavelength (nm)

base_image_size = 64;
base_patch_size = 64;  % level 1 patch size
level = 1;  % resolution scale-down level (1, 2, 4, 8)
image_size = base_image_size/level;  % image size given level
patch_size = base_patch_size/level;  % patch size given level
pair_width = 2*patch_size;
ppd = 60;  % pixels per degree

% RGB->LMS matrix from the CPS camera calibration (stored in the shared data
% store, ../vislab-common/data)
lms_file = load(fullfile(cfg.paths.data_root, 'cps_rgb2lms.mat'), 'lms');
lms = lms_file.lms;
n_channels = 3;  % number of color channels

% Load color and edge histograms. These two loads are the only data access in
% this file NOT routed through config(), because neither file is in the shared
% data store and there is nothing there to point at (B2.13, searched
% 2026-09-21): cdfs_abr_mo13_mo23_cs33_otf.mat exists only in the ancestral
% ../texture-learning/Bill's old code[ - revised]/ folders, and
% cdfs_abr_mo13_mo23_cs33.mat exists nowhere on this machine at all. Both
% loads are also vestigial as written -- the otf file holds Na, Nb, Nm, No,
% Nmo, Ncs1/2/4, ea, eb, ... and none of those names is read anywhere below.
% Deciding whether these belong in the shared store, and under what name, is
% B2.13's call; it is not a path-routing fix.
if apply_filter == 0
    load("cdfs_abr_mo13_mo23_cs33.mat");  % natural image cdfs
elseif apply_filter == 1
    load("cdfs_abr_mo13_mo23_cs33_otf.mat");  % natural image cdfs
end

% number and size of natural images
n_img9 = 104;
n_img10 = 90;
n_img12 = 197;
show_img = 0;
max_pix_val = 2^14 - 1;  % maximum pixel value

% number of patch pairs and storage
n_samples = 10;  % number of reference patches per image
n_pairs = (n_img9 + n_img10 + n_img12)*n_samples*2;
patches_near = zeros(patch_size, pair_width, n_channels, n_pairs);
patches_far = zeros(patch_size, pair_width, n_channels, n_pairs);
patch_count = 0;

% image set 9
for i_img = 1:n_img9
    num_str = num2str(i_img);

    % load rgb image
    file_name = fullfile(cfg.paths.natural_images, append('Set9_16_', num_str, '.png'));
    img_rgb = double(imread(file_name))*255/max_pix_val;
    if apply_filter == 1
        img_rgb = aply_otf(img_rgb, ppd, pupil_diameter, wavelength);  % apply otf
    end
    img_lms = rgb2lms(img_rgb, lms);
    img_lms = dsmp(img_lms, level, n_channels);  % downsample
    [size_x, size_y] = size(img_lms(:, :, 1));
    dist_min = size_x/4;

    % get samples from current image
    for i_sample = 1:n_samples
        x = randi(size_x - pair_width);  y = randi(size_y - pair_width);
        patch_ref = img_lms(x:x+patch_size-1, y:y+patch_size-1, :);  % reference patch

        % near patch right
        patch_count = patch_count + 1;
        patches_near(1:patch_size, 1:patch_size, 1:n_channels, patch_count) = patch_ref;
        patch_second = img_lms(x:x+patch_size-1, y+patch_size:y+pair_width-1, :);
        patches_near(1:patch_size, patch_size+1:pair_width, 1:n_channels, ...
            patch_count) = patch_second;

        % far patch right
        is_far = 0;
        while is_far == 0
            x_far = randi(size_x - pair_width);  y_far = randi(size_y - pair_width);
            dist_near_far = sqrt((x_far - x)^2 + (y_far - y)^2);
            if dist_near_far > dist_min
                is_far = 1;
            end
        end
        patches_far(1:patch_size, 1:patch_size, 1:n_channels, patch_count) = patch_ref;
        patch_second = img_lms(x_far:x_far+patch_size-1, y_far+patch_size:y_far+pair_width-1, :);
        patches_far(1:patch_size, patch_size+1:pair_width, 1:n_channels, ...
            patch_count) = patch_second;

        % transpose reference patch
        patch_ref_transposed = patch_ref;
        patch_ref_transposed(:, :, 1) = patch_ref_transposed(:, :, 1).';
        patch_ref_transposed(:, :, 2) = patch_ref_transposed(:, :, 2).';
        patch_ref_transposed(:, :, 3) = patch_ref_transposed(:, :, 3).';

        % near patch down
        patch_count = patch_count + 1;
        patches_near(1:patch_size, 1:patch_size, 1:n_channels, patch_count) = patch_ref_transposed;
        patch_second = img_lms(x+patch_size:x+pair_width-1, y:y+patch_size-1, :);
        patch_second(:, :, 1) = patch_second(:, :, 1).';
        patch_second(:, :, 2) = patch_second(:, :, 2).';
        patch_second(:, :, 3) = patch_second(:, :, 3).';
        patches_near(1:patch_size, patch_size+1:pair_width, 1:n_channels, ...
            patch_count) = patch_second;

        % far patch down
        is_far = 0;
        while is_far == 0
            x_far = randi(size_x - pair_width);  y_far = randi(size_y - pair_width);
            dist_near_far = sqrt((x_far - x)^2 + (y_far - y)^2);
            if dist_near_far > dist_min
                is_far = 1;
            end
        end
        patches_far(1:patch_size, 1:patch_size, 1:n_channels, patch_count) = patch_ref_transposed;
        patch_second = img_lms(x_far:x_far+patch_size-1, y_far+patch_size:y_far+pair_width-1, :);
        patch_second(:, :, 1) = patch_second(:, :, 1).';
        patch_second(:, :, 2) = patch_second(:, :, 2).';
        patch_second(:, :, 3) = patch_second(:, :, 3).';
        patches_far(1:patch_size, patch_size+1:pair_width, 1:n_channels, ...
            patch_count) = patch_second;
    end
end
ptchn9 = patches_near(1:patch_size, 1:pair_width, 1:n_channels, 1:patch_count);
ptchf9 = patches_far(1:patch_size, 1:pair_width, 1:n_channels, 1:patch_count);
pcnt9 = patch_count;
num_str = num2str(level);
file_name = fullfile(cfg.paths.stimuli, append('patch_pairs_9', num_str, '.mat'));
save(file_name, "ptchn9", "ptchf9", "pcnt9");

% image set 10
for i_img = 1:n_img10
    num_str = num2str(i_img);

    % load rgb image
    file_name = fullfile(cfg.paths.natural_images, append('Set10_16_', num_str, '.png'));
    img_rgb = double(imread(file_name))*255/max_pix_val;
    if apply_filter == 1
        img_rgb = aply_otf(img_rgb, ppd, pupil_diameter, wavelength);  % apply otf
    end
    img_lms = rgb2lms(img_rgb, lms);
    img_lms = dsmp(img_lms, level, n_channels);  % downsample

    % get samples from current image
    for i_sample = 1:n_samples
        x = randi(size_x - pair_width);  y = randi(size_y - pair_width);
        patch_ref = img_lms(x:x+patch_size-1, y:y+patch_size-1, :);  % reference patch

        % near patch right
        patch_count = patch_count + 1;
        patches_near(1:patch_size, 1:patch_size, 1:n_channels, patch_count) = patch_ref;
        patch_second = img_lms(x:x+patch_size-1, y+patch_size:y+pair_width-1, :);
        patches_near(1:patch_size, patch_size+1:pair_width, 1:n_channels, ...
            patch_count) = patch_second;

        % far patch right
        is_far = 0;
        while is_far == 0
            x_far = randi(size_x - pair_width);  y_far = randi(size_y - pair_width);
            dist_near_far = sqrt((x_far - x)^2 + (y_far - y)^2);
            if dist_near_far > dist_min
                is_far = 1;
            end
        end
        patches_far(1:patch_size, 1:patch_size, 1:n_channels, patch_count) = patch_ref;
        patch_second = img_lms(x_far:x_far+patch_size-1, y_far+patch_size:y_far+pair_width-1, :);
        patches_far(1:patch_size, patch_size+1:pair_width, 1:n_channels, ...
            patch_count) = patch_second;

        % transpose reference patch
        patch_ref_transposed = patch_ref;
        patch_ref_transposed(:, :, 1) = patch_ref_transposed(:, :, 1).';
        patch_ref_transposed(:, :, 2) = patch_ref_transposed(:, :, 2).';
        patch_ref_transposed(:, :, 3) = patch_ref_transposed(:, :, 3).';

        % near patch down
        patch_count = patch_count + 1;
        patches_near(1:patch_size, 1:patch_size, 1:n_channels, patch_count) = patch_ref_transposed;
        patch_second = img_lms(x+patch_size:x+pair_width-1, y:y+patch_size-1, :);
        patch_second(:, :, 1) = patch_second(:, :, 1).';
        patch_second(:, :, 2) = patch_second(:, :, 2).';
        patch_second(:, :, 3) = patch_second(:, :, 3).';
        patches_near(1:patch_size, patch_size+1:pair_width, 1:n_channels, ...
            patch_count) = patch_second;

        % far patch down
        is_far = 0;
        while is_far == 0
            x_far = randi(size_x - pair_width);  y_far = randi(size_y - pair_width);
            dist_near_far = sqrt((x_far - x)^2 + (y_far - y)^2);
            if dist_near_far > dist_min
                is_far = 1;
            end
        end
        patches_far(1:patch_size, 1:patch_size, 1:n_channels, patch_count) = patch_ref_transposed;
        patch_second = img_lms(x_far:x_far+patch_size-1, y_far+patch_size:y_far+pair_width-1, :);
        patch_second(:, :, 1) = patch_second(:, :, 1).';
        patch_second(:, :, 2) = patch_second(:, :, 2).';
        patch_second(:, :, 3) = patch_second(:, :, 3).';
        patches_far(1:patch_size, patch_size+1:pair_width, 1:n_channels, ...
            patch_count) = patch_second;
    end
end
ptchn10 = patches_near(1:patch_size, 1:pair_width, 1:n_channels, pcnt9+1:patch_count);
ptchf10 = patches_far(1:patch_size, 1:pair_width, 1:n_channels, pcnt9+1:patch_count);
pcnt10 = patch_count - pcnt9;
num_str = num2str(level);
file_name = fullfile(cfg.paths.stimuli, append('patch_pairs_10', num_str, '.mat'));
save(file_name, "ptchn10", "ptchf10", "pcnt10");

% image set 12
for i_img = 1:n_img12
    num_str = num2str(i_img);

    % load rgb image
    file_name = fullfile(cfg.paths.natural_images, append('Set12_16_', num_str, '.png'));
    img_rgb = double(imread(file_name))*255/max_pix_val;
    if apply_filter == 1
        img_rgb = aply_otf(img_rgb, ppd, pupil_diameter, wavelength);  % apply otf
    end
    img_lms = rgb2lms(img_rgb, lms);
    img_lms = dsmp(img_lms, level, n_channels);  % downsample

    % get samples from current image
    for i_sample = 1:n_samples
        x = randi(size_x - pair_width);  y = randi(size_y - pair_width);
        patch_ref = img_lms(x:x+patch_size-1, y:y+patch_size-1, :);  % reference patch

        % near patch right
        patch_count = patch_count + 1;
        patches_near(1:patch_size, 1:patch_size, 1:n_channels, patch_count) = patch_ref;
        patch_second = img_lms(x:x+patch_size-1, y+patch_size:y+pair_width-1, :);
        patches_near(1:patch_size, patch_size+1:pair_width, 1:n_channels, ...
            patch_count) = patch_second;

        % far patch right
        is_far = 0;
        while is_far == 0
            x_far = randi(size_x - pair_width);  y_far = randi(size_y - pair_width);
            dist_near_far = sqrt((x_far - x)^2 + (y_far - y)^2);
            if dist_near_far > dist_min
                is_far = 1;
            end
        end
        patches_far(1:patch_size, 1:patch_size, 1:n_channels, patch_count) = patch_ref;
        patch_second = img_lms(x_far:x_far+patch_size-1, y_far+patch_size:y_far+pair_width-1, :);
        patches_far(1:patch_size, patch_size+1:pair_width, 1:n_channels, ...
            patch_count) = patch_second;

        % transpose reference patch
        patch_ref_transposed = patch_ref;
        patch_ref_transposed(:, :, 1) = patch_ref_transposed(:, :, 1).';
        patch_ref_transposed(:, :, 2) = patch_ref_transposed(:, :, 2).';
        patch_ref_transposed(:, :, 3) = patch_ref_transposed(:, :, 3).';

        % near patch down
        patch_count = patch_count + 1;
        patches_near(1:patch_size, 1:patch_size, 1:n_channels, patch_count) = patch_ref_transposed;
        patch_second = img_lms(x+patch_size:x+pair_width-1, y:y+patch_size-1, :);
        patch_second(:, :, 1) = patch_second(:, :, 1).';
        patch_second(:, :, 2) = patch_second(:, :, 2).';
        patch_second(:, :, 3) = patch_second(:, :, 3).';
        patches_near(1:patch_size, patch_size+1:pair_width, 1:n_channels, ...
            patch_count) = patch_second;

        % far patch down
        is_far = 0;
        while is_far == 0
            x_far = randi(size_x - pair_width);  y_far = randi(size_y - pair_width);
            dist_near_far = sqrt((x_far - x)^2 + (y_far - y)^2);
            if dist_near_far > dist_min
                is_far = 1;
            end
        end
        patches_far(1:patch_size, 1:patch_size, 1:n_channels, patch_count) = patch_ref_transposed;
        patch_second = img_lms(x_far:x_far+patch_size-1, y_far+patch_size:y_far+pair_width-1, :);
        patch_second(:, :, 1) = patch_second(:, :, 1).';
        patch_second(:, :, 2) = patch_second(:, :, 2).';
        patch_second(:, :, 3) = patch_second(:, :, 3).';
        patches_far(1:patch_size, patch_size+1:pair_width, 1:n_channels, ...
            patch_count) = patch_second;
    end
end
ptchn12 = patches_near(1:patch_size, 1:pair_width, 1:n_channels, pcnt10+1:patch_count);
ptchf12 = patches_far(1:patch_size, 1:pair_width, 1:n_channels, pcnt10+1:patch_count);
pcnt12 = patch_count - pcnt10;
num_str = num2str(level);
file_name = fullfile(cfg.paths.stimuli, append('patch_pairs_12', num_str, '.mat'));
save(file_name, "ptchn12", "ptchf12", "pcnt12");
