% RUN_DEMO  Short demonstration of the texture-segmentation model.
%
%   Run it (from anywhere):   >> run <path-to-repo>/run_demo.m
%   or:   >> cd <repo>; setup; run run_demo.m
%
%   This is a script, not a function: it takes no arguments, asks no questions,
%   and leaves its results in the base workspace and in nine figure windows.
%   It runs in a few minutes (measured: 259 s on R2024b, most of it part 9's
%   256x256 pairwise comparisons) and needs no large downloads -- everything it
%   uses comes from the Brodatz texture sheets that ship inside the sibling
%   vislab-common repo, which setup clones automatically. The ~19 GB natural
%   image set is NOT needed.
%
% What it does, in nine parts:
%   1. Texture patches. Draws pairs of 64x64 Brodatz patches -- some pairs from
%      the SAME sheet, some from two DIFFERENT sheets -- with lib.texture_patch.
%   2. Decision variables. Runs two of the model's same/different decision
%      variables over those pairs: vislab.nat_stat_bayes.dv_power (Fourier
%      power spectrum) and lib.hist_dv (gray-level histogram log-likelihood
%      ratio). Both should
%      read near zero for same-texture pairs and clearly higher for
%      different-texture pairs; the demo prints the two means and the area
%      under the ROC curve, and plots the two distributions.
%   3. Grouping stimulus. Grows a patch grid into contiguous texture regions
%      with grouping.mk_masks, assigns a texture to each region with
%      grouping.mk_texs, and fills every patch to build the kind of
%      texture-region image the grouping experiments use as a stimulus.
%   4. Pair binning. Builds the distance / eccentricity geometry the grouping
%      experiment bins its patch pairs by (grouping.mk_dist, mk_mecc, mk_decc,
%      mk_bindex, find_bin), and shows the bin every patch falls into relative
%      to one reference patch.
%   5. Grown texture regions. Rebuilds the layout of Figure 1 of the lab's
%      manuscript (notes/Texture paper biorxiv.pdf): three images of five
%      grown Brodatz texture regions each, above their ground-truth region
%      maps, with the part-3 machinery.
%   6. Feature priors. Rebuilds panels D-F of the manuscript's Figure 5: the
%      cumulative distributions of the model's low-level feature responses
%      (steerable-filter magnitude and orientation, center-surround, and power
%      at a fixed spatial frequency), measured here over Brodatz patches
%      (vislab.nat_stat_bayes.edge_features, spot_features, power_spectrum)
%      rather than over the paper's natural images.
%   7. Decision bound. Rebuilds panel A of the manuscript's Figure 6: the two
%      decision variables of part 2 plotted against each other, with the
%      optimal quadratic bound between the same- and different-texture pairs
%      fitted by classify_normals.
%   8. Region-growing parameters. Rebuilds five of the six panels of the
%      manuscript's Figure 8: the same region-growing run at three region
%      counts, two block sizes, and one partial-coverage, center-biased
%      setting.
%   9. Full-scene grouping. Builds one 1024x1024 scene of 16 Brodatz regions,
%      splits it into a 16x16 grid of patches, and runs the actual grouping
%      pipeline end to end: part 2's two decision variables over every ordered
%      pair of patches, combined by a fitted quadratic boundary
%      (data/model/brodatz_boundary.mat) into one decision variable per pair,
%      thresholded into links, and merged into regions by how many links each
%      linked pair shares (grouping.thresh, grouping.nlsame). Shows the scene
%      next to the region map the grouping found.
%
%   It does NOT run the Psychtoolbox experiments (+experiment, which need a
%   live display and a subject) or any of the natural-image analyses
%   (+general). See the README for those.
%
%   Reproducible: everything is drawn under rng(cfg.seed), and every call to
%   lib.texture_patch is given an explicit seed, so repeated runs give
%   identical numbers and identical images.
%
% See also SETUP, CONFIG, LIB.TEXTURE_PATCH, VISLAB.NAT_STAT_BAYES.DV_POWER,
%   LIB.HIST_DV, GROUPING.MK_MASKS, GROUPING.MK_TEXS, GROUPING.FIND_BIN,
%   VISLAB.NAT_STAT_BAYES.EDGE_FEATURES, VISLAB.NAT_STAT_BAYES.SPOT_FEATURES,
%   VISLAB.NAT_STAT_BAYES.POWER_SPECTRUM, CLASSIFY_NORMALS, GROUPING.MK_WIN,
%   GROUPING.THRESH, GROUPING.NLSAME

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

