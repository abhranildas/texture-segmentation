function setup_experiment
%SETUP_EXPERIMENT  Build and save the grouping experiment's stimuli and settings.
%   experiment.grouping.prep.setup_experiment
%
%   For each of 6 sessions, calls GROUPING.MK_TEXSEG_SESSION to build a
%   texture-segmentation session (one of 3 texture families, chosen by
%   session_tex_ids), then GROUPING.MK_TRL_POINTS once per trial/level to
%   render that session's cue/stimulus/feedback images, gamma-correcting
%   each via LIB.GAMMA_CORRECT. Packs everything into exp_settings and
%   saves it to exp_files/grouping/exp_settings.mat for SETUP_SUBJECT and
%   the +run package to load. Takes no arguments; exp_type is fixed to
%   'grouping'. This is the entry point, run once before any subject.
%
%   Output
%     none (writes exp_files/grouping/exp_settings.mat; see Note)
%
%   Note: exp_settings (the saved variable name) and the struct field names
%   below (nTexs, bgPixVal, stimulusIntervalMs, etc.) are frozen cross-file
%   vocabulary shared with SETUP_SUBJECT and every +run hook, and are left
%   unrenamed even where camelCase; only this function's own local
%   variables were converted to snake_case.
%
%   See also EXPERIMENT.GROUPING.PREP.SETUP_SUBJECT, GROUPING.MK_TEXSEG_SESSION,
%   GROUPING.MK_TRL_POINTS.

exp_type = 'grouping';

tex_sets = {'brodatz', 'fabric', 'pertex'}; % texture families
n_texs = [60 60 334]; % # of textures in each family
session_tex_ids = [1 1 2 2 3 3]; % texture family id for each session

stim_sz = 1024;
patch_sz = 64; % size of a texture patch square
n_patches = stim_sz/patch_sz; % # of texture patches along each side

monitor_bit = 8;
monitor_gamma = 2.059;

n_trials = 96; % number of trials in each contrast level
n_levels = 5; % number of contrast levels
n_sessions = 6; % number of texture sessions
n_regions = 5; % number of texture regions in each stimulus

% array containing texture numbers used for each stimulus
tex_ids = nan(n_regions, n_trials, n_levels, n_sessions);
% seeds = nan(n_trials, n_levels, n_sessions);
% condition of each trial: is_diff_trial=1 (different), 0 (same)
is_diff_trial = false(n_trials, n_levels, n_sessions);
cue_imgs = zeros(stim_sz, stim_sz, n_trials, n_levels, n_sessions, 'uint8');
stimuli = zeros(stim_sz, stim_sz, n_trials, n_levels, n_sessions, 'uint8');
% stimuli + cue images
feedback_imgs = zeros(stim_sz, stim_sz, n_trials, n_levels, n_sessions, 'uint8');
contrasts = repmat([.1 .075 .05 .03 .02], [n_trials 1 n_sessions]); % contrast levels of each trial
% 2x2 matrix [x1 y1; x2 y2] of cue locations for each trial.
cue_locs = nan(2, 2, n_trials, n_levels, n_sessions);

for i_session = 1:n_sessions
    tex_id = session_tex_ids(i_session);
    tex_set = tex_sets{tex_id};
    n_tex = n_texs(tex_id);
    % call Bill's function to create session struct
    session = grouping.mk_texseg_session(tex_set, n_tex);

    % store same/different condition
    same_temp = logical(session.cuelocs(:, 1));
    is_diff_trial(:, :, i_session) = reshape(same_temp, [n_trials n_levels]);

    % store cue locations
    cue_locs_temp = session.cuelocs(:, 2:end);
    cue_locs(:, :, :, :, i_session) = ...
        reshape(cue_locs_temp(:, [2 4 1 3])', [2 2 n_trials n_levels]);

    % store region maps
    maps = reshape(session.maps, [n_patches n_patches n_trials n_levels]);

    % store texture id's in each stimulus
    tex_ids(:, :, :, i_session) = reshape(session.texs', [n_regions n_trials n_levels]);

    % generate and store stimuli
    stimuli_flat = zeros([stim_sz stim_sz n_trials*n_levels], 'uint8');
    cue_imgs_flat = zeros([stim_sz stim_sz n_trials*n_levels], 'uint8');
    feedback_imgs_flat = zeros([stim_sz stim_sz n_trials*n_levels], 'uint8');
    for i_trial_flat = 1:n_trials*n_levels
        [i_session i_trial_flat]
        c0 = session.cntrst(i_trial_flat);
        [~, cue_img, stim, fimg] = grouping.mk_trl_points(i_trial_flat, session.sz, session.pw, ...
            session.m0, session.tex_set, c0, session.cuelocs, session.texs, session.maps);
        cue_imgs_flat(:, :, i_trial_flat) = ...
            uint8(lib.gamma_correct(cue_img, monitor_gamma, monitor_bit));
        stimuli_flat(:, :, i_trial_flat) = ...
            uint8(lib.gamma_correct(stim, monitor_gamma, monitor_bit));
        feedback_imgs_flat(:, :, i_trial_flat) = ...
            uint8(lib.gamma_correct(fimg, monitor_gamma, monitor_bit));
    end

    cue_imgs(:, :, :, :, i_session) = reshape(cue_imgs_flat, [stim_sz stim_sz n_trials n_levels]);
    stimuli(:, :, :, :, i_session) = reshape(stimuli_flat, [stim_sz stim_sz n_trials n_levels]);
    feedback_imgs(:, :, :, :, i_session) = ...
        reshape(feedback_imgs_flat, [stim_sz stim_sz n_trials n_levels]);

end

exp_settings = struct(...
    'exp_type', exp_type,...
    'tex_sets', {tex_sets},...
    'nTexs', n_texs,... % 'seeds', seeds,...
    'stim_sz', stim_sz,...
    'nRegions', n_regions,...
    'nTrials', n_trials,...
    'nLevels', n_levels,...
    'nSessions', n_sessions, ...
    'tex_ids', tex_ids,...
    'cue_locs', cue_locs,...
    'diff', is_diff_trial,...
    'maps', maps,...
    'stimuli', stimuli,...
    'cue_imgs', cue_imgs,...
    'feedback_imgs', feedback_imgs,...
    'contrasts', contrasts,...
    'loadSessionStimuli', @experiment.grouping.run.load_stimuli, ...
    'luminance', 0.5,...
    'ppd', 60,...
    'monitor_bit', monitor_bit,...
    'monitor_gamma', monitor_gamma,...
    'moniter_brightness', 50,...
    'monitor_contrast', 100,...
    'monitorMaxPix', 255, ...
    'bgPixVal', 0.5*255, ...
    'cueIntervalMs', 200,...
    'blankIntervalMs', 50, ...
    'stimulusIntervalMs', 200,...
    'responseIntervalMs', 500, ...
    'feedbackIntervalMs', 100);

folder_out = ['exp_files/' exp_type];
mkdir(folder_out);
save([folder_out '/exp_settings.mat'], 'exp_settings', '-v7.3');

end
