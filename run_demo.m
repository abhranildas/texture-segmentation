% RUN_DEMO  Short demonstration of the texture-segmentation model.
%
%   Run it (from anywhere):   >> run <path-to-repo>/run_demo.m
%   or:   >> cd <repo>; setup; run run_demo.m
%
%   This is a script, not a function: it takes no arguments, asks no questions,
%   and leaves its results in the base workspace and in seven figure windows.
%   Most of it runs in well under a minute; part 2 additionally reads 40 of
%   the sibling vislab-common repo's calibrated natural images (~50 MB each)
%   for its color-pixel priors, adding its own read-and-filter time on top.
%   The Brodatz sheets setup clones automatically; the ~19 GB natural image
%   set (vislab-common/data/CPS natural images) is the one part of that
%   shared data store this demo needs, and setup does NOT fetch it
%   automatically -- see setup.m.
%
% What it does, in seven parts:
%   1. Grown texture regions. Rebuilds the layout of Figure 1 of the lab's
%      manuscript (notes/Texture paper biorxiv.pdf): three images of five
%      grown Brodatz texture regions each, above their ground-truth region
%      maps, above the model's OWN segmentation of each image (segment_scene,
%      the same grouping pipeline part 6 runs at full-scene scale). Each image
%      grows a patch grid into contiguous regions with grouping.mk_masks,
%      assigns a texture to each region with grouping.mk_texs, and draws one
%      continuous texture sample per region (lib.texture_patch, masked to the
%      region's shape) -- so a region's texture flows continuously across it,
%      rather than being resampled patch by patch.
%   2. Feature priors. Rebuilds all of the manuscript's Figure 5: panels A-C,
%      the marginal histograms of the LMS cone pixel values (A) and the ABR
%      opponent-channel pixel values (B), and the ABR channels' cumulative
%      distributions (C), measured over patches of real natural images; and
%      panels D-F, the cumulative
%      distributions of the model's low-level feature responses
%      (steerable-filter magnitude and orientation, center-surround, and power
%      at a fixed spatial frequency), measured here over Brodatz patches
%      (vislab.nat_stat_bayes.edge_features, spot_features, power_spectrum)
%      rather than over the paper's natural images, as in the sibling
%      texture-learning repo's own achromatic feature priors.
%   3. Decision bound. Rebuilds panel A of the manuscript's Figure 6: the
%      power/spot/edge decision variables behind the published figure
%      (data/model/all_cues.mat), plotted against each other, with the optimal
%      bound between the same- and different-texture pairs fitted and drawn by
%      classify_normals.
%   4. Forming the final decision variable. Unpacks part 3's single 3D fit
%      into the response cloud with its boundary, each cue's proportional
%      contribution to d' (classify_normals' d_con), and the resulting 1D
%      separation of same- vs different-texture pairs once power, spot and
%      edge combine into one number -- the sibling texture-learning repo's
%      own DV-construction figures (demo/plot_stage5.m, plot_dcon_bar.m),
%      adapted to this model's single combination step.
%   5. Region-growing parameters. Rebuilds five of the six panels of the
%      manuscript's Figure 9: the same region-growing run at three region
%      counts, two block sizes, and one partial-coverage, center-biased
%      setting.
%   6. Full-scene grouping. Builds one 1024x1024 scene of 16 Brodatz regions,
%      splits it into a 16x16 grid of patches, and runs the actual grouping
%      pipeline end to end (segment_scene, the same pipeline part 1 uses at
%      smaller scale): the power and histogram decision variables over every
%      ordered pair of patches, combined by a fitted quadratic boundary
%      (data/model/brodatz_boundary.mat) into one decision variable per pair,
%      thresholded into links, and merged into regions by how many links each
%      linked pair shares (grouping.thresh, grouping.nlsame). Shows the scene
%      next to the region map the grouping found.
%   7. Human discrimination accuracy vs eccentricity. Rebuilds the human half
%      of the manuscript's Figure 6B: same-different discrimination accuracy
%      averaged across the real "separated task" subject files
%      (exp_files/sep/subject_out/*.mat), via general.compute_exp_error_mat.
%      No model predictions are overlaid -- see docs/repo-cleanup.md section
%      0.7 for what that would need.
%
%   It does NOT run the Psychtoolbox experiments (+experiment, which need a
%   live display and a subject) or any of the natural-image analyses in
%   +general beyond part 7's subject-data summary. See the README for those.
%
%   Reproducible: everything is drawn under rng(cfg.seed), and every call to
%   lib.texture_patch is given an explicit seed, so repeated runs give
%   identical numbers and identical images.
%
% See also SETUP, CONFIG, LIB.TEXTURE_PATCH, VISLAB.NAT_STAT_BAYES.DV_POWER,
%   LIB.HIST_DV, GROUPING.MK_MASKS, GROUPING.MK_TEXS,
%   VISLAB.NAT_STAT_BAYES.EDGE_FEATURES, VISLAB.NAT_STAT_BAYES.SPOT_FEATURES,
%   VISLAB.NAT_STAT_BAYES.POWER_SPECTRUM, VISLAB.NAT_STAT_BAYES.SOURCE_TO_LMS,
%   VISLAB.LIB.PTCH_NORM, VISLAB.NAT_STAT_BAYES.APPLY_COLOR_ROTATION,
%   CLASSIFY_NORMALS, GROUPING.MK_WIN,
%   GROUPING.THRESH, GROUPING.NLSAME, GENERAL.COMPUTE_EXP_ERROR_MAT

% --- locate the repo and set up the path ---
repo_root = fileparts(mfilename('fullpath'));
cd(repo_root);
setup;
cfg = config();

% Dock all demo figures into one window. Works in the classic MATLAB desktop.
% (In R2025a's new desktop this docks to the desktop rather than a figure
% container, and programmatic docking is limited -- use the figure window's
% dock button if it doesn't take.) Skipped in headless `matlab -batch` runs,
% where there is no desktop to dock into.
if ~batchStartupOptionUsed
    set(0, 'defaultfigurewindowstyle', 'docked');
end

fprintf('\n=== texture-segmentation demo ===\n');
fprintf('Texture sheets: %s\n', fullfile(cfg.paths.textures, 'brodatz'));

% --- parameters shared across parts -----------------------------------------
patch_size = [64 64];            % pixels; the Brodatz/natural-image patch size used throughout
n_textures = 60;                 % Brodatz sheets B1..B60
% RMS contrast for every lib.texture_patch call below, a little under its own
% 0.2 default: a few Brodatz sheets have heavy enough luminance tails that 0.2
% clips a fraction of a percent of their pixels, and the resulting warnings
% would bury the demo's actual output.
patch_contrast = 0.12;
noise_const = 10;                % dv_power's spectral noise-suppression constant

%% --- 1. grown texture region images, as in the paper's Figure 1 ------------
% Figure 1 of the lab's manuscript (notes/Texture paper biorxiv.pdf, p. 2) shows
% three grown texture region (GTR) images, each made of five randomly shaped
% regions filled with Brodatz textures, above their ground-truth region maps.
% grouping.mk_masks grows a patch grid into contiguous regions; grouping.mk_texs
% assigns a texture to each region; fill_regions below draws one continuous
% texture sample per region and masks it to the region's shape, so a region's
% texture flows continuously across it rather than being resampled patch by
% patch. The paper's images are 640x640 pixels of 64-pixel blocks, so a 10x10
% grid of blocks; the blocks here are kept at 32 pixels so this stays fast.
% A third row below the ground truth shows what the actual grouping pipeline
% (segment_scene, also used by part 6 at full-scene scale) finds when it
% segments each image itself.
seed_radius_frac = 0.8;          % region seeds drawn from this fraction of the grid
fill_fraction = 1.0;             % grow until no patch is left unlabelled
region_patch_size = [32 32];     % pixels per patch, kept small so this is fast
gtr_grid_size = 10;              % blocks per side, as in the paper's figure
gtr_n_regions = 5;               % regions per image, as in the paper's figure
gtr_n_images = 3;                % images side by side, as in the paper's figure

fprintf('--- 1. Growing %d images of %d texture regions each (paper Figure 1) ---\n', ...
    gtr_n_images, gtr_n_regions);

rng(cfg.seed);
[~, gtr_maps] = grouping.mk_masks(gtr_grid_size, gtr_n_regions, gtr_n_images, ...
    seed_radius_frac, fill_fraction);
gtr_tex = grouping.mk_texs(n_textures, gtr_n_regions, gtr_n_images);

% each image continues the running seed cursor, so no seed is reused across
% images or parts
seed_cursor = 1;
gtr_images = cell(1, gtr_n_images);
for i_image = 1:gtr_n_images
    [gtr_images{i_image}, seed_cursor] = fill_regions(gtr_maps(:, :, i_image), ...
        gtr_tex(i_image, :), region_patch_size, patch_contrast, seed_cursor);
    fprintf('    image %d uses Brodatz sheets: %s\n', i_image, ...
        sheet_names(gtr_tex(i_image, :)));
end

% --- segment each image with the real grouping pipeline (segment_scene) ----
% segment_scene and the shared constants below are reused by part 6's
% full-scene run, so the segmentation logic exists in exactly one place.
% It needs raw Brodatz-pixel patches (fill_regions_raw), not the
% normalized-[0,1]-luminance patches drawn above for display: the fitted
% boundary was fit on the former, as part 6's own scene construction is.
link_criterion = 15;      % decision variable a pair must exceed to be linked
group_criterion = 0.5;    % shared-link fraction two linked patches must exceed
bin_width = 4;            % gray levels per histogram bin, a power of 2
hist_edges = (0:256/bin_width)*bin_width;
brodatz_bd = load(fullfile(cfg.paths.model, 'brodatz_boundary.mat')).brodatz_bd;
gtr_win = grouping.mk_win(region_patch_size(1), region_patch_size(1)/2, 2);

rng(cfg.seed);
gtr_seg_maps = zeros(gtr_grid_size*region_patch_size(1), gtr_grid_size*region_patch_size(2), gtr_n_images);
gtr_n_found = zeros(1, gtr_n_images);
for i_image = 1:gtr_n_images
    raw_scene = fill_regions_raw(gtr_maps(:, :, i_image), gtr_tex(i_image, :), ...
        region_patch_size, cfg);
    [gtr_seg_maps(:, :, i_image), gtr_n_found(i_image)] = segment_scene(raw_scene, ...
        region_patch_size(1), gtr_win, hist_edges, brodatz_bd, noise_const, ...
        link_criterion, group_criterion);
    fprintf('    image %d: model found %d regions (%d ground truth)\n', ...
        i_image, gtr_n_found(i_image), gtr_n_regions);
end

% Each row is labeled once, in its own dedicated column of label-only tiles
% (the same technique as the feature-priors figure's row letters), rather
% than a title repeated on every tile.
row_labels = {'texture image', 'ground truth', 'model segmentation'};
n_cols = gtr_n_images + 1;
row_label_tile = @(r) (r-1)*n_cols + 1;
img_tile = @(r, k) (r-1)*n_cols + 1 + k;

figure('Name', 'Demo 1: grown texture region images (paper Figure 1)');
tiledlayout(3, n_cols, 'TileSpacing', 'compact');
show_row_label(row_label_tile(1), row_labels{1});
for i_image = 1:gtr_n_images
    show_patch(gtr_images{i_image}, '', img_tile(1, i_image));
end
show_row_label(row_label_tile(2), row_labels{2});
for i_image = 1:gtr_n_images
    show_regions(gtr_maps(:, :, i_image), gtr_n_regions, '', img_tile(2, i_image));
end
show_row_label(row_label_tile(3), row_labels{3});
for i_image = 1:gtr_n_images
    show_regions(gtr_seg_maps(:, :, i_image), max(gtr_n_found(i_image), gtr_n_regions), ...
        '', img_tile(3, i_image));
end
drawnow;

%% --- 2. feature-response priors, as in the paper's Figure 5 ----------------
% Figure 5 of the manuscript (p. 7) shows the model's task-independent priors,
% pooled over patches from 391 calibrated natural images:
%   A. marginal histograms of the LMS cone pixel values (L, M, S).
%   B. marginal histograms of the ABR opponent-channel pixel values
%      (achromatic, blue-yellow, red-green), after the shared LMS->ABR
%      rotation (vislab.nat_stat_bayes.apply_color_rotation).
%   C. the same three ABR channels as B, as cumulative distributions.
% A-C need real natural-image patches -- Brodatz is grayscale and cannot stand
% in for them.
%   D. 1st-derivative steerable filter: magnitude, orientation, and their product.
%   E. 2nd-derivative steerable filter: the same three.
%   F. small (3x3) and large (5x5) center-surround responses, and the power at
%      a fixed spatial frequency.
% D-F are pooled over 160 fresh Brodatz patches instead, as in the sibling
% texture-learning repo's own achromatic feature priors.
prior_mean = 128;                % gray levels
prior_contrast = 0.25;           % RMS contrast, as a fraction of the mean
filter_sd = 1;                   % steerable-filter Gaussian SD, pixels
filter_nsd = 3;                  % kernel width in SDs: 1*3 gives the paper's 3x3 filters
% feature numbering of vislab.nat_stat_bayes.edge_features and spot_features
steerable_features = [5 6 7 9 10 11];  % 1st-derivative m, o, m x o; then 2nd
cs_features = [13 14];           % 3x3 and 5x5 linear center-surround
feature_flags = zeros(1, 14);
feature_flags([steerable_features cs_features]) = 1;
n_prior_patches = 160;           % Brodatz patches pooled for panels D-F
% The panel-F power prior is a statement about one frequency of one texture:
% across patches of the same sheet, the power at a fixed frequency is close to
% exponentially distributed. So it is measured on its own set of patches, all
% from one sheet, each frequency's power divided by its mean across them.
n_power_patches = 40;

rng(cfg.seed);
prior_tex = randi(n_textures, n_prior_patches, 1);
power_tex = randi(n_textures);
prior_patches = cell(n_prior_patches, 1);
for i_patch = 1:n_prior_patches
    prior_patches{i_patch} = lib.texture_patch('tex_num', prior_tex(i_patch), ...
        'patch_size', patch_size, 'seed', i_patch, 'contrast', patch_contrast);
end

fprintf('--- 2. Measuring feature-response distributions (paper Figure 5, A-F) ---\n');

% --- A-C: pixel priors over real natural-image patches ---------------------
% A: marginal histograms of the LMS cone pixel values. B: marginal histograms
% of the ABR opponent-channel pixel values (achromatic, blue-yellow, red-green)
% after the shared LMS->ABR rotation. C: the same ABR values as B, as CDFs.
% vislab.lib.ptch_norm (mean-normalize) and vislab.nat_stat_bayes.
% apply_color_rotation (LMS->ABR rotate) -- the exact two steps patch_to_abr
% chains -- and vislab.nat_stat_bayes.source_to_lms (image ingestion) are the
% same primitives texture-learning's own natural-prior pipeline (pipeline/
% sample_prior_features.m, finalize_priors.m) is built from, so this draws on
% shared vislab-common code rather than re-deriving it; nothing is duplicated
% from that pipeline.
% texture-learning's own prior measurement (config.m: natural.target_isolated_patches)
% pools 7820 patches, spread one-per-image over all 391 natural images -- reading
% all 391 full-resolution (~50 MB each) images here would blow this demo's runtime
% budget, so the same total patch count is instead drawn from n_natural_images
% images, more patches per image.
n_natural_images = 40;                                    % images to read
n_natural_total_patches = 7820;                            % matches texture-learning's target
n_natural_patches = ceil(n_natural_total_patches / n_natural_images);  % patches per image

fprintf('    reading %d of the 391 natural images, %d patches each ', ...
    n_natural_images, n_natural_patches);
fprintf('(%d patches total, matching texture-learning''s natural-prior count)\n', ...
    n_natural_images * n_natural_patches);

rng(cfg.seed);
natural_files = dir(fullfile(cfg.paths.natural_images, '*.png'));
natural_order = randperm(numel(natural_files), n_natural_images);
n_natural_pixels = n_natural_images * n_natural_patches * prod(patch_size);
pixels_l = zeros(n_natural_pixels, 1);
pixels_m = zeros(n_natural_pixels, 1);
pixels_s = zeros(n_natural_pixels, 1);
pixels_a = zeros(n_natural_pixels, 1);
pixels_b = zeros(n_natural_pixels, 1);
pixels_r = zeros(n_natural_pixels, 1);
n_pixels_so_far = 0;
for i_image = 1:n_natural_images
    file = fullfile(natural_files(natural_order(i_image)).folder, ...
        natural_files(natural_order(i_image)).name);
    img_lms = vislab.nat_stat_bayes.source_to_lms(file, cfg, ...
        struct('prescale', 255/cfg.natural.max_val));
    [n_rows, n_cols, ~] = size(img_lms);
    for i_patch = 1:n_natural_patches
        row0 = randi(n_rows - patch_size(1));
        col0 = randi(n_cols - patch_size(2));
        patch_lms = img_lms(row0:row0+patch_size(1)-1, col0:col0+patch_size(2)-1, :);
        norm_lms = vislab.lib.ptch_norm(patch_lms, prior_mean, prior_contrast, 3, 3);
        abr = vislab.nat_stat_bayes.apply_color_rotation(norm_lms);
        idx = n_pixels_so_far + (1:prod(patch_size));
        pixels_l(idx) = reshape(norm_lms(:, :, 1), [], 1);
        pixels_m(idx) = reshape(norm_lms(:, :, 2), [], 1);
        pixels_s(idx) = reshape(norm_lms(:, :, 3), [], 1);
        pixels_a(idx) = reshape(abr(:, :, 1), [], 1);
        pixels_b(idx) = reshape(abr(:, :, 2), [], 1);
        pixels_r(idx) = reshape(abr(:, :, 3), [], 1);
        n_pixels_so_far = n_pixels_so_far + prod(patch_size);
    end
end

feature_values = cell(n_prior_patches, numel(feature_flags));
for i_patch = 1:n_prior_patches
    achromatic = vislab.lib.cntrst_norm( ...
        prior_patches{i_patch}/mean(prior_patches{i_patch}, 'all')*prior_mean, ...
        prior_contrast);
    edge_values = vislab.nat_stat_bayes.edge_features(achromatic, 0, ...
        filter_sd, filter_nsd, filter_sd, filter_nsd, feature_flags);
    spot_values = vislab.nat_stat_bayes.spot_features(achromatic, ...
        size(achromatic, 1), feature_flags);
    feature_values(i_patch, steerable_features) = edge_values(steerable_features);
    feature_values(i_patch, cs_features) = spot_values(cs_features);
end

spectra = zeros([patch_size, n_power_patches]);
for i_patch = 1:n_power_patches
    spectra(:, :, i_patch) = vislab.nat_stat_bayes.power_spectrum( ...
        lib.texture_patch('tex_num', power_tex, 'patch_size', patch_size, ...
        'seed', i_patch, 'contrast', patch_contrast));
end
relative_power = spectra./mean(spectra, 3);
% drop zero frequency (power_spectrum removes the mean, so it carries nothing),
% which sits at the center after power_spectrum's fftshift
zero_freq = floor(patch_size/2) + 1;
relative_power(zero_freq(1), zero_freq(2), :) = NaN;
relative_power = relative_power(~isnan(relative_power));
% largest vertical gap between the measured CDF and the unit exponential's
sorted_power = sort(relative_power);
exp_gap = max(abs((1:numel(sorted_power))'/numel(sorted_power) ...
    - (1 - exp(-sorted_power))));

n_values = sum(cellfun(@numel, feature_values(:, [steerable_features cs_features])));
fprintf('    pooled %d patches: %d to %d values per feature\n', ...
    n_prior_patches, min(n_values), max(n_values));
fprintf(['    power at a fixed frequency, B%d, %d patches: largest gap between its\n', ...
    '    CDF and an exponential''s is %.3f\n'], power_tex, n_power_patches, exp_gap);

[kernel_1st, ~] = vislab.lib.steerable_kernels(filter_sd, filter_nsd);
[kernel_2nd, ~, ~] = vislab.lib.gauss_deriv2_kernels(filter_sd, filter_nsd);

figure('Name', 'Demo 2: feature-response priors (paper Figure 5, A-F)');
tiledlayout(6, 10, 'TileSpacing', 'compact');
% Grid is 6 rows x 10 columns: column 1 is a dedicated label tile per row, so
% each letter (a-f) labels its whole row once, pulled to the left, instead of
% a title repeated on every plot; columns 2-10 hold that row's three data
% tiles, each spanning 3 grid columns.
row_label_tile = @(r) (r-1)*10 + 1;
row_data_tile  = @(r, k) (r-1)*10 + 2 + 3*(k-1);

% A/B: solid-color marginal histograms, colored as in the paper (L/M/S cone
% red/green/blue; achromatic/blue-yellow/red-green black/blue/red), no bin
% edges.
show_row_label(row_label_tile(1), 'a');
show_hist(pixels_l, 'L cone', row_data_tile(1, 1), [0.85 0.1 0.1]);
show_hist(pixels_m, 'M cone', row_data_tile(1, 2), [0.1 0.6 0.2]);
show_hist(pixels_s, 'S cone', row_data_tile(1, 3), [0.2 0.3 0.9]);

show_row_label(row_label_tile(2), 'b');
show_hist(pixels_a, 'achromatic pixel', row_data_tile(2, 1), [0 0 0]);
show_hist(pixels_b, 'blue-yellow pixel', row_data_tile(2, 2), [0.2 0.3 0.9]);
show_hist(pixels_r, 'red-green pixel', row_data_tile(2, 3), [0.85 0.1 0.1]);

show_row_label(row_label_tile(3), 'c');
show_cdf(pixels_a, 'achromatic', row_data_tile(3, 1));
show_cdf(pixels_b, 'blue-yellow', row_data_tile(3, 2));
show_cdf(pixels_r, 'red-green', row_data_tile(3, 3));

show_row_label(row_label_tile(4), 'd');
show_cdf(vertcat(feature_values{:, steerable_features(1)}), 'magnitude', row_data_tile(4, 1));
add_kernel_inset(kernel_1st);   % 1st-derivative kernel
show_cdf(vertcat(feature_values{:, steerable_features(2)}), 'orientation (deg)', row_data_tile(4, 2));
show_cdf(vertcat(feature_values{:, steerable_features(3)}), 'magnitude x orientation', row_data_tile(4, 3));

show_row_label(row_label_tile(5), 'e');
show_cdf(vertcat(feature_values{:, steerable_features(4)}), 'magnitude', row_data_tile(5, 1));
add_kernel_inset(kernel_2nd);   % 2nd-derivative kernel
show_cdf(vertcat(feature_values{:, steerable_features(5)}), 'orientation (deg)', row_data_tile(5, 2));
show_cdf(vertcat(feature_values{:, steerable_features(6)}), 'magnitude x orientation', row_data_tile(5, 3));

show_row_label(row_label_tile(6), 'f');
show_cdf(vertcat(feature_values{:, 13}), 'center-surround, 3x3', row_data_tile(6, 1));
show_cdf(vertcat(feature_values{:, 14}), 'center-surround, 5x5', row_data_tile(6, 2));
show_cdf(relative_power, sprintf('relative power, B%d', power_tex), row_data_tile(6, 3));
hold on;
fplot(@(p) 1 - exp(-p), xlim, 'r--', 'LineWidth', 1.5);
legend('measured', 'exponential', 'Location', 'southeast'); box off;
drawnow;

%% --- 3. the optimal decision bound, as in the paper's Figure 6 -------------
% Figure 6A of the manuscript (p. 12) plots the THREE foveal decision variables
% of the separated same/different task against each other -- power, spot, and
% edge (vislab.nat_stat_bayes.dv_power, dv_spot_hist, dv_edge_hist) -- one point
% per patch pair -- and draws the optimal decision bound between same-texture
% and different-texture pairs. dv_spot_hist/dv_edge_hist need adaptive
% histogram bin boundaries learned over a full natural-image training pass (as
% the sibling texture-learning repo's s4_optimize_bins does); rather than
% reproducing that training here, this loads data/model/all_cues.mat, the
% repo's own precomputed per-pair values behind the actual published figure
% (17,700 same- and 17,700 different-texture pairs), and fits classify_normals
% to those directly. classify_normals comes from the Integrate and Classify
% Normal Distributions add-on, which setup installs; it draws its own
% boundary/probability surface (plotmode) rather than this script building one
% by hand -- only the raw sample points are plotted separately, as texture-
% learning's own decision-bound figures (demo/plot_stage5.m) also do.
%
% Only panel A is rebuilt. Panels B and D plot five human observers against the
% model across retinal eccentricity, which needs the subject files under
% exp_files/ rather than anything this demo computes. Panel C is the JOINED
% task, where the two patches abut so the model can also read the border
% between them -- a stimulus, and a set of border cues, the demo does not build.

fprintf('--- 3. Fitting the optimal decision bound (paper Figure 6A) ---\n');

cues = load(fullfile(cfg.paths.model, 'all_cues.mat'));
same_cues = [cues.vrps, cues.vrhs, cues.vres];   % power, spot, edge -- same-texture pairs
diff_cues = [cues.vrpd, cues.vrhd, cues.vred];   % power, spot, edge -- different-texture pairs
n_cue_pairs = size(same_cues, 1);

bound = classify_normals(same_cues, diff_cues, 'input_type', 'samp', ...
    'samp_opt', false, 'plotmode', 'norm_prob');   % opens its own figure
set(gcf, 'Name', 'Demo 3: optimal decision bound (paper Figure 6A)');
hold on;   % classify_normals' own hold state does not persist past its return
same_dots = scatter3(same_cues(:, 1), same_cues(:, 2), same_cues(:, 3), 4, 'b', ...
    'filled', 'MarkerFaceAlpha', 0.3);
diff_dots = scatter3(diff_cues(:, 1), diff_cues(:, 2), diff_cues(:, 3), 4, 'r', ...
    'filled', 'MarkerFaceAlpha', 0.3);
xlabel('power DV'); ylabel('spot DV'); zlabel('edge DV');
legend([same_dots diff_dots], {'same texture', 'different textures'}, 'Location', 'best');
title(sprintf('separated task, fovea: d'' = %.2f, %.1f%% correct', ...
    bound.norm_d_a, 100*(1 - bound.norm_err)), 'Interpreter', 'none'); box off;
drawnow;

fprintf('    %d same and %d different pairs: d'' = %.2f, error rate %.3f\n', ...
    n_cue_pairs, n_cue_pairs, bound.norm_d_a, bound.norm_err);

%% --- 4. forming the final decision variable from power, spot and edge -----
% Part 3 fit one quadratic boundary directly in 3D (power, spot, edge). This
% figure unpacks that single step into the three views the sibling
% texture-learning repo's own DV-construction figures use (demo/plot_stage5.m,
% plot_dcon_bar.m): the response cloud with its boundary, each cue's
% proportional contribution to d' (classify_normals' d_con output), and the
% resulting 1D separation of same- vs different-texture pairs once the three
% cues are combined into one number. Unlike texture-learning, which builds its
% final DV over several hierarchical stages (raw features -> sub-DVs ->
% combined DV), this model's three top-level cues combine in one step, so one
% row covers the whole construction.

fprintf('--- 4. Forming the final decision variable from power, spot and edge ---\n');

d_con = classify_normals(same_cues, diff_cues, 'input_type', 'samp', ...
    'samp_opt', false, 'd_con', true, 'plotmode', 0);
dv_fun = quad2fun(bound.norm_bd, 0);   % vectorized: takes a [3 x N] matrix of points
same_dv = dv_fun(same_cues')';
diff_dv = dv_fun(diff_cues')';

figure('Name', 'Demo 4: forming the final decision variable', 'Position', [100 100 1200 420]);
tiledlayout(1, 3, 'TileSpacing', 'compact');

nexttile; hold on;
scatter3(diff_cues(:, 1), diff_cues(:, 2), diff_cues(:, 3), 2, 'r', 'filled', ...
    'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.3);
scatter3(same_cues(:, 1), same_cues(:, 2), same_cues(:, 3), 2, 'b', 'filled', ...
    'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.3);
% The edge DV (3rd cue) has a long negative tail (a few pairs score far below
% the rest), which squeezes the bulk of the cloud into a sliver of the axes
% under min/max limits. Trimming each axis to its own central 99% -- the same
% convention part 2's histograms use -- keeps the boundary and the bulk of
% the cloud readable; the few points outside these limits simply clip.
cue_lims = [prctile([same_cues; diff_cues], 0.5); prctile([same_cues; diff_cues], 99.5)];
[Xg, Yg, Zg] = meshgrid(linspace(cue_lims(1,1), cue_lims(2,1), 40), ...
    linspace(cue_lims(1,2), cue_lims(2,2), 40), linspace(cue_lims(1,3), cue_lims(2,3), 40));
Vg = reshape(dv_fun([Xg(:), Yg(:), Zg(:)]'), size(Xg));
fv = isosurface(Xg, Yg, Zg, Vg, 0);
if ~isempty(fv.vertices)
    fv = reducepatch(fv, 0.15);
    p = patch(fv, 'FaceColor', [0.7 0.7 0.7], 'FaceAlpha', 0.35, ...
        'EdgeColor', [0.5 0.5 0.5], 'EdgeAlpha', 0.6);
    camlight; lighting gouraud;
end
view(3); grid on; box off;
xlim(cue_lims(:, 1)'); ylim(cue_lims(:, 2)'); zlim(cue_lims(:, 3)');
set(gca, 'XTickLabel', [], 'YTickLabel', [], 'ZTickLabel', []);
cue_colors = lines(3);
xlabel('power DV', 'Color', cue_colors(1, :));
ylabel('spot DV', 'Color', cue_colors(2, :));
zlabel('edge DV', 'Color', cue_colors(3, :));
title('response cloud + boundary');

nexttile; hold on;
pct_contrib = 100 * d_con.d_con / sum(d_con.d_con);
cum_pct = [0; cumsum(pct_contrib)];
cue_names = {'power', 'spot', 'edge'};
for i_cue = 1:3
    rectangle('Position', [0.4, cum_pct(i_cue), 0.8, pct_contrib(i_cue)], ...
        'FaceColor', cue_colors(i_cue, :), 'EdgeColor', 'w', 'LineWidth', 1);
    text(1.35, (cum_pct(i_cue) + cum_pct(i_cue+1)) / 2, ...
        sprintf('%s  %.0f%%', cue_names{i_cue}, pct_contrib(i_cue)), ...
        'VerticalAlignment', 'middle', 'Color', cue_colors(i_cue, :));
end
xlim([0 3]); ylim([0 100]);
set(gca, 'XTick', [], 'YTick', [], 'XColor', 'none', 'YColor', 'none');
box off;
title('d'' contribution per cue');

% The combined DV is even longer-tailed than any one cue (it's a quadratic
% combination of them), and its tail carries real probability mass rather
% than a handful of outliers, so clipping alone still leaves the bulk of the
% data squeezed near zero. A signed ("symlog") log transform -- linear near
% zero, logarithmic in each direction beyond it -- spreads the bulk out
% without discarding the tails: a standard trick for heavy-tailed data that
% spans both signs, where an ordinary log scale doesn't apply.
dv_lims = prctile([same_dv; diff_dv], [0.1 99.9]);
diff_dv_shown = diff_dv(diff_dv >= dv_lims(1) & diff_dv <= dv_lims(2));
same_dv_shown = same_dv(same_dv >= dv_lims(1) & same_dv <= dv_lims(2));
symlog = @(x) sign(x) .* log1p(abs(x));

nexttile; hold on;
histogram(symlog(diff_dv_shown), 'Normalization', 'pdf', 'FaceColor', 'r', 'EdgeColor', 'none', 'FaceAlpha', 0.6);
histogram(symlog(same_dv_shown), 'Normalization', 'pdf', 'FaceColor', 'b', 'EdgeColor', 'none', 'FaceAlpha', 0.6);
xlim(symlog(dv_lims));
tick_vals = [-300 -100 -30 -10 -3 0 3 10 30 100 300];
tick_vals = tick_vals(tick_vals >= dv_lims(1) & tick_vals <= dv_lims(2));
xticks(symlog(tick_vals)); xticklabels(string(tick_vals));
yticks([]);
xlabel('combined decision variable (symlog scale)'); ylabel('pdf'); box off;
legend({'different textures', 'same texture'}, 'Location', 'best');
title('final separation');
drawnow;

fprintf('    combined DV from %d cues; same/different separation matches part 3''s d'' = %.2f\n', ...
    3, bound.norm_d_a);

%% --- 5. grown texture regions across parameters, paper's Figure 9 ----------
% Figure 9 of the manuscript (p. 13) shows six 640x640 grown texture region
% images that differ only in the parameters the growing takes: how many
% regions, how big the blocks are, how strongly the region seeds are pulled to
% the center, and what fraction of the grid gets claimed. Five of its six
% panels are rebuilt here. The sixth (F) adds a vertical orientation bias to
% the textures, and nothing in this repo implements an orientation bias, so it
% is left out.
%
% Two readings of the paper's parameters are worth stating plainly, since
% neither is written down in code anywhere:
%   * Block size is rebuilt as a grid COUNT rather than a pixel count. The
%     paper's 640x640 image of 64-pixel blocks is a 10x10 grid of blocks and
%     its 16-pixel blocks are a 40x40 grid; keeping both grids while shrinking
%     the pixels per block keeps the picture the same and the demo fast.
%   * "Central bias" is read as the complement of mk_masks' seed_radius_frac:
%     a bias of 0 lets the region seeds fall anywhere (seed_radius_frac 1), and
%     a bias of 80% confines them to the central fifth of the grid (0.2).
fig8_panels = struct( ...
    'label',        {'A', 'B', 'C', 'D', 'E'}, ...
    'n_regions',    {  5,   3,   7,   5,   5}, ...
    'grid_size',    { 10,  10,  10,  40,  40}, ...
    'patch_px',     { 32,  32,  32,   8,   8}, ...
    'central_bias', {  0,   0,   0,   0, 0.8}, ...
    'coverage',     {  1,   1,   1,   1, 0.5});

fprintf('--- 5. Growing %d parameter variants of a region image (paper Figure 9) ---\n', ...
    numel(fig8_panels));

rng(cfg.seed);
figure('Name', 'Demo 5: grown texture regions across parameters (paper Figure 9)');
tiledlayout(2, 3, 'TileSpacing', 'compact');
% each panel continues the running seed cursor, so no seed is reused across
% panels or parts
for i_panel = 1:numel(fig8_panels)
    panel = fig8_panels(i_panel);
    [~, panel_map] = grouping.mk_masks(panel.grid_size, panel.n_regions, 1, ...
        1 - panel.central_bias, panel.coverage);
    panel_tex = grouping.mk_texs(n_textures, panel.n_regions, 1);
    [panel_image, seed_cursor] = fill_regions(panel_map, panel_tex(1, :), ...
        panel.patch_px*[1 1], patch_contrast, seed_cursor);
    show_patch(panel_image, sprintf('%s. %d regions, %dx%d, bias %d%%, cover %d%%', ...
        panel.label, panel.n_regions, panel.grid_size, panel.grid_size, ...
        round(100*panel.central_bias), round(100*panel.coverage)));
    fprintf('    %s: %d regions on a %dx%d grid, %d%% of it claimed\n', ...
        panel.label, panel.n_regions, panel.grid_size, panel.grid_size, ...
        round(100*mean(panel_map(:) > 0)));
end
drawnow;

%% --- 5. full-scene grouping: the actual segmentation pipeline --------------
% This runs the full pipeline from raw pixels all the way to a segmentation,
% via the same segment_scene pipeline part 1 already used to segment its
% smaller GTR images. A 1024x1024 scene is cut into 16 Brodatz regions (one
% per cell of a 4x4 grid, each a random crop of a different sheet), split into
% a 16x16 grid of 64x64 patches, and segment_scene computes the power and
% histogram decision variables for every ordered pair, combines them via the
% fitted Brodatz boundary (part 1's brodatz_bd), links pairs scoring above
% link_criterion, and merges them into regions.
%
% grp_patch_size and grp_grid_size are kept separate from the shared
% patch_size (a [64 64] pair): same idea, different scale, and this part runs
% last so nothing downstream reads either name.
grp_scene_size = 1024;         % scene side length, pixels
grp_sheet_size = 640;          % Brodatz sheet side length, pixels
grp_region_size = 256;         % texture region side length, pixels
grp_patch_size = 64;           % patch side length, pixels
grp_region_grid_size = grp_scene_size/grp_region_size;   % regions per scene side
grp_grid_size = grp_scene_size/grp_patch_size;            % patches per scene side

fprintf('--- 6. Grouping a full %dx%d-patch scene into regions ---\n', ...
    grp_grid_size, grp_grid_size);

% build the scene from the first 16 Brodatz sheets, B1..B16, one per region
rng(cfg.seed);
grp_scene = zeros(grp_scene_size, grp_scene_size);
grp_image_num = 0;
for i_region_row = 1:grp_region_grid_size
    for i_region_col = 1:grp_region_grid_size
        grp_image_num = grp_image_num + 1;
        tex_img = imread(fullfile(cfg.paths.textures, 'brodatz', ...
            sprintf('B%d.gif', grp_image_num)));
        row_offset = randi(grp_sheet_size - grp_region_size);
        col_offset = randi(grp_sheet_size - grp_region_size);
        region_img = tex_img(row_offset:row_offset+grp_region_size-1, ...
            col_offset:col_offset+grp_region_size-1);
        region_row_lo = (i_region_row-1)*grp_region_size+1;
        region_col_lo = (i_region_col-1)*grp_region_size+1;
        grp_scene(region_row_lo:region_row_lo+grp_region_size-1, ...
            region_col_lo:region_col_lo+grp_region_size-1) = region_img;
    end
end

% decision variables, boundary, linking, and merging into regions -- all via
% the shared segment_scene pipeline (constants loaded in part 1)
grp_win = grouping.mk_win(grp_patch_size, grp_patch_size/2, 2);
[grp_group_img, grp_group_num] = segment_scene(grp_scene, grp_patch_size, grp_win, ...
    hist_edges, brodatz_bd, noise_const, link_criterion, group_criterion);
fprintf('    %d patches merged into %d groups\n', grp_grid_size^2, grp_group_num);

figure('Name', 'Demo 6: full-scene grouping');
tiledlayout(1, 2, 'TileSpacing', 'compact');
nexttile;
imagesc(grp_scene); axis image off; colormap(gca, gray); title('scene (16 Brodatz regions)');
nexttile;
imagesc(grp_group_img); axis image off; colormap(gca, parula); title(sprintf('%d groups found', grp_group_num));
drawnow;

%% --- 7. human discrimination accuracy vs eccentricity, paper's Figure 6B ---
% Figure 6B plots five observers' same-different discrimination accuracy
% against retinal eccentricity in the separated task, with the HBO model's
% own predictions overlaid as solid symbols. The model half needs an
% eccentricity-dependent version of general.simulate_discrimination, which
% does not exist (that function only ever runs at the fovea) and today does
% not even run there (see docs/repo-cleanup.md's new section 0.7 for why).
% This part rebuilds only the human half, directly from the real subject
% files general.compute_exp_error_mat was written to read
% (exp_files/sep/subject_out/*.mat), skipping the one whose name marks it as
% a practice run rather than a scored session.
%
% general.compute_exp_error_mat also draws four pcolor error-matrix figures
% per subject, which this part doesn't want; those are closed right after
% each call, keeping only the final accuracy-vs-eccentricity summary.
sep_settings = load(fullfile(cfg.paths.exp_files, 'sep', 'exp_settings.mat')).exp_settings;
subject_files = dir(fullfile(cfg.paths.exp_files, 'sep', 'subject_out', '*.mat'));
subject_files = subject_files(~contains({subject_files.name}, 'practice', 'IgnoreCase', true));

fprintf('--- 7. Human discrimination accuracy vs eccentricity (paper Figure 6B, human data only) ---\n');

subject_accuracy = zeros(numel(subject_files), sep_settings.nLevels);
for i_subject = 1:numel(subject_files)
    subject_file = load(fullfile(subject_files(i_subject).folder, ...
        subject_files(i_subject).name)).subject_file;
    figs_before = findobj('Type', 'figure');
    [~, session_accuracy] = general.compute_exp_error_mat(sep_settings, subject_file);
    close(setdiff(findobj('Type', 'figure'), figs_before));
    subject_accuracy(i_subject, :) = mean(session_accuracy, 1);
end
fprintf('    %d of %d subject files used (practice sessions excluded)\n', ...
    numel(subject_files), numel(dir(fullfile(cfg.paths.exp_files, 'sep', 'subject_out', '*.mat'))));

figure('Name', 'Demo 7: human discrimination accuracy vs eccentricity (paper Figure 6B)');
errorbar(sep_settings.ecc, mean(subject_accuracy, 1), std(subject_accuracy, 0, 1), ...
    '-ok', 'MarkerFaceColor', 'k');
xlabel('eccentricity (deg)'); ylabel('accuracy'); box off;
title(sprintf('%d observers, separated task (no model overlay)', numel(subject_files)));
drawnow;

%% --- what you just saw -----------------------------------------------------
fprintf('\n=== what you just saw ===\n');
fprintf(['1. Three images of five grown Brodatz texture regions, above their\n', ...
    '   ground-truth maps, above the model''s own segmentation of each image: the\n', ...
    '   layout of Figure 1 of the manuscript, with the real grouping pipeline run\n', ...
    '   on it directly (figure 1).\n']);
fprintf(['2. The model''s low-level feature-response priors: LMS and ABR\n', ...
    '   (achromatic/blue-yellow/red-green) pixel-value histograms and ABR CDFs\n', ...
    '   (A-C) over real natural-image patches, and the steerable-filter magnitude\n', ...
    '   and orientation, center-surround, and power CDFs (D-F) over Brodatz patches\n', ...
    '   instead of natural images -- all of Figure 5 of the manuscript (figure 2).\n']);
fprintf(['3. The optimal decision bound between same- and different-texture pairs\n', ...
    '   in the published power/spot/edge decision variables: panel A of Figure 6\n', ...
    '   of the manuscript (figure 3). Its other panels need the human subject\n', ...
    '   files or the joined-task border cues, and are left out.\n']);
fprintf(['4. That same bound unpacked into the response cloud, each cue''s share\n', ...
    '   of d'', and the resulting 1D same/different separation once power, spot\n', ...
    '   and edge combine into one decision variable (figure 4).\n']);
fprintf(['5. The same region growing run at three region counts, two block sizes,\n', ...
    '   and one center-biased, half-covered setting: five of the six panels of\n', ...
    '   Figure 9 of the manuscript (figure 5). The sixth needs an orientation\n', ...
    '   bias, which this repo does not implement.\n']);
fprintf(['6. The full grouping pipeline run on one whole scene: the power and\n', ...
    '   histogram decision variables over every patch pair, combined by a fitted\n', ...
    '   boundary into links, and merged into the regions shown alongside the scene\n', ...
    '   (figure 6) -- this is the actual task the model performs, not a controlled\n', ...
    '   comparison.\n']);
fprintf(['7. Real observers'' same-different discrimination accuracy against\n', ...
    '   retinal eccentricity, in the separated task: the human half of Figure 6B\n', ...
    '   of the manuscript, with no model overlay (figure 7).\n']);
fprintf('\nDemo complete. See the README for the full experiments and analyses.\n');

%% --- local helpers ---------------------------------------------------------

function show_patch(img, label, tile_idx)
% One tile of a tiled layout showing a normalized-luminance image in gray.
% imagesc rather than imshow: it needs no Image Processing Toolbox and does not
% warn about magnification inside a docked figure. label is optional -- pass
% '' to leave the tile untitled (e.g. when a dedicated label column, via
% SHOW_ROW_LABEL, names the whole row instead). tile_idx is optional -- pass
% it to address an explicit tile in a layout with a reserved label column;
% omit it to just take the next tile in sequence.
    if nargin < 3, nexttile; else, nexttile(tile_idx); end
    imagesc(img, [0 1]);
    axis image off;
    colormap(gca, gray);
    if ~isempty(label), title(label); end
end

function show_regions(region_map, n_regions, label, tile_idx)
% One tile of a tiled layout showing a region-label map, one flat color per
% region. The color limits are pinned to 1:n_regions so that each region keeps
% its own color even if a map happens not to use every label. label and
% tile_idx are optional -- see SHOW_PATCH.
    if nargin < 4, nexttile; else, nexttile(tile_idx); end
    imagesc(region_map, [1 n_regions]);
    axis image off;
    colormap(gca, parula(n_regions));
    if ~isempty(label), title(label); end
end

function show_cdf(values, label, tile_idx)
% One tile of a tiled layout showing the empirical cumulative distribution of
% values as a black line, as in the paper's Figure 5. Drawn through 500 evenly
% spaced order statistics rather than every value, and with the x axis trimmed
% to the central 99% of the values so a few outliers do not squash the curve.
% label is the x-axis label alone -- no separate title repeating it. tile_idx
% is this tile's explicit nexttile position (the figure reserves a dedicated
% label column, so tiles are addressed by index, not handed out sequentially).
    nexttile(tile_idx, [1 3]);
    sorted = sort(values(:));
    n_values = numel(sorted);
    keep = unique(round(linspace(1, n_values, 500)));
    plot(sorted(keep), keep/n_values, 'k', 'LineWidth', 1.5);
    xlim(sorted([ceil(0.005*n_values), floor(0.995*n_values)])');
    ylim([0 1]); yticks([0 1]);
    xlabel(label); ylabel('cdf'); box off;
end

function show_hist(values, label, tile_idx, color)
% One tile of a tiled layout showing a marginal PDF of values, as in panels A
% and B of the paper's Figure 5. The x axis is trimmed to the central 99% of
% the values so a few outliers do not squash the bars; the y axis carries no
% numbers since the per-bin density's scale is arbitrary and differs per
% feature (matching the sibling texture-learning repo's own prior plots).
% label is the x-axis label alone -- no separate title repeating it. tile_idx
% is this tile's explicit nexttile position (see SHOW_CDF). color is a solid
% RGB fill with no bin-edge outline, matching the paper's own coloring.
    nexttile(tile_idx, [1 3]);
    sorted = sort(values(:));
    n_values = numel(sorted);
    histogram(sorted, 300, 'Normalization', 'pdf', 'FaceColor', color, 'EdgeColor', 'none');
    xlim(sorted([ceil(0.005*n_values), floor(0.995*n_values)])');
    yticks([]);
    xlabel(label); ylabel('pdf'); box off;
end

function show_row_label(tile_idx, text_str)
% One narrow tile holding bold text (a single row letter, or a short row
% name), pulled to the left of its row's data tiles -- the text labels the
% whole row once, instead of a title repeated on every plot.
    nexttile(tile_idx, [1 1]);
    text(0.5, 0.5, text_str, 'FontWeight', 'bold', 'FontSize', 12, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
    axis off;
end

function add_kernel_inset(kernel)
% Small inset image in the bottom-right corner of the CURRENT tile's axes,
% showing the actual steerable-filter kernel (vislab.lib.steerable_kernels /
% gauss_deriv2_kernels) behind that row's 1st- or 2nd-derivative feature.
% Drawn as an image in the tile's own data coordinates rather than a separate
% axes: a tiledlayout silently deletes its earlier tiles if a bare axes() is
% added as a sibling, so the inset has to live inside the existing axes. Sized
% in actual screen pixels (getpixelposition resolves this tile's true size
% even nested inside a tiledlayout), not data units: a CDF tile's x-range can
% be orders of magnitude wider than its fixed [0 1] y-range, so a "square"
% inset in data units would render as a sliver.
    hold on;
    tile_px = getpixelposition(gca);
    xl = xlim; yl = ylim;
    dx_per_px = diff(xl) / tile_px(3);
    dy_per_px = diff(yl) / tile_px(4);
    sz_px = 11; margin_px = 4;
    inset_x = xl(2) - [margin_px + sz_px, margin_px] * dx_per_px;
    inset_y = yl(1) + [margin_px, margin_px + sz_px] * dy_per_px;
    image(inset_x, inset_y, repmat(rescale(kernel), 1, 1, 3));
    xlim(xl); ylim(yl);   % the inset must not change the tile's own axis range
end

function [stimulus, next_seed] = fill_regions(region_map, region_tex, patch_size, contrast, first_seed)
% Build a texture-region image by drawing ONE continuous texture sample per
% region (lib.texture_patch, sized to the whole canvas) and masking it down to
% that region's grown shape -- so a region's texture flows continuously across
% all its patches, rather than being resampled independently patch by patch
% (paper Figure 1). region_tex(k) gives the Brodatz sheet for region k; each
% region draws from seed first_seed+k-1, and next_seed is returned so a
% following call can continue the seed run without reusing one.
% A patch labelled 0 was never claimed -- grouping.mk_masks stops growing once
% its fill_fraction is reached -- and is left at mid gray.
    [n_rows, n_cols] = size(region_map);
    canvas_size = [n_rows*patch_size(1), n_cols*patch_size(2)];
    n_regions = numel(region_tex);
    stimulus = 0.5*ones(canvas_size);
    for region = 1:n_regions
        region_img = lib.texture_patch('tex_num', region_tex(region), ...
            'patch_size', canvas_size, 'seed', first_seed + region - 1, 'contrast', contrast);
        pixel_mask = logical(kron(region_map == region, ones(patch_size)));
        stimulus(pixel_mask) = region_img(pixel_mask);
    end
    next_seed = first_seed + n_regions;
end

function stimulus = fill_regions_raw(region_map, region_tex, patch_size, cfg)
% Raw-Brodatz-pixel counterpart of FILL_REGIONS, for feeding SEGMENT_SCENE.
% The fitted brodatz_boundary.mat was fit on raw 0-255 Brodatz crops, as part
% 6's own scene construction uses directly -- not on lib.texture_patch's
% normalized-[0,1]-luminance synthesis FILL_REGIONS draws for display, a
% different numeric scale the fitted boundary was not fit for. Places one
% random crop of the region's Brodatz sheet per region, masked to the same
% grown shape FILL_REGIONS uses, so the ground truth lines up with the pretty
% display version.
    [n_rows, n_cols] = size(region_map);
    canvas_size = [n_rows*patch_size(1), n_cols*patch_size(2)];
    n_regions = numel(region_tex);
    stimulus = 128*ones(canvas_size);   % mid-gray for any patch never claimed
    for region = 1:n_regions
        sheet = double(imread(fullfile(cfg.paths.textures, 'brodatz', ...
            sprintf('B%d.gif', region_tex(region)))));
        row_offset = randi(size(sheet, 1) - canvas_size(1) + 1);
        col_offset = randi(size(sheet, 2) - canvas_size(2) + 1);
        region_img = sheet(row_offset:row_offset+canvas_size(1)-1, ...
            col_offset:col_offset+canvas_size(2)-1);
        pixel_mask = logical(kron(region_map == region, ones(patch_size)));
        stimulus(pixel_mask) = region_img(pixel_mask);
    end
end

function [group_img, n_groups] = segment_scene(scene, patch_size, win, edges, ...
    boundary, noise_const, link_criterion, group_criterion)
% SEGMENT_SCENE  The grouping pipeline's decision-variables-to-regions pass,
% on one square gray-level scene: the power and histogram decision variables
% for every ordered pair of patch_size patches, combined by the fitted
% Brodatz boundary into one decision variable per pair, thresholded into
% links, and merged into regions by how many links each linked pair shares.
% Shared by part 1 (small grown-region images) and part 6 (the full
% 1024x1024 scene), so this segmentation logic exists in exactly one place.
%
%   scene           - [n x n] gray-level image, n a multiple of patch_size.
%   patch_size      - patch side length, pixels.
%   win             - grouping.mk_win output, sized to patch_size.
%   edges           - gray-level histogram bin edges, for lib.hist_dv.
%   boundary        - struct with fields q2, q1, q0: a fitted quadratic
%                     combining log-power and log-histogram decision
%                     variables into one (data/model/brodatz_boundary.mat).
%   noise_const     - dv_power's spectral noise-suppression constant.
%   link_criterion  - decision variable a pair must exceed to be linked.
%   group_criterion - shared-link fraction two linked patches must exceed.
%
%   See also GROUPING.MK_WIN, GROUPING.THRESH, GROUPING.NLSAME,
%   VISLAB.NAT_STAT_BAYES.DV_POWER, LIB.HIST_DV.
    grid_size = size(scene, 1) / patch_size;
    n_patches = grid_size^2;
    patch_coords = zeros(n_patches, 2);
    responses = zeros(n_patches, n_patches, 2);
    for i_patch1 = 1:n_patches
        row1 = floor((i_patch1-1)/grid_size) + 1;
        col1 = i_patch1 - (row1-1)*grid_size;
        row1_lo = (row1-1)*patch_size+1;  col1_lo = (col1-1)*patch_size+1;
        patch_coords(i_patch1, :) = [row1_lo, col1_lo];
        patch1 = scene(row1_lo:row1_lo+patch_size-1, col1_lo:col1_lo+patch_size-1);
        for i_patch2 = 1:n_patches
            row2 = floor((i_patch2-1)/grid_size) + 1;
            col2 = i_patch2 - (row2-1)*grid_size;
            row2_lo = (row2-1)*patch_size+1;  col2_lo = (col2-1)*patch_size+1;
            patch2 = scene(row2_lo:row2_lo+patch_size-1, col2_lo:col2_lo+patch_size-1);
            responses(i_patch1, i_patch2, 1) = vislab.nat_stat_bayes.dv_power( ...
                patch1.*win, patch2.*win, noise_const, patch_size);
            responses(i_patch1, i_patch2, 2) = lib.hist_dv(patch1, patch2, edges);
        end
    end

    dv = zeros(n_patches, n_patches);
    for i_patch1 = 1:n_patches
        for i_patch2 = 1:n_patches
            if i_patch1 ~= i_patch2
                xx = [log(responses(i_patch1, i_patch2, 1)); ...
                      log(responses(i_patch1, i_patch2, 2))];
                dv(i_patch1, i_patch2) = xx'*boundary.q2*xx + xx'*boundary.q1 + boundary.q0;
            end
        end
    end

    links = grouping.thresh(dv, n_patches, link_criterion);
    groups = zeros(n_patches, 2+n_patches, 2);   % group#, #links, link1, link2, ...
    for i_patch1 = 1:n_patches
        for i_patch2 = 1:n_patches
            if links(i_patch1, i_patch2) == 1
                n_links = groups(i_patch1, 2, 1) + 1;
                groups(i_patch1, 2, 1) = n_links;
                groups(i_patch1, 2+n_links, 1) = i_patch2;
                groups(i_patch1, 2+n_links, 2) = dv(i_patch1, i_patch2);
            end
        end
    end
    for i_patch = 1:n_patches
        n_links_a = groups(i_patch, 2, 1);
        links_a = groups(i_patch, 3:3+n_links_a-1, 1);
        for i_link = 1:n_links_a
            n_links_b = groups(links_a(i_link), 2, 1);
            links_b = groups(links_a(i_link), 3:3+n_links_b-1, 1);
            n_common = grouping.nlsame(links_a, n_links_a, links_b, n_links_b);
            link_ratio = 2*n_common/(n_links_a+n_links_b);
            if n_links_a > 1 && link_ratio < group_criterion && i_patch ~= links_a(i_link)
                links(i_patch, links_a(i_link)) = 0;
            end
        end
    end
    n_groups = 0;
    for i_patch = 1:n_patches
        n_links_a = groups(i_patch, 2, 1);
        links_a = groups(i_patch, 3:3+n_links_a-1, 1);
        for i_link = 1:n_links_a
            n_links_b = groups(links_a(i_link), 2, 1);
            links_b = groups(links_a(i_link), 3:3+n_links_b-1, 1);
            n_common = grouping.nlsame(links_a, n_links_a, links_b, n_links_b);
            link_ratio = 2*n_common/(n_links_a+n_links_b);
            if n_links_a > 1 && link_ratio > group_criterion
                if groups(i_patch, 1, 1) == 0
                    n_groups = n_groups + 1;
                    groups(i_patch, 1, 1) = n_groups;
                end
                if groups(links_a(i_link), 1, 1) == 0
                    groups(links_a(i_link), 1, 1) = groups(i_patch, 1, 1);
                end
            end
        end
    end

    group_img = zeros(size(scene));
    for i_patch = 1:n_patches
        xx = patch_coords(i_patch, 1);  yy = patch_coords(i_patch, 2);
        group_img(xx:xx+patch_size-1, yy:yy+patch_size-1) = groups(i_patch, 1);
    end
end

function names = sheet_names(tex_nums)
% Brodatz sheet numbers as one printable list, e.g. 'B36, B16, B34'.
    names = strjoin(arrayfun(@(t) sprintf('B%d', t), tex_nums, ...
        'UniformOutput', false), ', ');
end