%% --- 1. texture patches: same-texture and different-texture pairs ----------
% Every random choice is made here, once, under the config seed. This matters:
% lib.texture_patch reseeds the global RNG itself (rng('default'); rng(seed)),
% so drawing the texture numbers inside the loop would not be reproducible.
% Each patch therefore gets an explicit texture number and an explicit seed.
rng(cfg.seed);
n_pairs = 40;                    % pairs per condition
patch_size = [64 64];            % pixels
n_textures = 60;                 % Brodatz sheets B1..B60
% RMS contrast for every patch drawn below, a little under lib.texture_patch's
% own 0.2 default: a few Brodatz sheets have heavy enough luminance tails that
% 0.2 clips a fraction of a percent of their pixels, and the resulting warnings
% would bury the demo's actual output.
patch_contrast = 0.12;

same_tex = randi(n_textures, n_pairs, 1);
diff_tex = zeros(n_pairs, 2);
for i_pair = 1:n_pairs
    pair_tex = randperm(n_textures, 2);     % two distinct sheets
    diff_tex(i_pair, :) = pair_tex;
end
patch_seeds = randi(intmax, n_pairs, 4);    % one seed per patch, 4 patches/row

fprintf('\n--- 1. Drawing %d same-texture and %d different-texture patch pairs ---\n', ...
    n_pairs, n_pairs);

same_patches = cell(n_pairs, 2);
diff_patches = cell(n_pairs, 2);
for i_pair = 1:n_pairs
    % same-texture pair: one sheet, two random locations in it
    same_patches{i_pair, 1} = lib.texture_patch('tex_num', same_tex(i_pair), ...
        'patch_size', patch_size, 'seed', patch_seeds(i_pair, 1), 'contrast', patch_contrast);
    same_patches{i_pair, 2} = lib.texture_patch('tex_num', same_tex(i_pair), ...
        'patch_size', patch_size, 'seed', patch_seeds(i_pair, 2), 'contrast', patch_contrast);
    % different-texture pair: two sheets
    diff_patches{i_pair, 1} = lib.texture_patch('tex_num', diff_tex(i_pair, 1), ...
        'patch_size', patch_size, 'seed', patch_seeds(i_pair, 3), 'contrast', patch_contrast);
    diff_patches{i_pair, 2} = lib.texture_patch('tex_num', diff_tex(i_pair, 2), ...
        'patch_size', patch_size, 'seed', patch_seeds(i_pair, 4), 'contrast', patch_contrast);
end

figure('Name', 'Demo 1: example patch pairs');
tiledlayout(2, 2, 'TileSpacing', 'compact');
show_patch(same_patches{1, 1}, sprintf('same: B%d', same_tex(1)));
show_patch(same_patches{1, 2}, sprintf('same: B%d', same_tex(1)));
show_patch(diff_patches{1, 1}, sprintf('different: B%d', diff_tex(1, 1)));
show_patch(diff_patches{1, 2}, sprintf('different: B%d', diff_tex(1, 2)));
drawnow;

%% --- 2. decision variables over those pairs --------------------------------
% Both decision variables are "evidence that the two patches differ": near zero
% for a same-texture pair, larger for a different-texture pair.
noise_const = 10;                % dv_power's spectral noise-suppression constant
n_hist_bins = 32;                % gray-level bins for hist_dv

fprintf('--- 2. Computing the power and histogram decision variables ---\n');

power_same = zeros(n_pairs, 1);
power_diff = zeros(n_pairs, 1);
hist_same = zeros(n_pairs, 1);
hist_diff = zeros(n_pairs, 1);
for i_pair = 1:n_pairs
    power_same(i_pair) = vislab.nat_stat_bayes.dv_power(same_patches{i_pair, 1}, ...
        same_patches{i_pair, 2}, noise_const, size(same_patches{i_pair, 1}, 1));
    power_diff(i_pair) = vislab.nat_stat_bayes.dv_power(diff_patches{i_pair, 1}, ...
        diff_patches{i_pair, 2}, noise_const, size(diff_patches{i_pair, 1}, 1));
    % hist_dv needs explicit bin edges; span whichever pair is being compared,
    % since texture_patch returns normalized luminance rather than gray levels.
    hist_same(i_pair) = lib.hist_dv(same_patches{i_pair, 1}, ...
        same_patches{i_pair, 2}, ...
        pair_edges(same_patches{i_pair, 1}, same_patches{i_pair, 2}, n_hist_bins));
    hist_diff(i_pair) = lib.hist_dv(diff_patches{i_pair, 1}, ...
        diff_patches{i_pair, 2}, ...
        pair_edges(diff_patches{i_pair, 1}, diff_patches{i_pair, 2}, n_hist_bins));
end

fprintf('\n    decision variable    same-texture      different-texture    AUC\n');
fprintf('    %-18s  %7.3f +- %5.3f   %7.3f +- %5.3f   %.3f\n', 'dv_power', ...
    mean(power_same), std(power_same), mean(power_diff), std(power_diff), ...
    roc_area(power_same, power_diff));
