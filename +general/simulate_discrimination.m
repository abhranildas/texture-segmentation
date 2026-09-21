%SIMULATE_DISCRIMINATION  Simulate texture discrimination from image patches.
%   run('+general/simulate_discrimination.m')
%
%   Draws same-texture and different-texture patch pairs from the 60 Brodatz
%   texture sheets, computes a decision variable for each cue (power spectrum,
%   greyscale histogram, gradient magnitude / orientation / product at five
%   scales, and four edge-contour properties), and uses classify_normals to
%   fit a quadratic discrimination boundary per cue and one combining them
%   all. The three %% sections are meant to be run in order, as cells:
%
%     1. simulate the trials and fit the boundaries;
%     2. overlay one real subject's experimental trials on the power-vs-
%        histogram plot;
%     3. classify one freshly drawn pair of patches using the fitted
%        boundaries, and title the figure green or red by whether it was
%        right.
%
%   This is a script, not a function: every parameter is hardcoded below and
%   every result is left in the workspace. Converting it into a proper
%   function is Stage 3 item S2.5.
%
%   Inputs: none. The parameters are the constants at the top of each cell --
%     n_tex       - number of texture sheets (count)
%     image_size  - texture sheet side length (pixels)
%     patch_size  - patch side length (pixels)
%     ppd         - pixels per degree, for OTF filtering
%     n_samp      - patch pairs drawn per texture pair (count)
%     noise_const - weak-power suppression constant added to the unit-mean
%                   normalized power spectrum (dimensionless)
%     eps_offset  - small constant added inside a log to prevent log(0)
%     pad_val     - mean grey level used to pad patches before taking
%                   gradients (grey levels, 0 to 255)
%
%   Outputs, left in the workspace:
%     tx_pairs / tx_pair_labels - all simulated patch pairs and their
%                     same/different labels, shuffled together
%     tx_samples / tx_labels    - patch a of every trial and its texture
%                     number, unshuffled
%     *_dv_same / *_dv_diff     - per-cue decision variables, in log units
%     tx_discrim_bd             - struct of fitted boundaries (grad_m_bd,
%                     grad_o_bd, grad_p_bd, all_bd). Frozen name: it is the
%                     variable inside data/model/texture discrimination
%                     boundaries.mat.
%
%   Data this script reads, and whether the path resolves (checked 2026-09-21):
%     fullfile(cfg.paths.data_root, 'nat_im_eff_coding.mat') - resolves; holds
%       the gradient and gray-level bin edges (cells 1 and 3).
%     fullfile(cfg.paths.textures, 'brodatz')                - resolves; the
%       60 Brodatz sheets (cells 1 and 3).
%     fullfile(cfg.paths.model, 'texture discrimination boundaries.mat')
%                                                            - resolves (cell 3).
%     'exp_files/norm/...'                                   - does NOT
%       resolve: no norm subdirectory exists under exp_files. Left as written,
%       since that is Stage 4 item B3.1, not a data-store routing problem.
%
%   See also CONFIG, LIB.EDGE_PROPS_STIM, LIB.HIST_DV,
%   GENERAL.COMPUTE_EXP_ERROR_MAT.

%% simulate texture discrimination from patches
% rng(0);

% every data path below comes from config(), never from the current folder
cfg = config();

% constants and parameters
n_tex = 60;  % # of textures
image_size = 640;  % texture image size
patch_size = 64;  % patch size
ppd = 60;  % PPD for OTF filtering images
n_samp = 10;  % # of samples per texture pair (usually 10)
noise_const = 10;  % weak power suppression parameter
eps_offset = 1e-10;  % to prevent log(0)
pad_val = 128;  % pad patches with this mean greylevel value when taking gradients

% load the efficient-coding histogram bins of gradient magnitude computed from
% natural images
load(fullfile(cfg.paths.data_root, 'nat_im_eff_coding.mat'))

