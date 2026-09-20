function golden = golden_harness(mode, golden_file)
% GOLDEN_HARNESS  Capture or replay golden outputs for this repo's Stage-2 checks.
%   golden = golden_harness('capture', golden_file)
%   golden = golden_harness('replay', golden_file)
%
%   Calls entry points directly (never through texture_grouping.m or any
%   Psychtoolbox launcher) under an explicit rng(cfg.seed), and either saves
%   their reduced outputs to GOLDEN_FILE ('capture') or reloads GOLDEN_FILE and
%   asserts isequal against a fresh run ('replay').
%
%   Entry points, by tranche (docs/repo-cleanup.md sections 1 and 3.1.2):
%     9 (config/driver)      config
%     3 (+grouping helpers)  mk_dist, mk_mecc, mk_decc, mk_bindex, mk_masks,
%                            find_bin, check_xy, check_tlst
%     2 (+lib)               steerable_filter, steerable_grad, local_sd
%     5 (root cluster C)     mk_win, mk_contour, thresh, nlsame
%
%   Not covered, and pattern-check-only for Stage 2: all of +experiment
%   (needs Psychtoolbox and a live display), all of +general (needs the ~19 GB
%   natural-image set or exp_files/Brodatz data), +lib/texture_patch.m,
%   +lib/edge_props_stim.m, and the root files that consume real images
%   (re.m, rs.m, rs_new.m, rp.m, edge_dv.m, contour_blur_estimation.m,
%   texture_grouping.m). Also not covered: +grouping/mk_texs.m, find_xy.m,
%   effective_distance.m, find_tex_regions.m and the +grouping stimulus
%   scripts, which are scripts or need real texture sheets.
%
% Inputs
%   mode         'capture' or 'replay', char
%   golden_file  path to a .mat file to write to / read from, char
% Output
%   golden  struct of reduced entry-point outputs (checksums and size vectors),
%           as captured or as freshly computed depending on MODE
%
% See also CANON, CHECK_STAGE1, ASSERT_RENAME_BIJECTION

setup();
cfg = config();

% Field names below use the POST-RENAME function names (find_bin, check_xy,
% check_tlst) even though tranche 0.1.1 has not run yet. Golden-struct fields
% are dot-qualified, so check_stage1's reverse-rename regex deliberately skips
% them -- renaming them later would make the check fail on a correct edit, and
% would also invalidate the captured reference. Naming them final from the
% start avoids both.

% -------------------------------------------------------------------------
% Shared synthetic inputs. Small and fully synthetic -- no disk reads.
% -------------------------------------------------------------------------

grid_size = 8;                      % patch-grid side length, in patches
bb_dist = [1, 2, 4, 8, 16, 32];     % distance bin bounds, as mk_texseg_session.m:23
bb_mecc = [0, 1, 2, 4, 8, 12];      % min-eccentricity bin bounds
bb_decc = [0, 2, 4, 6, 8, 12];      % eccentricity-difference bin bounds

% -------------------------------------------------------------------------
% config -- numeric constants only. cfg.paths.* are absolute and therefore
% machine-dependent, so only their field NAMES go into the reference.
% -------------------------------------------------------------------------

golden.config_path_fields = sort(fieldnames(cfg.paths));
golden.config_optics = [cfg.optics.ppd, cfg.optics.pupil_diameter, ...
    cfg.optics.wavelength];
golden.config_rgb_to_lms_checksum = sum(cfg.color.rgb_to_lms, 'all');
golden.config_rgb_to_lms_size = size(cfg.color.rgb_to_lms);
golden.config_norm = [cfg.norm.target_mean, cfg.norm.target_contrast];
golden.config_seed = cfg.seed;

% -------------------------------------------------------------------------
% +grouping geometry matrices -- deterministic, no RNG use.
% -------------------------------------------------------------------------

rng(cfg.seed);
dist = grouping.mk_dist(grid_size);
golden.mk_dist_checksum = sum(dist, 'all');
golden.mk_dist_size = size(dist);

rng(cfg.seed);
mecc = grouping.mk_mecc(grid_size);
golden.mk_mecc_checksum = sum(mecc, 'all');
golden.mk_mecc_size = size(mecc);

rng(cfg.seed);
decc = grouping.mk_decc(grid_size);
golden.mk_decc_checksum = sum(decc, 'all');
golden.mk_decc_size = size(decc);

rng(cfg.seed);
bindex = grouping.mk_bindex(bb_dist, bb_mecc, bb_decc);
golden.mk_bindex_checksum = sum(bindex, 'all');
golden.mk_bindex_size = size(bindex);

% -------------------------------------------------------------------------
% find_bin -- every ordered pair of distinct patch locations on the grid.
% -------------------------------------------------------------------------

rng(cfg.seed);
n_loc = grid_size^2;
bins = zeros(n_loc, n_loc);
for i0 = 1:n_loc
    for j0 = 1:n_loc
        if i0 ~= j0
            bins(i0, j0) = grouping.fnd_bin(i0, j0, dist, mecc, decc, ...
                bb_dist, bb_mecc, bb_decc, bindex);
        end
    end
end
golden.find_bin_checksum = sum(bins, 'all');
golden.find_bin_n_distinct = numel(unique(bins(:)));
golden.find_bin_max = max(bins, [], 'all');

% -------------------------------------------------------------------------
% mk_masks -- the one RNG-consuming entry point here; seeded immediately
% before, and kept small so its region-growing loops terminate quickly.
% -------------------------------------------------------------------------