fprintf('    %-18s  %7.1f +- %5.1f   %7.1f +- %5.1f   %.3f\n', 'hist_dv', ...
    mean(hist_same), std(hist_same), mean(hist_diff), std(hist_diff), ...
    roc_area(hist_same, hist_diff));
fprintf(['\n    (AUC is the area under the ROC curve: the chance that a random\n', ...
    '     different-texture pair scores above a random same-texture pair.\n', ...
    '     0.5 is chance, 1.0 is perfect separation.)\n\n']);

figure('Name', 'Demo 2: decision variables, same vs different');
tiledlayout(1, 2, 'TileSpacing', 'compact');
nexttile;
histogram(power_same, 15, 'FaceAlpha', 0.5); hold on;
histogram(power_diff, 15, 'FaceAlpha', 0.5);
xlabel('power DV (nats/pixel)'); ylabel('pairs');
title('vislab.nat\_stat\_bayes.dv\_power'); legend('same texture', 'different textures', ...
    'Location', 'best'); box off;
nexttile;
histogram(hist_same, 15, 'FaceAlpha', 0.5); hold on;
histogram(hist_diff, 15, 'FaceAlpha', 0.5);
xlabel('histogram DV (nats)'); ylabel('pairs');
title('lib.hist\_dv'); legend('same texture', 'different textures', ...
    'Location', 'best'); box off;
drawnow;

%% --- 3. a texture-region grouping stimulus ---------------------------------
% grouping.mk_masks grows contiguous regions over a patch grid; grouping.mk_texs
% hands out a texture to each region. Filling each patch from its region's sheet
% gives the kind of image the grouping experiment shows a subject.
grid_size = 8;                   % patches per side
n_regions = 3;                   % texture regions in the image
n_trials = 1;                    % just one image here
seed_radius_frac = 0.8;          % region seeds drawn from this fraction of the grid
fill_fraction = 1.0;             % grow until no patch is left unlabelled
region_patch_size = [32 32];     % pixels per patch, kept small so this is fast

fprintf('--- 3. Growing a %dx%d-patch image with %d texture regions ---\n', ...
    grid_size, grid_size, n_regions);

rng(cfg.seed);
[~, region_maps] = grouping.mk_masks(grid_size, n_regions, n_trials, ...
    seed_radius_frac, fill_fraction);
region_map = region_maps(:, :, 1);
region_tex = grouping.mk_texs(n_textures, n_regions, n_trials);

% fill every patch from the sheet its region was assigned
stimulus = fill_regions(region_map, region_tex(1, :), region_patch_size, ...
    patch_contrast, 1);

fprintf('    regions use Brodatz sheets: %s\n', sheet_names(region_tex(1, :)));

figure('Name', 'Demo 3: texture-region stimulus');
tiledlayout(1, 2, 'TileSpacing', 'compact');
show_regions(region_map, n_regions, 'region map (ground truth)');
show_patch(stimulus, sprintf('%dx%d px stimulus', size(stimulus, 1), size(stimulus, 2)));
drawnow;

%% --- 4. how the experiment bins patch pairs --------------------------------
% A grouping trial asks about one PAIR of patch locations. Pairs are pooled into
% bins by three geometric quantities: the separation between the two patches,
% the smaller of their two eccentricities, and the difference of their
% eccentricities. grouping.find_bin maps a pair to its bin number.
bb_dist = [1, 2, 4, 8, 16, 32];  % separation bin bounds, in patches
bb_mecc = [0, 1, 2, 4, 8, 12];   % min-eccentricity bin bounds
bb_decc = [0, 2, 4, 6, 8, 12];   % eccentricity-difference bin bounds
% The grouping experiment lays its patches out on a 16x16 grid (see
% grouping/tex_regions.m), which is what these bin bounds were chosen for, so
% use that here rather than the smaller grid part 3 drew.
bin_grid_size = 16;

fprintf('--- 4. Binning the patch pairs by distance and eccentricity ---\n');

pair_dist = grouping.mk_dist(bin_grid_size);
pair_mecc = grouping.mk_mecc(bin_grid_size);
pair_decc = grouping.mk_decc(bin_grid_size);
bin_index = grouping.mk_bindex(bb_dist, bb_mecc, bb_decc);

% The +grouping helpers number a patch at grid position (x, y) as
% (x-1)*bin_grid_size + y, so unpack the index that way rather than relying on
% MATLAB's own column-major linear indexing, which is its transpose.
reference_x = bin_grid_size/2;
reference_y = bin_grid_size/2;
reference_patch = (reference_x-1)*bin_grid_size + reference_y;
bin_map = zeros(bin_grid_size, bin_grid_size);
for x = 1:bin_grid_size
    for y = 1:bin_grid_size
        i_patch = (x-1)*bin_grid_size + y;
        if i_patch ~= reference_patch
            bin_map(x, y) = grouping.find_bin(reference_patch, i_patch, ...
                pair_dist, pair_mecc, pair_decc, bb_dist, bb_mecc, bb_decc, ...
                bin_index);
        end
    end
