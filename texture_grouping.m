% TEXTURE_GROUPING  Group the patches of a synthetic texture scene into regions.
%   run('texture_grouping.m')
%
%   Builds a 1024x1024 scene from a 4x4 grid of 256x256 texture regions, each
%   cut at a random position out of a different Brodatz sheet, then splits the
%   scene into a 16x16 grid of 64x64 patches and computes two same/different
%   decision variables for every ordered pair of patches: a windowed
%   power-spectrum difference (VISLAB.NAT_STAT_BAYES.DV_POWER on the windowed
%   patches) and a gray-level histogram difference (LIB.HIST_DV).
%   A hardcoded 2-cue quadratic combines the two logs into one decision
%   variable per pair, which is thresholded into links; links are then pruned
%   and merged into groups by how many links each linked pair shares. Displays
%   the scene and the resulting grouping map.
%
%   This is a script, not a function: it clears the workspace, runs top to
%   bottom, and leaves its results in the base workspace. Converting it into a
%   proper function is the treatment Stage 3 item S2.5 gives the repo's other
%   scripts (docs/repo-cleanup.md).
%
%   Expects, in the shared data store
%     B1.gif ... B16.gif - the first 16 Brodatz sheets, 640x640 gray levels,
%                          read from <cfg.paths.textures>/brodatz, i.e.
%                          ../vislab-common/data/textures/brodatz. The path is
%                          built from CONFIG, so the script runs from any
%                          working directory.
%
%   Workspace outputs
%     scene      - scene_size x scene_size scene image, in gray levels
%                  (0-255), that the patches were cut from.
%     responses  - n_patches x n_patches x n_responses array of the two raw
%                  decision variables for every ordered patch pair.
%     dv         - n_patches x n_patches combined decision variable, 0 on the
%                  diagonal. The thresholding step below links pairs scoring
%                  above link_criterion and links every patch to itself
%                  regardless, so a larger value means more evidence the two
%                  patches share a texture, not that they differ.
%     links      - n_patches x n_patches 0/1 link matrix, after weak links are
%                  pruned.
%     groups     - n_patches x (2+n_patches) x 2 table, one row per patch:
%                  group number, link count, then one column per link holding
%                  the linked patch's index (page 1) and the pair's decision
%                  variable (page 2).
%     group_img  - scene_size x scene_size map of each patch's group number.
%
%   Note: the power call resolves once SETUP has put vislab-common on the path.
%
%   Note: seeds with the literal rng(2) where CONFIG exposes cfg.seed = 0, and
%   hardcodes a 2-cue quadratic boundary of the same shape as the repo's
%   shipped fabric_bd.mat (q2 2x2, q1 2x1, q0 scalar) but with different
%   values, from an unrecorded fit. Stage 3 items S3.7 and S3.8.
%
%   See also VISLAB.NAT_STAT_BAYES.DV_POWER, LIB.HIST_DV, MK_WIN, THRESH,
%   NLSAME, CONFIG, SETUP.

clear all;
close all;
rng(2);

% data locations come from config(), never from the current folder
cfg = config();

scene_size = 1024;      % scene side length, pixels
image_size = 640;       % Brodatz sheet side length, pixels
region_size = 256;      % texture region side length, pixels
patch_size = 64;        % patch side length, pixels
region_grid_size = scene_size/region_size;   % regions per scene side
grid_size = scene_size/patch_size;           % patches per scene side
n_patches = grid_size^2;                     % patches in the scene
n_responses = 2;
link_criterion = 15;    % decision variable a pair must exceed to be linked
group_criterion = 0.5;  % shared-link fraction two linked patches must exceed
image_num = 0;
responses = zeros(n_patches, n_patches, n_responses);   % response storage array

% load scene
scene = zeros(scene_size, scene_size);
n_images = 60;
first_image_num = 1;
% ii and jj are deliberately neutral names: each serves several roles through
% this script -- region row and column here, patch index in the response and
% grouping loops, histogram bin index below (rule C-6 in docs/repo-cleanup.md).
for ii = 1:region_grid_size
    for jj = 1:region_grid_size

        % select a texture image -- sequentially, B1..B16; the commented line
        % below is the earlier version, which picked one of the 60 at random
        %   image_num = randi(n_images);
        image_num = image_num + 1;
        num_str = num2str(image_num-1+first_image_num);
        file_name = fullfile(cfg.paths.textures, 'brodatz', ...
            append('B', num_str, '.gif'));
        tex_img = imread(file_name);

        % randomly select a region within that texture image
        row_offset = randi(image_size-region_size);
        col_offset = randi(image_size-region_size);
        region_img = tex_img(row_offset:row_offset+region_size-1, ...
            col_offset:col_offset+region_size-1);
        region_row_lo = (ii-1)*region_size+1;  region_row_hi = region_row_lo+region_size-1;
        region_col_lo = (jj-1)*region_size+1;  region_col_hi = region_col_lo+region_size-1;

        % insert the texture region into the scene
        scene(region_row_lo:region_row_hi, region_col_lo:region_col_hi) = region_img;
    end
end

figure;
colormap(gray(256));
image(scene);
axis image;

% make patch-analysis window
radius = patch_size/2;   % flat radius, pixels; at patch_size/2 the whole window is flat
shape = 2;               % 1 radially symmetric, 2 separable
win = mk_win(patch_size, radius, shape);
noise_const = 10;        % weak power suppression parameter