rng(cfg.seed);
[masks, maps] = grouping.mk_masks(grid_size, 2, 2, 0.8, 0.25);
golden.mk_masks_masks_checksum = sum(masks, 'all');
golden.mk_masks_masks_size = size(masks);
golden.mk_masks_maps_checksum = sum(maps, 'all');
golden.mk_masks_maps_size = size(maps);

% -------------------------------------------------------------------------
% check_xy / check_tlst -- swept over a fixed synthetic label map, so the
% reduction covers every branch rather than one arbitrary location.
% -------------------------------------------------------------------------

label_map = repmat([1 1 1 1 2 2 2 2], grid_size, 1);   % vertical boundary at x=4|5
maps_2 = cat(3, label_map, label_map');

rng(cfg.seed);
xy_flags = zeros(grid_size, grid_size, 2);
for trial = 1:2
    for x = 1:grid_size
        for y = 1:grid_size
            xy_flags(x, y, trial) = grouping.chk_xy(x, y, trial, maps_2, grid_size);
        end
    end
end
golden.check_xy_checksum = sum(xy_flags, 'all');
golden.check_xy_size = size(xy_flags);

rng(cfg.seed);
free_map = label_map;
free_map(3:6, 3:6) = 0;            % a block of unfilled locations to find
tlst_out = zeros(4, grid_size, grid_size, 3);
for dprm = 1:4
    for x = 1:grid_size
        for y = 1:grid_size
            [chk_flag, x_out, y_out] = grouping.chktlst(dprm, x, y, free_map, grid_size);
            tlst_out(dprm, x, y, :) = [chk_flag, x_out, y_out];
        end
    end
end
golden.check_tlst_checksum = sum(tlst_out, 'all');
golden.check_tlst_flag_sum = sum(tlst_out(:, :, :, 1), 'all');
golden.check_tlst_size = size(tlst_out);

% -------------------------------------------------------------------------
% +lib filters. steerable_filter is pure; steerable_grad and local_sd need
% stdfilt/padarray from the Image Processing Toolbox, so they are gated.
% -------------------------------------------------------------------------

kernel_size = [2, 3];              % [kernel_sd in px, truncation in SDs]

rng(cfg.seed);
filt = lib.steerable_filter(kernel_size);
golden.steerable_filter_checksum = sum(filt, 'all');
golden.steerable_filter_abs_checksum = sum(abs(filt), 'all');
golden.steerable_filter_size = size(filt);

rng(cfg.seed);
stim = 128 + 20 * randn(32, 32);   % synthetic mid-grey image with texture

if exist('stdfilt', 'file') && exist('padarray', 'file')
    rng(cfg.seed);
    sd_map = lib.local_sd(stim, kernel_size);
    golden.local_sd_checksum = sum(sd_map, 'all');
    golden.local_sd_size = size(sd_map);

    % steerable_grad leaves a NaN border (it preallocates nan(M,N,2) and
    % pastes only the 'valid' region), so reduce with omitnan and record the
    % NaN count separately -- a plain sum would be NaN and compare useless.
    rng(cfg.seed);
    grad = lib.steerable_grad(stim, 'kernel_size', kernel_size);
    golden.steerable_grad_checksum = sum(grad, 'all', 'omitnan');
    golden.steerable_grad_nan_count = sum(isnan(grad), 'all');
    golden.steerable_grad_size = size(grad);
else
    golden.local_sd_checksum = [];
    golden.local_sd_size = [];
    golden.steerable_grad_checksum = [];
    golden.steerable_grad_nan_count = [];
    golden.steerable_grad_size = [];
    warning('golden_harness:noToolbox', ...
        ['Image Processing Toolbox (stdfilt/padarray) not found -- ', ...
         'local_sd and steerable_grad entry points skipped.']);
end

% -------------------------------------------------------------------------
% Root cluster-C utilities -- all pure, all deterministic.
% -------------------------------------------------------------------------

rng(cfg.seed);
win_radial = mk_win(16, 4, 1);
golden.mk_win_radial_checksum = sum(win_radial, 'all');
golden.mk_win_radial_size = size(win_radial);

rng(cfg.seed);
win_separable = mk_win(16, 4, 2);
golden.mk_win_separable_checksum = sum(win_separable, 'all');
golden.mk_win_separable_size = size(win_separable);

% mk_contour needs an open chain of 8-connected pixels: it scans for the first
% row of the link map with exactly one link and uses it as the chain's start,
% so a closed loop would make that scan run off the end.
rng(cfg.seed);
n_px = 10;
px_x = 1:n_px;
px_y = ones(1, n_px);
[contour_out, lnks, n_con] = mk_contour(n_px, px_y, px_x);
golden.mk_contour_checksum = sum(contour_out, 'all');
golden.mk_contour_lnks_checksum = sum(lnks, 'all');
golden.mk_contour_n_con = n_con;

rng(cfg.seed);
rsp = rand(grid_size, grid_size);
r_thresh = thresh(rsp, grid_size, 0.5);
golden.thresh_checksum = sum(r_thresh, 'all');
golden.thresh_size = size(r_thresh);

rng(cfg.seed);
lnk_a = [1, 3, 5, 7, 9];
lnk_b = [2, 3, 5, 8];
golden.nlsame_value = nlsame(lnk_a, numel(lnk_a), lnk_b, numel(lnk_b));

% -------------------------------------------------------------------------

if strcmp(mode, 'capture')
    save(golden_file, 'golden');
elseif strcmp(mode, 'replay')
    ref = load(golden_file, 'golden');
    assert(isequal(ref.golden, golden), 'golden_harness:mismatch', ...
        'golden output changed -- this edit is not behaviour-preserving');
else
    error('golden_harness:mode', 'mode must be ''capture'' or ''replay''');
end
end