% load('vislab-common/data/eff_coding_bins.mat') % load the efficient-coding histogram bins of gradient magnitude computed from natural images
% n_bins=64;                 % # of grayscale histogram bins
% grey_hist_bins=linspace(0,256,n_bins+1); % gray-level bin edges

% load image files
tex_dir = fullfile(cfg.paths.textures, 'brodatz');
file_type = 'gif';
files = dir(fullfile(tex_dir, ['*.' file_type]));

% sort them right
file_numbers = cellfun(@(x) str2double(regexp(x, '\d+', 'match', 'once')), ...
    {files.name});
[~, sort_idx] = sort(file_numbers);
files = files(sort_idx);

imgs = nan(640, 640, n_tex);
for i_file = 1:n_tex
    file_name = fullfile(tex_dir, files(i_file).name);
    img = double(imread(file_name));
    img = mean(img, 3);
    img = vislab.lib.otf_filter(img, ppd);
    imgs(:, :, i_file) = img;
end

n_all = nchoosek(n_tex, 2)*n_samp;  % # of trials in same/diff category each

% initiate storage
tx_samples = nan(patch_size, patch_size, 1, 2*n_all);
tx_labels = nan(2*n_all, 1);

tx_pairs = nan(patch_size, patch_size, 2, 2*n_all);  % all trial patch pairs
tx_pair_labels = false(2*n_all, 1);

% discrimination decision variables
pow_dv_same = nan(n_all, 1);  pow_dv_diff = nan(n_all, 1);  % power spectrum
hist_dv_same = nan(n_all, 1);  hist_dv_diff = nan(n_all, 1);  % greyscale histogram

grad_m_same = nan(n_all, 5);  grad_m_diff = nan(n_all, 5);  % gradient magnitude
grad_o_same = nan(n_all, 5);  grad_o_diff = nan(n_all, 5);  % gradient orientation
grad_p_same = nan(n_all, 5);  grad_p_diff = nan(n_all, 5);  % gradient product

pix_num_same = nan(n_all, 1);  pix_num_diff = nan(n_all, 1);  % # edge contour pixels
con_num_same = nan(n_all, 1);  con_num_diff = nan(n_all, 1);  % edge contour numbers
con_len_same = nan(n_all, 1);  con_len_diff = nan(n_all, 1);  % edge contour lengths
con_curv_same = nan(n_all, 1);  con_curv_diff = nan(n_all, 1);  % edge contour curvatures