end
fprintf(['    reference patch %d pairs with the other %d patches, ', ...
    'falling into %d bins\n'], ...
    reference_patch, bin_grid_size^2 - 1, numel(unique(bin_map(bin_map > 0))));

figure('Name', 'Demo 4: pair bins around one reference patch');
imagesc(bin_map); axis image; colorbar;
title(sprintf('pair-bin number, relative to patch %d', reference_patch));
xlabel('patch column'); ylabel('patch row');
drawnow;

%% --- 5. grown texture region images, as in the paper's Figure 1 ------------
% Figure 1 of the lab's manuscript (notes/Texture paper biorxiv.pdf, p. 2) shows
% three grown texture region (GTR) images, each made of five randomly shaped
% regions filled with Brodatz textures, above their ground-truth region maps.
% This rebuilds that layout with the part-3 machinery. The paper's images are
% 640x640 pixels of 64-pixel blocks, so a 10x10 grid of blocks; the blocks here
% are kept at part 3's 32 pixels so this stays fast.
gtr_grid_size = 10;              % blocks per side, as in the paper's figure
gtr_n_regions = 5;               % regions per image, as in the paper's figure
gtr_n_images = 3;                % images side by side, as in the paper's figure

fprintf('--- 5. Growing %d images of %d texture regions each (paper Figure 1) ---\n', ...
    gtr_n_images, gtr_n_regions);

rng(cfg.seed);
[~, gtr_maps] = grouping.mk_masks(gtr_grid_size, gtr_n_regions, gtr_n_images, ...
    seed_radius_frac, fill_fraction);
gtr_tex = grouping.mk_texs(n_textures, gtr_n_regions, gtr_n_images);

% each image's patches get their own run of seeds, starting after the run part 3
% used, so no seed is reused across images or parts
gtr_images = cell(1, gtr_n_images);
for i_image = 1:gtr_n_images
    gtr_images{i_image} = fill_regions(gtr_maps(:, :, i_image), ...
        gtr_tex(i_image, :), region_patch_size, patch_contrast, ...
        grid_size^2 + (i_image-1)*gtr_grid_size^2 + 1);
    fprintf('    image %d uses Brodatz sheets: %s\n', i_image, ...
        sheet_names(gtr_tex(i_image, :)));
end

figure('Name', 'Demo 5: grown texture region images (paper Figure 1)');
tiledlayout(2, gtr_n_images, 'TileSpacing', 'compact');
for i_image = 1:gtr_n_images
    show_patch(gtr_images{i_image}, char('A' + i_image - 1));
end
for i_image = 1:gtr_n_images
    show_regions(gtr_maps(:, :, i_image), gtr_n_regions, 'ground truth');
end
drawnow;

%% --- 6. feature-response priors, as in the paper's Figure 5 ----------------
% Figure 5 of the manuscript (p. 7) shows the model's task-independent priors:
% the cumulative distribution of each low-level feature response, pooled over
% patches from 391 calibrated natural images. Its color panels (A-C: cone and
% opponent-color responses) need color images, which the grayscale Brodatz
% sheets cannot supply, so this rebuilds only its achromatic panels D-F, pooled
% over the 160 Brodatz patches of part 1 instead of natural images:
%   D. 1st-derivative steerable filter: magnitude, orientation, and their product.
%   E. 2nd-derivative steerable filter: the same three.
%   F. small (3x3) and large (5x5) center-surround responses, and the power at
%      a fixed spatial frequency.
% Each patch is first set to the mean and RMS contrast the paper's prior
% measurement normalizes to.
prior_mean = 128;                % gray levels
prior_contrast = 0.25;           % RMS contrast, as a fraction of the mean
filter_sd = 1;                   % steerable-filter Gaussian SD, pixels
filter_nsd = 3;                  % kernel width in SDs: 1*3 gives the paper's 3x3 filters
% feature numbering of vislab.nat_stat_bayes.edge_features and spot_features
steerable_features = [5 6 7 9 10 11];  % 1st-derivative m, o, m x o; then 2nd
cs_features = [13 14];           % 3x3 and 5x5 linear center-surround
feature_flags = zeros(1, 14);
feature_flags([steerable_features cs_features]) = 1;
% The panel-F power prior is a statement about one frequency of one texture:
% across patches of the same sheet, the power at a fixed frequency is close to
% exponentially distributed. So it is measured on its own set of patches, all
% from one sheet, each frequency's power divided by its mean across them.
n_power_patches = 40;
power_tex = same_tex(1);

fprintf('--- 6. Measuring feature-response distributions (paper Figure 5, D-F) ---\n');

