function tex_nums = mk_texs(n_tex, n_tex_regions, n_trials)
% MK_TEXS  Assign a texture to every region of every trial in a session.
%   tex_nums = grouping.mk_texs(n_tex, n_tex_regions, n_trials)
%
%   Draws from a pool built by concatenating independent random permutations of
%   1:n_tex, then hands out the pool in order, so every texture is used about
%   equally often across the session rather than by chance. The pool is rounded
%   up to a whole number of permutations, and the tail beyond the last trial is
%   discarded. Nothing stops the same texture appearing twice within one trial.
%
%   Inputs
%     n_tex         - number of texture sheets to choose from.
%     n_tex_regions - number of texture regions per image.
%     n_trials      - number of trials in the session.
%
%   Output
%     tex_nums - n_trials by n_tex_regions array of texture numbers, each in
%                1:n_tex.
%
%   See also GROUPING.MK_MASKS, GROUPING.MK_TEXSEG_SESSION.

    tex_nums = zeros(n_trials, n_tex_regions);

    % build a pool of randomly ordered texture numbers, at least as long as
    % the output array
    n_pool = (floor(n_tex_regions*n_trials/n_tex) + 1)*n_tex;
    tex_pool = zeros(n_pool, 1);
    for ii = 1:n_tex:n_pool
        tex_perm = randperm(n_tex);
        for jj = 1:n_tex
            tex_pool(ii+jj-1) = tex_perm(jj);
        end
    end

    % hand the pool out to the trials in order
    for ii = 1:n_trials
        for jj = 1:n_tex_regions
            tex_nums(ii, jj) = tex_pool((ii-1)*n_tex_regions + jj);
        end
    end
end