i_trial = 1;  i_same = 1;  i_diff = 1;
for i_tex = 1:n_tex
    % read texture image
    img_a = imgs(:, :, i_tex);
    % img_a=mean(img_a,3);

    % same trials
    for i_samp = 1:n_all/n_tex
        [i_tex i_tex i_samp]

        % sample patch a from image
        x = randi(image_size - patch_size);  y = randi(image_size - patch_size);
        patch_a = img_a(x:x+patch_size-1, y:y+patch_size-1);
        patch_a = patch_a/mean(patch_a(:))*128;  % scale patch to a mean of 128
        tx_pairs(:, :, 1, i_trial) = patch_a;

        % store only texture a and label (for testing)
        tx_samples(:, :, 1, i_trial) = patch_a;
        tx_labels(i_trial) = i_tex;

        % sample patch b from image
        x = randi(image_size - patch_size);  y = randi(image_size - patch_size);
        patch_b = img_a(x:x+patch_size-1, y:y+patch_size-1);
        patch_b = patch_b/mean(patch_b(:))*128;  % scale patch to a mean of 128
        tx_pairs(:, :, 2, i_trial) = patch_b;

        tx_pair_labels(i_trial) = true;

        % compute decision variables
        pow_dv_same(i_same) = log(vislab.nat_stat_bayes.dv_power(patch_a, ...
            patch_b, noise_const, size(patch_a, 1)));
        hist_dv_same(i_same) = log(lib.hist_dv(patch_a, patch_b, ...
            grey_hist_bins) + eps_offset);

        patches = cat(3, patch_a, patch_b);
        [grad_m_same(i_same, 1), grad_m_same(i_same, 2), grad_m_same(i_same, 3), ...
            grad_m_same(i_same, 4), grad_m_same(i_same, 5), ...
            grad_o_same(i_same, 1), grad_o_same(i_same, 2), grad_o_same(i_same, 3), ...
            grad_o_same(i_same, 4), grad_o_same(i_same, 5), ...
            grad_p_same(i_same, 1), grad_p_same(i_same, 2), grad_p_same(i_same, 3), ...
            grad_p_same(i_same, 4), grad_p_same(i_same, 5), ...
            pix_num_same(i_same), ...
            con_num_same(i_same), ...
            con_len_same(i_same), ~, ~, ~, ...
            ~, ~, ...
            con_curv_same(i_same), ~, ~, ~, ~, ~, ~] = ...
            lib.edge_props_stim(patches, 'stim_type', 'tex', 'pad_val', pad_val, ...
            'grad_mag_bins', grad_m_bins, 'grad_or_bins', grad_o_bins, ...
            'grad_prod_bins', grad_p_bins);

        i_trial = i_trial + 1;
        i_same = i_same + 1;
    end

    % different trials
    for j_tex = i_tex+1:n_tex
        % img_b=mean(img_b,3);
        img_b = imgs(:, :, j_tex);

        for i_samp = 1:n_samp
            [i_tex j_tex i_samp]
            while true

                % sample patch a from image
                x = randi(image_size - patch_size);  y = randi(image_size - patch_size);
                patch_a = img_a(x:x+patch_size-1, y:y+patch_size-1);
                tx_pairs(:, :, 1, i_trial) = patch_a;

                % store only texture a and label (for testing)
                tx_samples(:, :, 1, i_trial) = patch_a;
                tx_labels(i_trial) = i_tex;

                % sample patch b from image
                x = randi(image_size - patch_size);  y = randi(image_size - patch_size);
                patch_b = img_b(x:x+patch_size-1, y:y+patch_size-1);
                tx_pairs(:, :, 2, i_trial) = patch_b;

                tx_pair_labels(i_trial) = false;

                % compute decision variables
                pow_diff_this = log(vislab.nat_stat_bayes.dv_power(patch_a, ...
                    patch_b, noise_const, size(patch_a, 1)));
                hist_diff_this = log(lib.hist_dv(patch_a, patch_b, grey_hist_bins));

                patches = cat(3, patch_a, patch_b);
                [grad_m_diff(i_diff, 1), grad_m_diff(i_diff, 2), grad_m_diff(i_diff, 3), ...
                    grad_m_diff(i_diff, 4), grad_m_diff(i_diff, 5), ...
                    grad_o_diff(i_diff, 1), grad_o_diff(i_diff, 2), grad_o_diff(i_diff, 3), ...
                    grad_o_diff(i_diff, 4), grad_o_diff(i_diff, 5), ...
                    grad_p_diff(i_diff, 1), grad_p_diff(i_diff, 2), grad_p_diff(i_diff, 3), ...
                    grad_p_diff(i_diff, 4), grad_p_diff(i_diff, 5), ...
                    pix_num_diff(i_diff), ...
                    con_num_diff(i_diff), ...
                    con_len_diff(i_diff), ~, ~, ~, ...
                    ~, ~, ...
                    con_curv_diff(i_diff), ~, ~, ~, ~, ~, ~] = ...
                    lib.edge_props_stim(patches, 'stim_type', 'tex', 'pad_val', pad_val, ...
                    'grad_mag_bins', grad_m_bins, 'grad_or_bins', grad_o_bins, ...
                    'grad_prod_bins', grad_p_bins);

                if (pow_diff_this > -10) && (hist_diff_this > -10)
                    pow_dv_diff(i_diff) = pow_diff_this;
                    hist_dv_diff(i_diff) = hist_diff_this;
                    %                     edge_dv_diff(i_diff,:)=[edge_length_dv_exp];

                    i_trial = i_trial + 1;
                    i_diff = i_diff + 1;
                    break;
                end
            end
        end
    end