prior_patches = [same_patches(:); diff_patches(:)];
n_prior_patches = numel(prior_patches);
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

figure('Name', 'Demo 6: feature-response priors (paper Figure 5, D-F)');
tiledlayout(3, 3, 'TileSpacing', 'compact');
panel_labels = {'D. 1st deriv.: magnitude', 'D. 1st deriv.: orientation', ...
    'D. 1st deriv.: product', 'E. 2nd deriv.: magnitude', ...
    'E. 2nd deriv.: orientation', 'E. 2nd deriv.: product'};
axis_labels = {'m', 'o (deg)', 'm x o'};
for i_feature = 1:numel(steerable_features)
    show_cdf(vertcat(feature_values{:, steerable_features(i_feature)}), ...
        axis_labels{mod(i_feature-1, 3) + 1}, panel_labels{i_feature});
end
show_cdf(vertcat(feature_values{:, 13}), 'cs1', 'F. center-surround, 3x3');
show_cdf(vertcat(feature_values{:, 14}), 'cs2', 'F. center-surround, 5x5');
show_cdf(relative_power, 'p (relative power)', sprintf('F. power, B%d', power_tex));
hold on;
fplot(@(p) 1 - exp(-p), xlim, 'r--', 'LineWidth', 1.5);
legend('measured', 'exponential', 'Location', 'southeast'); box off;
drawnow;

%% --- 7. the optimal decision bound, as in the paper's Figure 6 -------------
% Figure 6A of the manuscript (p. 12) plots the two foveal decision variables
% of the separated same/different task against each other -- one point per
% patch pair, same-texture and different-texture -- and draws the optimal
% quadratic decision bound between them. Part 2 already computed exactly those
% two decision variables on exactly those two conditions, so this fits the
% bound to them and redraws the panel. classify_normals comes from the
% Integrate and Classify Normal Distributions add-on, which setup installs.
%
% Only panel A is rebuilt. Panels B and D plot five human observers against the
% model across retinal eccentricity, which needs the subject files under
% exp_files/ rather than anything this demo computes. Panel C is the JOINED
% task, where the two patches abut so the model can also read the border
% between them -- a stimulus, and a set of border cues, the demo does not build.

fprintf('--- 7. Fitting the optimal decision bound (paper Figure 6A) ---\n');

bound = classify_normals([power_same hist_same], [power_diff hist_diff], ...
    'input_type', 'samp', 'samp_opt', false, 'plotmode', false);
fprintf('    %d same and %d different pairs: d'' = %.2f, error rate %.3f\n', ...
    n_pairs, n_pairs, bound.norm_d_a, bound.norm_err);

figure('Name', 'Demo 7: optimal decision bound (paper Figure 6A)');
same_dots = scatter(power_same, hist_same, 36, 'b', 'filled', ...
    'MarkerFaceAlpha', 0.6);
hold on;
diff_dots = scatter(power_diff, hist_diff, 36, 'r', 'filled', ...
    'MarkerFaceAlpha', 0.6);
xlabel('power DV (nats/pixel)'); ylabel('histogram DV (nats)');
bound_line = plot_boundary(bound.norm_bd, 2, 'plot_type', 'line');
legend([same_dots diff_dots bound_line], ...
    {'same texture', 'different textures', 'optimal bound'}, 'Location', 'best');
title(sprintf('separated task, fovea: d'' = %.2f', bound.norm_d_a)); box off;
drawnow;

%% --- 8. grown texture regions across parameters, paper's Figure 8 ----------
% Figure 8 of the manuscript (p. 13) shows six 640x640 grown texture region
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

fprintf('--- 8. Growing %d parameter variants of a region image (paper Figure 8) ---\n', ...
    numel(fig8_panels));

rng(cfg.seed);
figure('Name', 'Demo 8: grown texture regions across parameters (paper Figure 8)');
tiledlayout(2, 3, 'TileSpacing', 'compact');
% each panel's patches get their own run of seeds, starting after the run
% part 5 used, so no seed is reused across panels or parts
panel_seed = grid_size^2 + gtr_n_images*gtr_grid_size^2 + 1;
for i_panel = 1:numel(fig8_panels)
    panel = fig8_panels(i_panel);
    [~, panel_map] = grouping.mk_masks(panel.grid_size, panel.n_regions, 1, ...
        1 - panel.central_bias, panel.coverage);
    panel_tex = grouping.mk_texs(n_textures, panel.n_regions, 1);
    panel_image = fill_regions(panel_map, panel_tex(1, :), ...
        panel.patch_px*[1 1], patch_contrast, panel_seed);
    panel_seed = panel_seed + panel.grid_size^2;
    show_patch(panel_image, sprintf('%s. %d regions, %dx%d, bias %d%%, cover %d%%', ...
        panel.label, panel.n_regions, panel.grid_size, panel.grid_size, ...
        round(100*panel.central_bias), round(100*panel.coverage)));
    fprintf('    %s: %d regions on a %dx%d grid, %d%% of it claimed\n', ...
        panel.label, panel.n_regions, panel.grid_size, panel.grid_size, ...
        round(100*mean(panel_map(:) > 0)));
