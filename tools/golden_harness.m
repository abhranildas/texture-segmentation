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
%     2 (+lib)               steerable_filter, steerable_grad, local_sd,
%                            texture_patch, edge_props_stim (error identity
%                            only -- see below)
%     5 (root cluster C)     mk_win, mk_contour, thresh, nlsame, re, rs, rp,
%                            rs_new (error identity only -- see below)
%
%   The first three groups run on small synthetic inputs; texture_patch and
%   everything from re onward run on real, small, git-tracked Brodatz patches
%   read through cfg.paths.textures, never on the ~19 GB natural-image set.
%
%   Three entry points have no runnable path at all and are covered by the
%   IDENTITY OF THE ERROR THEY RAISE rather than by an output checksum:
%   edge_props_stim's 'tex' path (bug B2.15), its 'camo' default (B3.6) and
%   rs_new (B3.13). That pins where each one dies, so a Stage 2 edit cannot
%   move it; their numeric outputs stay unverified until Stage 4 fixes them.
%
%   Not covered, and pattern-check-only for Stage 2: all of +experiment
%   (needs Psychtoolbox and a live display), all of +general (see bugs
%   B2.12/B2.13 and item S2.5 -- not a data problem), edge_dv.m (B2.1: calls
%   a function that does not exist), contour_blur_estimation.m (a figure
%   script with no callable entry point), texture_grouping.m and setup.m
%   (driver / path-modifying scripts). Also not covered: +grouping/mk_texs.m,
%   find_xy.m, effective_distance.m, find_tex_regions.m and the +grouping
%   stimulus scripts, which are scripts or need real texture sheets.
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
            bins(i0, j0) = grouping.find_bin(i0, j0, dist, mecc, decc, ...
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
            xy_flags(x, y, trial) = grouping.check_xy(x, y, trial, maps_2, grid_size);
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
            [chk_flag, x_out, y_out] = grouping.check_tlst(dprm, x, y, free_map, grid_size);
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
% Real-data entry points. Everything below reads the small, git-tracked
% Brodatz sheets through cfg.paths.textures -- two sheets, four 64x64 crops.
% The natural-image set is never touched.
% -------------------------------------------------------------------------

brodatz_dir = fullfile(cfg.paths.textures, 'brodatz');
has_brodatz = isfolder(brodatz_dir) && isfile(fullfile(brodatz_dir, 'B1.gif'));
if ~has_brodatz
    warning('golden_harness:noTextures', ...
        ['Brodatz sheets not found at %s -- every real-data entry point ', ...
         '(texture_patch, re, rs, rs_new, rp, edge_props_stim) skipped.'], ...
        brodatz_dir);
end

% texture_patch. Its mean and SD are fixed by construction ('lum' and 'cont'),
% so a plain checksum would pass whatever pixels came back; the reduction is
% therefore position-weighted as well, which no reshuffle or wrong crop can
% survive. Two calls: one fully explicit, and one taking the 'rand' defaults
% for texture number and seed, which is the only branch here that draws from
% the RNG (and the only reason a seed is set immediately before it).
if has_brodatz
    rng(cfg.seed);
    [tex_patch, tex_seed, tex_number, tex_coords] = lib.texture_patch( ...
        'tex_num', 3, 'patch_sz', [64 64], 'seed', 1, 'cont', 0.12);
    golden.texture_patch_checksum = sum(tex_patch, 'all');
    golden.texture_patch_weighted_checksum = weighted_checksum(tex_patch);
    golden.texture_patch_sq_checksum = sum(tex_patch.^2, 'all');
    golden.texture_patch_size = size(tex_patch);
    golden.texture_patch_seed = tex_seed;
    golden.texture_patch_tex_num = tex_number;
    golden.texture_patch_coords = tex_coords;

    rng(cfg.seed);
    [rand_patch, rand_seed, rand_tex_num, rand_coords] = lib.texture_patch( ...
        'patch_sz', [32 32], 'cont', 0.12);
    golden.texture_patch_rand_weighted_checksum = weighted_checksum(rand_patch);
    golden.texture_patch_rand_seed = rand_seed;
    golden.texture_patch_rand_tex_num = rand_tex_num;
    golden.texture_patch_rand_coords = rand_coords;
else
    golden.texture_patch_checksum = [];
    golden.texture_patch_weighted_checksum = [];
    golden.texture_patch_sq_checksum = [];
    golden.texture_patch_size = [];
    golden.texture_patch_seed = [];
    golden.texture_patch_tex_num = [];
    golden.texture_patch_coords = [];
    golden.texture_patch_rand_weighted_checksum = [];
    golden.texture_patch_rand_seed = [];
    golden.texture_patch_rand_tex_num = [];
    golden.texture_patch_rand_coords = [];
end

% Gray-level patches for the decision-variable functions, cut at fixed
% offsets so no RNG draw is involved: two crops from one sheet (a "same
% texture" pair) and one from a second sheet (a "different texture" pair).
% Raw gray levels rather than texture_patch's normalized [0, 1] output,
% because that is what these functions and the efficient-coding histogram
% bins below were written for (+general/simulate_discrimination.m:151-174).
patch_size_px = 64;
if has_brodatz
    sheet_a = double(imread(fullfile(brodatz_dir, 'B1.gif')));
    sheet_b = double(imread(fullfile(brodatz_dir, 'B2.gif')));
    patch_a1 = sheet_a(1:patch_size_px, 1:patch_size_px);
    patch_a2 = sheet_a(301:300+patch_size_px, 201:200+patch_size_px);
    patch_b1 = sheet_b(1:patch_size_px, 1:patch_size_px);
end

% rp and rs -- pure, no toolbox, no RNG.
if has_brodatz
    rng(cfg.seed);
    win_rp = mk_win(patch_size_px, patch_size_px/4, 1);
    golden.rp_diff = rp(patch_a1, patch_b1, 10, patch_size_px, win_rp);
    golden.rp_same = rp(patch_a1, patch_a2, 10, patch_size_px, win_rp);

    rng(cfg.seed);
    golden.rs_diff = rs(patch_a1, patch_b1, patch_size_px);
    golden.rs_same = rs(patch_a1, patch_a2, patch_size_px);
else
    golden.rp_diff = [];
    golden.rp_same = [];
    golden.rs_diff = [];
    golden.rs_same = [];
end

% re needs edge/imgradient/bwconncomp/labelmatrix from the Image Processing
% Toolbox, so it is gated. The gradient-magnitude threshold is 50 rather than
% anything lower on purpose: below about 30 these patches yield more contours
% in patch 1 than in patch 2, and re.m's patch-2 loop runs to patch 1's
% contour count (bug B1.2), so the call dies on an out-of-range index. Same
% precaution as the find_bin sweep above, which is sized to stay inside B3.2.
has_ipt_edges = exist('edge', 'file') && exist('imgradient', 'file') && ...
    exist('bwconncomp', 'file') && exist('labelmatrix', 'file');
if has_brodatz && has_ipt_edges
    rng(cfg.seed);
    golden.re_diff = re(patch_a1, patch_b1, patch_size_px, 2, 8, 50);
    golden.re_same = re(patch_a1, patch_a2, patch_size_px, 2, 8, 50);
else
    golden.re_diff = [];
    golden.re_same = [];
end

% rs_new and edge_props_stim have no runnable path: each one errors before
% returning anything (B3.13, B2.15, B3.6 -- see this file's header). What is
% captured is therefore the identity of the error, which pins where each one
% dies so that a Stage 2 edit cannot silently move it.
if has_brodatz
    rng(cfg.seed);
    golden.rs_new_error_id = error_id(@() rs_new(patch_a1, patch_b1, ...
        patch_size_px, 8));
else
    golden.rs_new_error_id = [];
end

% edge_props_stim additionally needs the efficient-coding histogram bins and
% (through steerable_grad/local_sd/imshow) the Image Processing Toolbox. It
% is called exactly as +general/simulate_discrimination.m:171-174 calls it,
% minus the OTF prefilter, which would pull in vislab.lib.otf_filter without
% changing what is being pinned here. Its four figures are closed afterwards,
% and only the ones it opened.
bins_file = fullfile(cfg.paths.data_root, 'nat_im_eff_coding.mat');
if has_brodatz && has_ipt_edges && exist('imshow', 'file') && isfile(bins_file)
    bins = load(bins_file, 'grad_m_bins', 'grad_o_bins', 'grad_p_bins');
    figs_before = findobj(0, 'Type', 'figure');

    rng(cfg.seed);
    golden.edge_props_stim_tex_error_id = error_id(@() ...
        edge_props_stim_probe(cat(3, patch_a1, patch_b1), 'tex', bins));

    rng(cfg.seed);
    golden.edge_props_stim_camo_error_id = error_id(@() ...
        edge_props_stim_probe(patch_a1, 'camo', bins));

    figs_after = findobj(0, 'Type', 'figure');
    for i_fig = 1:numel(figs_after)
        if ~any(figs_after(i_fig) == figs_before)
            close(figs_after(i_fig));
        end
    end
else
    golden.edge_props_stim_tex_error_id = [];
    golden.edge_props_stim_camo_error_id = [];
end

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

% -------------------------------------------------------------------------
% Local helpers
% -------------------------------------------------------------------------

function checksum = weighted_checksum(x)
% Position-weighted checksum, for arrays whose plain sum is fixed by
% construction (texture_patch's output has an imposed mean and SD, so a plain
% checksum would match whatever pixels came back).
    checksum = sum(x.*reshape(1:numel(x), size(x)), 'all');
end

function id = error_id(fn)
% Identifier of the error FN raises, or '' if it unexpectedly succeeds. The
% success case is captured rather than ignored: if a fix later makes one of
% these entry points run, the replay fails and says so.
    try
        fn();
        id = '';
    catch err
        id = err.identifier;
    end
end

function edge_props_stim_probe(stim, stim_type, bins)
% One edge_props_stim call asking for its 15 live outputs, wrapped so that
% error_id can call it with no arguments and no outputs.
    out = cell(1, 15);
    [out{:}] = lib.edge_props_stim(stim, 'stim_type', stim_type, ...
        'pad_val', 128, 'grad_mag_bins', bins.grad_m_bins, ...
        'grad_or_bins', bins.grad_o_bins, 'grad_prod_bins', bins.grad_p_bins);
end