end

% shuffle labelled texture pairs
shuffle_order = randperm(2*n_all);
tx_pair_labels = tx_pair_labels(shuffle_order);
tx_pairs = tx_pairs(:, :, :, shuffle_order);

% convert labels to categorical arrays
tx_labels = categorical(tx_labels);
tx_pair_labels = categorical(tx_pair_labels);

% discriminate using power spectrum and grey level
results = classify_normals([pow_dv_same hist_dv_same], ...
    [pow_dv_diff hist_dv_diff], 'input_type', 'samp', 'samp_opt', false, ...
    'd_con', true);
axis normal
xlabel 'power spectrum'
ylabel 'greyscale histogram'

% discriminate using gradient magnitude, and merge to single dv
results = classify_normals(grad_m_same, grad_m_diff, 'input_type', 'samp', ...
    'samp_opt', false, 'd_con', true);
xlim([-20 15])
ylim([0 .16])
xlabel 'gradient magnitude (scales combined)'
set(gca, 'ytick', [], 'fontsize', 13)
grad_m_bd = results.norm_bd;
grad_m_dv_same = results.samp_dv{1};
grad_m_dv_diff = results.samp_dv{2};

% discriminate using gradient orientation, and merge to single dv
results = classify_normals(grad_o_same, grad_o_diff, 'input_type', 'samp', ...
    'samp_opt', false, 'd_con', true);
xlim([-10 10])
xlabel 'gradient orientation (scales combined)'
set(gca, 'ytick', [], 'fontsize', 13)
grad_o_bd = results.norm_bd;
grad_o_dv_same = results.samp_dv{1};
grad_o_dv_diff = results.samp_dv{2};

% discriminate using gradient product, and merge to single dv
results = classify_normals(grad_p_same, grad_p_diff, 'input_type', 'samp', ...
    'samp_opt', false, 'd_con', true);
xlim([-7 10])
xlabel 'gradient product (scales combined)'
set(gca, 'ytick', [], 'fontsize', 13)
grad_p_bd = results.norm_bd;
grad_p_dv_same = results.samp_dv{1};
grad_p_dv_diff = results.samp_dv{2};

% discriminate using the 3 gradient histograms
results_grad = classify_normals( ...
    [grad_m_dv_same grad_o_dv_same grad_p_dv_same], ...
    [grad_m_dv_diff grad_o_dv_diff grad_p_dv_diff], ...
    'input_type', 'samp', 'samp_opt', false, 'd_con', true);
axis([-10 10 -10 10 -10 10])
xlabel 'gradient magnitude'
ylabel 'gradient orientation'
zlabel 'gradient product'
set(gca, 'fontsize', 13)
grad_dv_same = results_grad.samp_dv{1};
grad_dv_diff = results_grad.samp_dv{2};

% discriminate using grey level and gradients
results_grad = classify_normals([hist_dv_same grad_dv_same], ...
    [hist_dv_diff grad_dv_diff], 'input_type', 'samp', 'samp_opt', false);
axis([0 10 -10 25])
xlabel 'greyscale histogram'
ylabel 'gradient histograms'

% discriminate using edge contour properties
results = classify_normals( ...
    [pix_num_same con_num_same con_len_same con_curv_same], ...
    [pix_num_diff con_num_diff con_len_diff con_curv_diff], ...
    'input_type', 'samp', 'samp_opt', false, 'd_con', true);
xlim([-7 10])
xlabel 'all edge contour properties combined'
set(gca, 'ytick', [], 'fontsize', 13)

% discriminate using all cues
results_all = classify_normals( ...
    [pow_dv_same hist_dv_same grad_m_dv_same grad_o_dv_same grad_p_dv_same ...
    pix_num_same con_num_same con_len_same con_curv_same], ...
    [pow_dv_diff hist_dv_diff grad_m_dv_diff grad_o_dv_diff grad_p_dv_diff ...
    pix_num_diff con_num_diff con_len_diff con_curv_diff], ...
    'input_type', 'samp', 'samp_opt', false, 'd_con', true);