end
drawnow;

%% --- 9. full-scene grouping: the actual segmentation pipeline --------------
% Parts 1-2 showed the two decision variables separate same/different patch
% pairs; this runs them all the way to a segmentation. A 1024x1024 scene is cut
% into 16 Brodatz regions (one per cell of a 4x4 grid, each a random crop of a
% different sheet), split into a 16x16 grid of 64x64 patches, and the power and
% histogram decision variables are computed for every ordered pair of its 256
% patches. A fitted 2-cue quadratic boundary (data/model/brodatz_boundary.mat)
% combines each pair's two log decision variables into one, pairs scoring above
% grp_link_criterion are linked, weak links are pruned, and the remaining links
% are merged into regions by how many links each linked pair shares.
%
% grp_patch_size and grp_grid_size are kept separate from part 1's patch_size
% (a [64 64] pair) and part 3's grid_size (8): same idea, different scale, and
% this part runs last so nothing downstream reads either name.
grp_scene_size = 1024;         % scene side length, pixels
grp_sheet_size = 640;          % Brodatz sheet side length, pixels
grp_region_size = 256;         % texture region side length, pixels
grp_patch_size = 64;           % patch side length, pixels
grp_region_grid_size = grp_scene_size/grp_region_size;   % regions per scene side
grp_grid_size = grp_scene_size/grp_patch_size;            % patches per scene side
grp_n_patches = grp_grid_size^2;                          % patches in the scene
grp_link_criterion = 15;       % decision variable a pair must exceed to be linked
grp_group_criterion = 0.5;     % shared-link fraction two linked patches must exceed

