% texture_same_diff_patches_cnn.m
% Build same/different texture patch-pair TEST sets for the twin CNN, from several
% texture databases in vislab-common/data/textures. Produces TWO sets:
%
%   same,      diff       -- ALL databases combined (balanced), "different" pairs may
%                            cross databases (two textures from anywhere in the pool)
%   same_brod, diff_brod  -- Brodatz only (both patches from Brodatz textures)
%
% Each is [psz psz 2 N] uint8; dim 3 holds the two patches of a pair (1 = reference,
% 2 = partner), matching the natural-image near/far layout so getTwinBatchPairs can
% slice it directly. Saved to data/stimuli/textures/patch_pairs.mat.
%
% Ingestion FULLY MIRRORS the Bayesian pipeline (texture-learning load_texture_images.m):
% per database, resize pertex 1024->640, grayscale-replicate, gamma-linearize, eye-optics
% OTF, RGB->LMS->ABR achromatic channel -- via general.texture_image_to_A. So the texture
% test patches are optically blurred like the natural-image training patches.
%
% Balancing: each database contributes the same number of distinct textures (capped) and
% the same number of pairs, so the large low-variety pertex set cannot swamp the metric.

psz = 64;
texdir = '../vislab-common/data/textures/';
ppd = 60; pd = 4; w = 550;   % optics for the OTF (ppd 60 = texture-sheet display scale)
down_level = 1;              % resolution scale-down; must match the training patches

n_tex_per_db  = 60;          % cap on distinct textures used per DB (subsample larger DBs)
n_same = 10000; n_diff = 10000;          % all-textures pairs of each type
n_same_brod = 5000; n_diff_brod = 5000;  % Brodatz-only pairs of each type

% per-database ingestion flags (see general.texture_image_to_A / load_texture_images.m)
dbs = struct( ...
    'name',   {'brodatz','fabric','mcgill','vistex','pertex'}, ...
    'ext',    {'gif',    'png',   'png',   'png',   'png'   }, ...
    'gray',   {true,     false,   false,   false,   true    }, ...
    'gamma',  {false,    true,    true,    true,    false   }, ...
    'resize', {false,    false,   false,   false,   true    });

% load a capped, random subset of each database as achromatic uint8 images
allTex   = {};                 % every loaded texture (balanced pool)
brodTex  = {};                 % Brodatz subset (for the Brodatz-only set)
for d = 1:numel(dbs)
    files = dir([texdir dbs(d).name '/*.' dbs(d).ext]);
    n_use = min(n_tex_per_db, numel(files));
    sel = randperm(numel(files), n_use);
    fprintf('%s: using %d of %d textures\n', dbs(d).name, n_use, numel(files));
    for i = 1:n_use
        A = general.texture_image_to_A(fullfile(files(sel(i)).folder, files(sel(i)).name), ...
            dbs(d).gray, dbs(d).gamma, dbs(d).resize, ppd, pd, w, down_level);
        allTex{end+1} = A; %#ok<SAGROW>
        if strcmp(dbs(d).name, 'brodatz'), brodTex{end+1} = A; end %#ok<SAGROW>
    end
end

% all-textures set: same = one random texture twice; diff = two different textures from
% anywhere in the pool (cross-database allowed)
[same, diff] = make_pairs(allTex, n_same, n_diff, psz);

% Brodatz-only set (both patches Brodatz)
[same_brod, diff_brod] = make_pairs(brodTex, n_same_brod, n_diff_brod, psz);

% save both sets
outdir = 'data/stimuli/textures/';
if ~exist(outdir, 'dir'); mkdir(outdir); end
if down_level > 1
    outfile = [outdir 'patch_pairs_dsmpl_' num2str(down_level) '.mat'];
else
    outfile = [outdir 'patch_pairs.mat'];
end
save(outfile, 'same', 'diff', 'same_brod', 'diff_brod', '-v7.3')

%% show a few example pairs from the all-textures set (reference | partner)
n_show = 5;
i_same = randi(size(same,4), 1, n_show);
i_diff = randi(size(diff,4), 1, n_show);
figure;
tiledlayout(2, n_show, 'TileSpacing', 'compact', 'Padding', 'compact');
for j = 1:n_show
    nexttile; imshow([same(:,:,1,i_same(j)) same(:,:,2,i_same(j))], []);
    title(sprintf('same #%d', i_same(j)));
end
for j = 1:n_show
    nexttile; imshow([diff(:,:,1,i_diff(j)) diff(:,:,2,i_diff(j))], []);
    title(sprintf('diff #%d', i_diff(j)));
end

%% ------- local functions -------
function [same, diff] = make_pairs(tex, n_same, n_diff, psz)
    n = numel(tex);
    same = zeros(psz, psz, 2, n_same, 'uint8');
    for i = 1:n_same
        k = randi(n);                          % one random texture, two patches
        same(:,:,1,i) = rand_patch(tex{k}, psz);
        same(:,:,2,i) = rand_patch(tex{k}, psz);
    end
    diff = zeros(psz, psz, 2, n_diff, 'uint8');
    for i = 1:n_diff
        kk = randperm(n, 2);                   % two different textures, one patch each
        diff(:,:,1,i) = rand_patch(tex{kk(1)}, psz);
        diff(:,:,2,i) = rand_patch(tex{kk(2)}, psz);
    end
end

function p = rand_patch(t, psz)
    sz = size(t);
    x = randi(sz(1) - psz + 1);
    y = randi(sz(2) - psz + 1);
    p = t(x:x+psz-1, y:y+psz-1);
end
