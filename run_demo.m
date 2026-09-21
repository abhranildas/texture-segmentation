% RUN_DEMO  Short demonstration of the texture-segmentation model.
%
%   Run it (from anywhere):   >> run <path-to-repo>/run_demo.m
%   or:   >> cd <repo>; setup; run run_demo.m
%
%   This is a script, not a function: it takes no arguments, asks no questions,
%   and leaves its results in the base workspace and in four figure windows.
%   It runs in a few seconds and needs no large downloads -- everything it uses
%   comes from the Brodatz texture sheets that ship inside the sibling
%   vislab-common repo, which setup clones automatically. The ~19 GB natural
%   image set is NOT needed.
%
% What it does, in four parts:
%   1. Texture patches. Draws pairs of 64x64 Brodatz patches -- some pairs from
%      the SAME sheet, some from two DIFFERENT sheets -- with lib.texture_patch.
%   2. Decision variables. Runs two of the model's same/different decision
%      variables over those pairs: lib.power_dv (Fourier power spectrum) and
%      lib.hist_dv (gray-level histogram log-likelihood ratio). Both should
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
%
%   It does NOT run the Psychtoolbox experiments (+experiment, which need a
%   live display and a subject) or any of the natural-image analyses
%   (+general). See the README for those.
%
%   Reproducible: everything is drawn under rng(cfg.seed), and every call to
%   lib.texture_patch is given an explicit seed, so repeated runs give
%   identical numbers and identical images.
%
% See also SETUP, CONFIG, LIB.TEXTURE_PATCH, LIB.POWER_DV, LIB.HIST_DV,
%   GROUPING.MK_MASKS, GROUPING.MK_TEXS, GROUPING.FIND_BIN

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
noise_const = 10;                % power_dv's spectral noise-suppression constant
n_hist_bins = 32;                % gray-level bins for hist_dv

fprintf('--- 2. Computing the power and histogram decision variables ---\n');

power_same = zeros(n_pairs, 1);
power_diff = zeros(n_pairs, 1);
hist_same = zeros(n_pairs, 1);
hist_diff = zeros(n_pairs, 1);
for i_pair = 1:n_pairs
    power_same(i_pair) = lib.power_dv(same_patches{i_pair, 1}, ...
        same_patches{i_pair, 2}, noise_const);
    power_diff(i_pair) = lib.power_dv(diff_patches{i_pair, 1}, ...
        diff_patches{i_pair, 2}, noise_const);
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
fprintf('    %-18s  %7.3f +- %5.3f   %7.3f +- %5.3f   %.3f\n', 'power_dv', ...
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
title('lib.power_dv'); legend('same texture', 'different textures', ...
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
stimulus = zeros(grid_size*region_patch_size(1), grid_size*region_patch_size(2));
patch_seed = 1;
for i_row = 1:grid_size
    for i_col = 1:grid_size
        tex_num = region_tex(1, region_map(i_row, i_col));
        patch_img = lib.texture_patch('tex_num', tex_num, ...
            'patch_size', region_patch_size, 'seed', patch_seed, ...
            'contrast', patch_contrast);
        rows = (i_row-1)*region_patch_size(1) + (1:region_patch_size(1));
        cols = (i_col-1)*region_patch_size(2) + (1:region_patch_size(2));
        stimulus(rows, cols) = patch_img;
        patch_seed = patch_seed + 1;
    end
end

fprintf('    regions use Brodatz sheets: %s\n', ...
    strjoin(arrayfun(@(t) sprintf('B%d', t), region_tex(1, :), ...
    'UniformOutput', false), ', '));

figure('Name', 'Demo 3: texture-region stimulus');
tiledlayout(1, 2, 'TileSpacing', 'compact');
nexttile;
imagesc(region_map); axis image off; colormap(gca, lines(n_regions));
title('region map (ground truth)');
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
