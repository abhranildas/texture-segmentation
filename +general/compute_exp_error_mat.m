function [err_mat_all, subject_accuracy] = compute_exp_error_mat(exp_settings, subject_file)
%COMPUTE_EXP_ERROR_MAT  Texture-discrimination error matrix from subject data.
%   [err_mat_all, subject_accuracy] = general.compute_exp_error_mat( ...
%       exp_settings, subject_file)
%
%   Builds, for each eccentricity level, a symmetric n_tex x n_tex matrix of
%   proportion-correct for every texture pair the subject saw, sorts the
%   textures by their same-pair (diagonal) performance at the largest
%   eccentricity, and plots one pcolor map per level plus an accuracy-vs-
%   eccentricity curve.
%
%   Inputs (load both first, e.g. from exp_files/<type>/):
%     exp_settings  - experiment settings struct. Fields read: nTex (number of
%                     textures), nLevels (number of eccentricity levels),
%                     nTrials (trials per session), nSessions (sessions per
%                     level), tex (cell array, texture numbers per trial),
%                     ecc (eccentricity of each level, in degrees).
%     subject_file  - subject response struct. Fields read: idx (trial index
%                     into exp_settings.tex) and correct (1 = correct, 0 =
%                     incorrect), both nTrials x nLevels x nSessions.
%
%   Outputs
%     err_mat_all      - nTex x nTex x nLevels, proportion correct per texture
%                        pair per level, rows and columns sorted by the last
%                        level's diagonal (dimensionless fraction, 0 to 1).
%                        NaN wherever a pair was never presented.
%     subject_accuracy - nSessions x nLevels, proportion correct per session
%                        per level (dimensionless fraction, 0 to 1).
%
%   Note: exp_settings and subject_file are the variable names the two inputs
%   carry inside their .mat files, and all their field spellings are frozen
%   .mat-backed names, so none of them is renamed here (see the plan's
%   renaming zone 3). Hardcoding 4 levels in the loops below is bug B3.18.
%
%   See also GENERAL.SIMULATE_DISCRIMINATION.

    err_mat_all = nan(exp_settings.nTex, exp_settings.nTex, exp_settings.nLevels);

    for i_level = 1:4  % set eccentricity level

        err_mat = nan(exp_settings.nTex);
        err_mat(logical(eye(size(err_mat)))) = 0;

        % concatenate all sessions
        idx = reshape(permute(subject_file.idx, [2 1 3]), exp_settings.nLevels, ...
            exp_settings.nTrials*exp_settings.nSessions)';
        correct = reshape(permute(subject_file.correct, [2 1 3]), exp_settings.nLevels, ...
            exp_settings.nTrials*exp_settings.nSessions)';

        % textures presented in the experiment
        tex_nums = exp_settings.tex(idx(:, i_level));

        for i_trial = 1:numel(tex_nums)
            tex_pair = sort(tex_nums{i_trial});
            if numel(tex_pair) == 1  % same pair
                err_mat(tex_pair, tex_pair) = err_mat(tex_pair, tex_pair) + ...
                    correct(i_trial, i_level);
            else  % different pair
                err_mat(tex_pair(1), tex_pair(2)) = correct(i_trial, i_level);
            end
        end

        % change diagonals from counts to proportion correct
        err_mat(logical(eye(size(err_mat)))) = diag(err_mat) / ...
            (exp_settings.nTrials*exp_settings.nSessions/(2*exp_settings.nTex));

        % symmetrize the matrix
        err_mat = triu(err_mat) + triu(err_mat, 1)';

        err_mat_all(:, :, i_level) = err_mat;
    end

    % sort by diagonal errors of the last eccentricity level, and plot
    [~, sort_idx] = sort(diag(err_mat_all(:, :, exp_settings.nLevels)), 'descend');

    for i_level = 1:4
        err_mat = err_mat_all(:, :, i_level);
        err_mat = err_mat(sort_idx, sort_idx);
        err_mat_all(:, :, i_level) = err_mat;

        figure;
        h_pcolor = pcolor(err_mat_all(:, :, i_level));
        set(h_pcolor, 'edgecolor', 'none');
        axis image;
        colormap winter;
        colorbar;
        set(gca, 'YDir', 'reverse');
        set(gca, 'xtick', [1 60]);
        set(gca, 'ytick', [1 60]);
        set(gca, 'fontsize', 13);
        xlabel 'texture #';
        ylabel 'texture #';
        title(sprintf('eccentricity: %.1f', exp_settings.ecc(i_level)));
    end

    %% plot accuracy vs eccentricity
    subject_accuracy = squeeze(mean(subject_file.correct, 1))';

    figure;
    hold on;
    errorbar(exp_settings.ecc, mean(subject_accuracy), std(subject_accuracy), '-ok', ...
        'markerfacecolor', 'k');
    xlabel 'eccentricity (deg)';
    ylabel 'accuracy';
end