% make histogram edges
bin_width = 4;           % gray levels per histogram bin, a power of 2
n_bins = 256/bin_width;
edges = zeros(n_bins, 1);
for ii = 1:n_bins+1
    edges(ii) = (ii-1)*bin_width;
end

% compute responses
patch_coords = zeros(n_patches, 2);
for ii = 1:n_patches
    row1 = floor((ii-1)/grid_size) + 1;
    col1 = ii - (row1-1)*grid_size;

    % get patch ii
    patch_row_lo = (row1-1)*patch_size+1;  patch_row_hi = patch_row_lo+patch_size-1;
    patch_col_lo = (col1-1)*patch_size+1;  patch_col_hi = patch_col_lo+patch_size-1;
    patch_coords(ii, 1) = patch_row_lo;  patch_coords(ii, 2) = patch_col_lo;
    patch1 = scene(patch_row_lo:patch_row_hi, patch_col_lo:patch_col_hi);
    for jj = 1:n_patches
        row2 = floor((jj-1)/grid_size) + 1;
        col2 = jj - (row2-1)*grid_size;

        % get patch jj
        patch_row_lo = (row2-1)*patch_size+1;  patch_row_hi = patch_row_lo+patch_size-1;
        patch_col_lo = (col2-1)*patch_size+1;  patch_col_hi = patch_col_lo+patch_size-1;
        patch2 = scene(patch_row_lo:patch_row_hi, patch_col_lo:patch_col_hi);
        responses(ii, jj, 1) = vislab.nat_stat_bayes.dv_power(patch1.*win, ...
            patch2.*win, noise_const, patch_size);
        responses(ii, jj, 2) = lib.hist_dv(patch1, patch2, edges);
    end
end

% quadratic parameters for decision variable
q2 = [5.273048046354344, 0.784966045877294;...
      0.784966045877294, 1.323305813271773];
q1 = [0.154037415875747; -24.896804657431097];
q0 = 26.906021503125597;

% compute decision variable
dv = zeros(n_patches, n_patches);
for ii = 1:n_patches
    for jj = 1:n_patches
        if ii ~= jj
            xx = [log(responses(ii, jj, 1)); log(responses(ii, jj, 2))];
            dv(ii, jj) = xx'*q2*xx + xx'*q1 + q0;
        end
    end
end

% find links
links = thresh(dv, n_patches, link_criterion);

% load links and strengths into groups array
groups = zeros(n_patches, 2+n_patches, 2);   % group#, #links, link1, link2, ...
for ii = 1:n_patches
    for jj = 1:n_patches
        if links(ii, jj) == 1
            n_links = groups(ii, 2, 1)+1;  groups(ii, 2, 1) = n_links;
            groups(ii, 2+n_links, 1) = jj;
            groups(ii, 2+n_links, 2) = dv(ii, jj);
        end
    end
end
group_set = groups(1:n_patches, 1:n_patches, 1);

% remove weak links
for ii = 1:n_patches
    n_links_a = groups(ii, 2, 1);                     % number of links for patch ii
    links_a = groups(ii, 3:3+n_links_a-1, 1);         % list of links for patch ii
    for jj = 1:n_links_a
        n_links_b = groups(links_a(jj), 2, 1);        % number of links for link jj|ii
        links_b = groups(links_a(jj), 3:3+n_links_b-1, 1);   % list of links for link jj|ii
        n_common = nlsame(links_a, n_links_a, links_b, n_links_b);
        link_ratio = 2*n_common/(n_links_a+n_links_b);
        if n_links_a > 1 && link_ratio < group_criterion
            if ii ~= links_a(jj)
                links(ii, links_a(jj)) = 0;
            end
        end
    end
end

% find groups
group_num = 0;
for ii = 1:n_patches
    n_links_a = groups(ii, 2, 1);                     % number of links for patch ii
    links_a = groups(ii, 3:3+n_links_a-1, 1);         % list of links for patch ii
    for jj = 1:n_links_a
        n_links_b = groups(links_a(jj), 2, 1);        % number of links for link jj|ii
        links_b = groups(links_a(jj), 3:3+n_links_b-1, 1);   % list of links for link jj|ii
        n_common = nlsame(links_a, n_links_a, links_b, n_links_b);
        link_ratio = 2*n_common/(n_links_a+n_links_b);
        if n_links_a > 1 && link_ratio > group_criterion
            if groups(ii, 1, 1) == 0
                group_num = group_num+1;
                groups(ii, 1, 1) = group_num;
                group_set(ii, 1) = group_num;
            end
            if groups(links_a(jj), 1, 1) == 0
                groups(links_a(jj), 1, 1) = groups(ii, 1, 1);
                group_set(links_a(jj), 1) = groups(ii, 1, 1);
            end
        end
    end
end

% make grouping map
group_img = zeros(scene_size, scene_size);
for ii = 1:n_patches
    xx = patch_coords(ii, 1);  yy = patch_coords(ii, 2);
    patch_block = ones(patch_size, patch_size)*groups(ii, 1);
    group_img(xx:xx+patch_size-1, yy:yy+patch_size-1) = patch_block;
end
figure;
image(group_img, 'CDataMapping', 'scaled');
axis image;

% figure; colormap(gray(256)); image(rthres*255); axis image;