xlim([-50 50])
xlabel 'final decision variable'
set(gca, 'ytick', [], 'fontsize', 13)
all_bd = results_all.norm_bd;

% save decision boundaries
tx_discrim_bd = struct;
tx_discrim_bd.grad_m_bd = grad_m_bd;
tx_discrim_bd.grad_o_bd = grad_o_bd;
tx_discrim_bd.grad_p_bd = grad_p_bd;
tx_discrim_bd.all_bd = all_bd;

% save("data/model/texture discrimination boundaries.mat","tx_discrim_bd")

%% add actual experimental patches to the plot
load('exp_files/norm/exp_settings.mat')
load('exp_files/norm/subject_out/neel.mat')

i_level = 1;  % pick eccentricity level

% concatenate all sessions
idx = reshape(permute(subject_file.idx, [2 1 3]), exp_settings.nLevels, ...
    exp_settings.nTrials*exp_settings.nSessions)';
diffpair = reshape(permute(subject_file.diffpair, [2 1 3]), exp_settings.nLevels, ...
    exp_settings.nTrials*exp_settings.nSessions)';
correct = reshape(permute(subject_file.correct, [2 1 3]), exp_settings.nLevels, ...
    exp_settings.nTrials*exp_settings.nSessions)';

pow_dv_exp = nan(size(idx, 1), 1);
hist_dv_exp = nan(size(idx, 1), 1);

for i_exp_trial = 1:size(idx, 1)
    patch_a = exp_settings.stimuli(:, :, 1, idx(i_exp_trial, i_level))*255;
    patch_b = exp_settings.stimuli(:, :, 2, idx(i_exp_trial, i_level))*255;
    pow_dv_exp(i_exp_trial) = log(vislab.nat_stat_bayes.dv_power(patch_a, ...
        patch_b, noise_const, size(patch_a, 1)));
    hist_dv_exp(i_exp_trial) = log(lib.hist_dv(patch_a, patch_b, grey_hist_bins));
end

hold on
default_colors = colororder;

plot(pow_dv_exp(~diffpair(:, i_level) & correct(:, i_level)), ...
    hist_dv_exp(~diffpair(:, i_level) & correct(:, i_level)), ...
    '.', 'color', default_colors(1, :), 'markersize', 8)
plot(pow_dv_exp(~diffpair(:, i_level) & ~correct(:, i_level)), ...
    hist_dv_exp(~diffpair(:, i_level) & ~correct(:, i_level)), ...
    'o', 'markerfacecolor', default_colors(1, :), 'markeredgecolor', 'k', ...
    'markersize', 4)

plot(pow_dv_exp(diffpair(:, i_level) & correct(:, i_level)), ...
    hist_dv_exp(diffpair(:, i_level) & correct(:, i_level)), ...
    '.', 'color', default_colors(2, :), 'markersize', 8)
plot(pow_dv_exp(diffpair(:, i_level) & ~correct(:, i_level)), ...
    hist_dv_exp(diffpair(:, i_level) & ~correct(:, i_level)), ...
    'o', 'markerfacecolor', default_colors(2, :), 'markeredgecolor', 'k', ...
    'markersize', 4)

%% discriminate a single pair of texture patches

% this cell is self-contained, so it fetches the paths itself
cfg = config();

% load the efficient-coding histogram bins of gradient magnitude computed
% from natural images. This used to read 'eff_coding_bins.mat', which exists
% nowhere; nat_im_eff_coding.mat is the same file cell 1 loads and holds the
% grad_m_bins / grad_o_bins / grad_p_bins this cell goes on to use (B2.14).
load(fullfile(cfg.paths.data_root, 'nat_im_eff_coding.mat'))

% load texture-discrimination boundaries:
load(fullfile(cfg.paths.model, 'texture discrimination boundaries.mat'))

