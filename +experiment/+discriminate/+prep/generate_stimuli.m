function [stimuli, seeds, tex, coords] = generate_stimuli(exp_type)
%GENERATE_STIMULI  Sample texture-patch stimuli for the discrimination experiment.
%   [stimuli, seeds, tex, coords] = experiment.discriminate.prep.generate_stimuli(exp_type)
%
%   Draws same-texture and different-texture patch pairs, 10 trials for
%   each of 60 textures, calling LIB.TEXTURE_PATCH once per patch. Called
%   only from SETUP_EXPERIMENT, once per experiment type.
%
%   Inputs
%     exp_type   Experiment variant string: 'norm' draws each patch of a
%                pair independently; 'joined' draws one 128x64-pixel patch
%                and splits it top/bottom into the pair.
%
%   Output
%     stimuli   64x64x2xN patch image array (pixels), N = 2*n_tex*n_trials.
%     seeds     Nx2 uint32, the RNG seed LIB.TEXTURE_PATCH used for each patch.
%     tex       Nx1 cell; scalar texture id for a same-texture pair, or
%               [id1 id2] for a different-texture pair.
%     coords    Nx2 cell; the sampling coordinates LIB.TEXTURE_PATCH returned
%               for each patch.
%
%   See also EXPERIMENT.DISCRIMINATE.PREP.SETUP_EXPERIMENT, LIB.TEXTURE_PATCH.

n_tex = 60; % number of textures
n_trials = 10; % number of trials for each texture pair

stimuli = nan(64, 64, 2, 2*n_tex*n_trials);
seeds = zeros(2*n_tex*n_trials, 2, 'uint32');
tex = cell(2*n_tex*n_trials, 1);
coords = cell(2*n_tex*n_trials, 2);

% same-texture pairs
for i_tex = 1:n_tex
    for i_trial = 1:n_trials
        idx = (i_tex-1)*n_trials+i_trial;
        tex{idx} = i_tex;

        if strcmpi(exp_type, 'norm')
            % patch 1
            [patch1, seed, ~, coord] = lib.texture_patch('tex_num', i_tex);
            stimuli(:, :, 1, idx) = patch1;
            seeds(idx, 1) = seed;
            coords{idx, 1} = coord;

            % patch 2
            [patch2, seed, ~, coord] = lib.texture_patch('tex_num', i_tex);
            stimuli(:, :, 2, idx) = patch2;
            seeds(idx, 2) = seed;
            coords{idx, 2} = coord;

        elseif strcmpi(exp_type, 'joined')
            % total patch
            [patch_joined, seed, ~, coord] = lib.texture_patch('tex_num', i_tex, 'patch_size', [128 64]);

            patch1 = patch_joined(1:64, :);
            stimuli(:, :, 1, idx) = patch1;
            seeds(idx, 1) = seed;
            coords{idx, 1} = coord;

            patch2 = patch_joined(65:end, :);
            stimuli(:, :, 2, idx) = patch2;
            seeds(idx, 2) = seed;
            coords{idx, 2} = coord;
        end
    end
end

% different-texture pairs
for i_tex = 1:n_tex
    % prevent sampling any pair twice:
    prev_tex = cell2mat(tex(n_tex*n_trials+1:idx));
    if ~isempty(prev_tex)
        prev_tex = prev_tex(prev_tex(:, 2) == i_tex, 1); % textures previously paired with this
    end
    tex2 = datasample(setdiff(1:n_tex, [i_tex; prev_tex]), n_trials, 'replace', false);
    for i_trial = 1:n_trials
        i_tex2 = tex2(i_trial);
        idx = n_tex*n_trials+(i_tex-1)*n_trials+i_trial;
        tex{idx} = [i_tex, i_tex2];

        % patch 1
        [patch1, seed, ~, coord] = lib.texture_patch('tex_num', i_tex);
        stimuli(:, :, 1, idx) = patch1;
        seeds(idx, 1) = seed;
        coords{idx, 1} = coord;

        % patch 2
        [patch2, seed, ~, coord] = lib.texture_patch('tex_num', i_tex2);
        stimuli(:, :, 2, idx) = patch2;
        seeds(idx, 2) = seed;
        coords{idx, 2} = coord;
    end
end