fprintf('--- 9. Grouping a full %dx%d-patch scene into regions ---\n', ...
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

% power and histogram decision variables for every ordered pair of patches
grp_win = grouping.mk_win(grp_patch_size, grp_patch_size/2, 2);
grp_bin_width = 4;             % gray levels per histogram bin, a power of 2
grp_n_bins = 256/grp_bin_width;
grp_edges = (0:grp_n_bins)*grp_bin_width;
grp_patch_coords = zeros(grp_n_patches, 2);
grp_responses = zeros(grp_n_patches, grp_n_patches, 2);
for i_patch1 = 1:grp_n_patches
    row1 = floor((i_patch1-1)/grp_grid_size) + 1;
    col1 = i_patch1 - (row1-1)*grp_grid_size;
    row1_lo = (row1-1)*grp_patch_size+1;  col1_lo = (col1-1)*grp_patch_size+1;
    grp_patch_coords(i_patch1, :) = [row1_lo, col1_lo];
    patch1 = grp_scene(row1_lo:row1_lo+grp_patch_size-1, col1_lo:col1_lo+grp_patch_size-1);
    for i_patch2 = 1:grp_n_patches
        row2 = floor((i_patch2-1)/grp_grid_size) + 1;
        col2 = i_patch2 - (row2-1)*grp_grid_size;
        row2_lo = (row2-1)*grp_patch_size+1;  col2_lo = (col2-1)*grp_patch_size+1;
        patch2 = grp_scene(row2_lo:row2_lo+grp_patch_size-1, col2_lo:col2_lo+grp_patch_size-1);
        grp_responses(i_patch1, i_patch2, 1) = vislab.nat_stat_bayes.dv_power( ...
            patch1.*grp_win, patch2.*grp_win, noise_const, grp_patch_size);
        grp_responses(i_patch1, i_patch2, 2) = lib.hist_dv(patch1, patch2, grp_edges);
    end
end

% combine into one decision variable per pair via the fitted Brodatz boundary
grp_brodatz_bd = load(fullfile(cfg.paths.model, 'brodatz_boundary.mat')).brodatz_bd;
grp_dv = zeros(grp_n_patches, grp_n_patches);
for i_patch1 = 1:grp_n_patches
    for i_patch2 = 1:grp_n_patches
        if i_patch1 ~= i_patch2
            xx = [log(grp_responses(i_patch1, i_patch2, 1)); ...
                  log(grp_responses(i_patch1, i_patch2, 2))];
            grp_dv(i_patch1, i_patch2) = xx'*grp_brodatz_bd.q2*xx + xx'*grp_brodatz_bd.q1 ...
                + grp_brodatz_bd.q0;
        end
    end
end

% threshold into links, then merge linked patches into groups by shared links
grp_links = grouping.thresh(grp_dv, grp_n_patches, grp_link_criterion);
grp_groups = zeros(grp_n_patches, 2+grp_n_patches, 2);   % group#, #links, link1, link2, ...
for i_patch1 = 1:grp_n_patches
    for i_patch2 = 1:grp_n_patches
        if grp_links(i_patch1, i_patch2) == 1
            n_links = grp_groups(i_patch1, 2, 1) + 1;
            grp_groups(i_patch1, 2, 1) = n_links;
            grp_groups(i_patch1, 2+n_links, 1) = i_patch2;
            grp_groups(i_patch1, 2+n_links, 2) = grp_dv(i_patch1, i_patch2);
        end
    end
end
for i_patch = 1:grp_n_patches
    n_links_a = grp_groups(i_patch, 2, 1);
    links_a = grp_groups(i_patch, 3:3+n_links_a-1, 1);
    for i_link = 1:n_links_a
        n_links_b = grp_groups(links_a(i_link), 2, 1);
        links_b = grp_groups(links_a(i_link), 3:3+n_links_b-1, 1);
        n_common = grouping.nlsame(links_a, n_links_a, links_b, n_links_b);
        link_ratio = 2*n_common/(n_links_a+n_links_b);
        if n_links_a > 1 && link_ratio < grp_group_criterion && i_patch ~= links_a(i_link)
            grp_links(i_patch, links_a(i_link)) = 0;
        end
    end
end
grp_group_num = 0;
for i_patch = 1:grp_n_patches
    n_links_a = grp_groups(i_patch, 2, 1);
    links_a = grp_groups(i_patch, 3:3+n_links_a-1, 1);
    for i_link = 1:n_links_a
        n_links_b = grp_groups(links_a(i_link), 2, 1);
        links_b = grp_groups(links_a(i_link), 3:3+n_links_b-1, 1);
        n_common = grouping.nlsame(links_a, n_links_a, links_b, n_links_b);
        link_ratio = 2*n_common/(n_links_a+n_links_b);
        if n_links_a > 1 && link_ratio > grp_group_criterion
            if grp_groups(i_patch, 1, 1) == 0
                grp_group_num = grp_group_num + 1;
                grp_groups(i_patch, 1, 1) = grp_group_num;
            end
            if grp_groups(links_a(i_link), 1, 1) == 0
                grp_groups(links_a(i_link), 1, 1) = grp_groups(i_patch, 1, 1);
            end
        end
    end
end

% paint the group map and show it next to the scene it came from
grp_group_img = zeros(grp_scene_size, grp_scene_size);
for i_patch = 1:grp_n_patches
    xx = grp_patch_coords(i_patch, 1);  yy = grp_patch_coords(i_patch, 2);
    grp_group_img(xx:xx+grp_patch_size-1, yy:yy+grp_patch_size-1) = grp_groups(i_patch, 1);
end
fprintf('    %d patches merged into %d groups\n', grp_n_patches, grp_group_num);

figure('Name', 'Demo 9: full-scene grouping');
tiledlayout(1, 2, 'TileSpacing', 'compact');
nexttile;
imagesc(grp_scene); axis image off; colormap(gca, gray); title('scene (16 Brodatz regions)');
nexttile;
imagesc(grp_group_img); axis image off; colormap(gca, parula); title(sprintf('%d groups found', grp_group_num));
drawnow;

%% --- what you just saw -----------------------------------------------------
fprintf('\n=== what you just saw ===\n');
fprintf(['1. Brodatz texture patches drawn by lib.texture_patch, in pairs from the\n', ...
    '   same sheet and from two different sheets (figure 1).\n']);
fprintf(['2. Two of the model''s same/different decision variables scored on those\n', ...
    '   pairs. Both separate the two conditions (AUC above, figure 2): this is the\n', ...
    '   discrimination the psychophysics in +experiment measures in humans.\n']);
fprintf(['3. A texture-region stimulus grown by grouping.mk_masks and textured by\n', ...
    '   grouping.mk_texs -- the ground-truth region map and the image a subject\n', ...
    '   (or the model) actually sees (figure 3).\n']);
fprintf(['4. The distance/eccentricity bins the grouping experiment pools its patch\n', ...
    '   pairs into, shown around one reference patch (figure 4).\n']);
fprintf(['5. Three images of five grown Brodatz texture regions above their\n', ...
    '   ground-truth maps: the layout of Figure 1 of the manuscript, the kind of\n', ...
    '   image the full model segments (figure 5).\n']);
fprintf(['6. The cumulative distributions of the model''s low-level feature\n', ...
    '   responses -- steerable-filter magnitude and orientation, center-surround,\n', ...
    '   and power at a fixed frequency -- the priors of Figure 5 (D-F) of the\n', ...
    '   manuscript, measured on Brodatz patches instead of natural images; the\n', ...
    '   color panels A-C need color images and are left out (figure 6).\n']);
fprintf(['7. The optimal decision bound between same- and different-texture pairs\n', ...
    '   in the two decision variables of part 2: panel A of Figure 6 of the\n', ...
    '   manuscript (figure 7). Its other panels need the human subject files or\n', ...
    '   the joined-task border cues, and are left out.\n']);
fprintf(['8. The same region growing run at three region counts, two block sizes,\n', ...
    '   and one center-biased, half-covered setting: five of the six panels of\n', ...
    '   Figure 8 of the manuscript (figure 8). The sixth needs an orientation\n', ...
    '   bias, which this repo does not implement.\n']);
fprintf(['9. The full grouping pipeline run on one whole scene: part 2''s decision\n', ...
    '   variables over every patch pair, combined by a fitted boundary into\n', ...
    '   links, and merged into the regions shown alongside the scene (figure 9) --\n', ...
    '   this is the actual task the model performs, not a controlled comparison.\n']);
fprintf('\nDemo complete. See the README for the full experiments and analyses.\n');

%% --- local helpers ---------------------------------------------------------

function show_patch(img, label)
% One tile of a tiled layout showing a normalized-luminance image in gray.
% imagesc rather than imshow: it needs no Image Processing Toolbox and does not
% warn about magnification inside a docked figure.
    nexttile;
    imagesc(img, [0 1]);
    axis image off;
    colormap(gca, gray);
    title(label);
end

function show_regions(region_map, n_regions, label)
% One tile of a tiled layout showing a region-label map, one flat color per
% region. The color limits are pinned to 1:n_regions so that each region keeps
% its own color even if a map happens not to use every label.
    nexttile;
    imagesc(region_map, [1 n_regions]);
    axis image off;
    colormap(gca, parula(n_regions));
    title(label);
end

function show_cdf(values, x_label, label)
% One tile of a tiled layout showing the empirical cumulative distribution of
% values as a black line, as in the paper's Figure 5. Drawn through 500 evenly
% spaced order statistics rather than every value, and with the x axis trimmed
% to the central 99% of the values so a few outliers do not squash the curve.
    nexttile;
    sorted = sort(values(:));
    n_values = numel(sorted);
    keep = unique(round(linspace(1, n_values, 500)));
    plot(sorted(keep), keep/n_values, 'k', 'LineWidth', 1.5);
    xlim(sorted([ceil(0.005*n_values), floor(0.995*n_values)])');
    ylim([0 1]);
    xlabel(x_label); ylabel('pr');
    title(label); box off;
end

function stimulus = fill_regions(region_map, region_tex, patch_size, contrast, first_seed)
% Fill every patch of a region-label map from the Brodatz sheet its region was
% assigned (region_tex(k) for region k), to build a texture-region image.
% Patches are drawn in row order with seeds first_seed, first_seed+1, ..., so
% the image is reproducible and two calls with disjoint seed runs differ.
% A patch labelled 0 was never claimed -- grouping.mk_masks stops growing once
% its fill_fraction is reached -- and is left at mid gray.
    [n_rows, n_cols] = size(region_map);
    stimulus = 0.5*ones(n_rows*patch_size(1), n_cols*patch_size(2));
    for i_row = 1:n_rows
        for i_col = 1:n_cols
            region = region_map(i_row, i_col);
            if region == 0
                continue
            end
            patch_img = lib.texture_patch('tex_num', region_tex(region), ...
                'patch_size', patch_size, 'seed', ...
                first_seed + (i_row-1)*n_cols + (i_col-1), 'contrast', contrast);
            rows = (i_row-1)*patch_size(1) + (1:patch_size(1));
            cols = (i_col-1)*patch_size(2) + (1:patch_size(2));
            stimulus(rows, cols) = patch_img;
        end
    end
end

function names = sheet_names(tex_nums)
% Brodatz sheet numbers as one printable list, e.g. 'B36, B16, B34'.
    names = strjoin(arrayfun(@(t) sprintf('B%d', t), tex_nums, ...
        'UniformOutput', false), ', ');
end

function edges = pair_edges(patch_a, patch_b, n_bins)
% Histogram bin edges spanning both patches, for lib.hist_dv. Widened by a hair
% at each end so that histcounts cannot drop the extreme pixels.
    lo = min(min(patch_a, [], 'all'), min(patch_b, [], 'all'));
    hi = max(max(patch_a, [], 'all'), max(patch_b, [], 'all'));
    pad = 1e-9*max(1, hi - lo);
    edges = linspace(lo - pad, hi + pad, n_bins + 1);
end

function area = roc_area(scores_negative, scores_positive)
% Area under the ROC curve, computed directly as the probability that a random
% positive scores above a random negative (ties counted as half).
    comparison = scores_positive(:)' > scores_negative(:);
    ties = scores_positive(:)' == scores_negative(:);
    area = mean(comparison(:)) + 0.5*mean(ties(:));
end