% parameters
n_tex = 60;  % # of textures
image_size = 640;  % texture image size
patch_size = 64;  % patch size
ppd = 60;  % PPD for OTF filtering images
n_samp = 10;  % # of samples per texture pair
noise_const = 10;  % weak power suppression parameter
n_bins = 64;  % # of grayscale histogram bins
grey_hist_bins = linspace(0, 256, n_bins+1);  % gray-level bin edges

% pick textures
tex_a = randi(n_tex);
if unifrnd(0, 1) < 0.5
    tex_b = tex_a;
    same = true;
else
    other_tex = [1:tex_a-1 tex_a+1:n_tex];
    tex_b = other_tex(randi(n_tex-1));
    same = false;
end

% sample patches
img_a = double(imread(fullfile(cfg.paths.textures, 'brodatz', ...
    ['B', num2str(tex_a), '.gif'])));
img_a = vislab.lib.otf_filter(img_a, ppd);
% img_a=imresize(img_a, [1024 1024]);
x = randi(image_size - patch_size);  y = randi(image_size - patch_size);
patch_a = img_a(x:x+patch_size-1, y:y+patch_size-1);

img_b = double(imread(fullfile(cfg.paths.textures, 'brodatz', ...
    ['B', num2str(tex_b), '.gif'])));
img_b = vislab.lib.otf_filter(img_b, ppd);
% img_b=imresize(img_b, [1024 1024]);
x = randi(image_size - patch_size);  y = randi(image_size - patch_size);
patch_b = img_b(x:x+patch_size-1, y:y+patch_size-1);

% figure;
subplot(1, 2, 1);
imshow(patch_a, [])
title(tex_a)
subplot(1, 2, 2);
imshow(patch_b, [])
title(tex_b)

% compute decision variables
pow_dv = log(vislab.nat_stat_bayes.dv_power(patch_a, patch_b, noise_const, ...
    size(patch_a, 1)));
hist_dv = log(lib.hist_dv(patch_a, patch_b, grey_hist_bins));

patches = cat(3, patch_a, patch_b);

[grad_m_1, grad_m_2, grad_m_4, grad_m_8, ~, ...
    grad_o_1, grad_o_2, grad_o_4, grad_o_8, ~, ...
    grad_p_1, grad_p_2, grad_p_4, grad_p_8, ~, ...
    pix_num, ...
    con_num, ...
    con_len, ~, ~, ~, ...
    ~, ~, ...
    con_curv, ~, ~, ~, ~, ~, ~] = ...
    lib.edge_props_stim(patches, 'stim_type', 'tex', ...
    'grad_mag_bins', grad_m_bins, 'grad_or_bins', grad_o_bins, ...
    'grad_prod_bins', grad_p_bins);

% first compute combined gradient histogram dv's

% function that computes the bayes dv using the trained boundary
grad_m_dv_fun = quad2fun(tx_discrim_bd.grad_m_bd, 0);
grad_m_dv = grad_m_dv_fun([grad_m_1 grad_m_2 grad_m_4 grad_m_8]');

grad_o_dv_fun = quad2fun(tx_discrim_bd.grad_o_bd, 0);
grad_o_dv = grad_o_dv_fun([grad_o_1 grad_o_2 grad_o_4 grad_o_8]');

grad_p_dv_fun = quad2fun(tx_discrim_bd.grad_p_bd, 0);
grad_p_dv = grad_p_dv_fun([grad_p_1 grad_p_2 grad_p_4 grad_p_8]');

all_dv_fun = quad2fun(tx_discrim_bd.all_bd, 0);
all_dv = all_dv_fun([pow_dv hist_dv grad_m_dv grad_o_dv grad_p_dv pix_num ...
    con_num con_len con_curv]');

if all_dv > 0
    sg_title = sgtitle('same');
else
    sg_title = sgtitle('different');
end

if same == (all_dv > 0)
    sg_title.Color = [0 .8 0];
else
    sg_title.Color = 'red';
end
