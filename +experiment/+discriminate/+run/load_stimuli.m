function session_settings = load_stimuli(exp_settings)
%LOAD_STIMULI  Format and gamma-correct a session's stimuli for display.
%   session_settings = experiment.discriminate.run.load_stimuli(exp_settings)
%
%   Converts exp_settings (as returned by LOAD_CURRENT_SESSION) into the
%   session_settings struct the trial-loop hooks (DISPLAY_LEVEL_START,
%   FIXATION_INTERVAL, STIMULUS_INTERVAL, GIVE_FEEDBACK, SAVE_CURRENT_LEVEL)
%   read: computes screen positions in pixels, converts interval durations
%   from ms to s, clips and gamma-corrects the stimuli and target outline
%   to 8 bits, and builds the fixation-cross texture. Called via
%   exp_settings.loadSessionStimuli, from RUN_EXPERIMENT's load_session hook.
%
%   Inputs
%     exp_settings  Struct from LOAD_CURRENT_SESSION. Fields read: currentLevel,
%                    currentSession, monitorSizePix (pixels), stimuli, bgPixVal
%                    (0-255), ppd (pixels per degree), exp_type, stim_size
%                    (pixels), ecc (degrees, per level), *IntervalMs (ms),
%                    luminance, bgPixValGamma, subjectStr, expTypeStr,
%                    nTrials, nLevels, diffpair.
%
%   Output
%     session_settings  Struct read by every trial-loop hook; see the hooks'
%                        own headers for the fields each one reads.
%
%   See also EXPERIMENT.DISCRIMINATE.RUN.LOAD_CURRENT_SESSION,
%   EXPERIMENT.DISCRIMINATE.RUN.RUN_EXPERIMENT.

%% Set up

gamma_value = 2.059;

current_level = exp_settings.currentLevel;

current_session = exp_settings.currentSession;

monitor_size_pix = exp_settings.monitorSizePix;

stimuli = exp_settings.stimuli;
bg_pix_val = exp_settings.bgPixVal;
pixels_per_deg = exp_settings.ppd;

stim1_pos_deg = [0 .75];
stim2_pos_deg = [0 -.75];
stim1_pos_pix = lib.monitor_degrees_to_pixels(stim1_pos_deg, monitor_size_pix, pixels_per_deg);
stim2_pos_pix = lib.monitor_degrees_to_pixels(stim2_pos_deg, monitor_size_pix, pixels_per_deg);

if strcmpi(exp_settings.exp_type, 'joined')
    % put the two texture patches adjacent to each other
    stim1_pos_pix(2) = monitor_size_pix(2)/2 - exp_settings.stim_size/2;
    stim2_pos_pix(2) = monitor_size_pix(2)/2 + exp_settings.stim_size/2;
end

fix_pos_deg = [exp_settings.ecc(current_level) 0];
fix_pos_pix = lib.monitor_degrees_to_pixels(fix_pos_deg, monitor_size_pix, pixels_per_deg);

response_interval_s = exp_settings.responseIntervalMs/1000;
stimulus_interval_s = exp_settings.stimulusIntervalMs/1000;
fixation_interval_s = exp_settings.fixationIntervalMs/1000;
blank_interval_s = exp_settings.blankIntervalMs/1000;

%% Gamma correct stimuli
% and change to 8-bits

bit_depth_out = 8;

for i_trial = 1:size(stimuli, 4)
    for i_pair = [1 2]
        stim = stimuli(:, :, i_pair, i_trial);

        % clip:
        stim(stim > 1) = 1;
        stim(stim < 0) = 0;

        stim = lib.gamma_correct(stim, gamma_value, bit_depth_out);
        stimuli(:, :, i_pair, i_trial) = stim;
    end
end

%% Create target examples

% target outline
target_outline = zeros(exp_settings.stim_size);
target_outline(:, [1 end]) = 1;
target_outline([1 end], :) = 1;
target_outline = double(~target_outline);
target_outline(target_outline == 1) = exp_settings.luminance;
target_outline_gamma = lib.gamma_correct(target_outline, gamma_value, bit_depth_out);

%% Create the fixation target

fixation_size = round(pixels_per_deg.*0.1);
fixation_pixel_val = 0.7*bg_pix_val;
fixation_target = fixation_pixel_val.*ones(fixation_size, fixation_size);
fixation_target = lib.gamma_correct(fixation_target, gamma_value, bit_depth_out);

%% Save

session_settings = struct('stim1PosPix', stim1_pos_pix, 'stim2PosPix', stim2_pos_pix, ...
    'fixPosPix', fix_pos_pix, 'bgPixValGamma', exp_settings.bgPixValGamma, ...
    'targetOutline', target_outline_gamma, ...
    'responseIntervalS', response_interval_s, 'fixationIntervalS', fixation_interval_s, ...
    'stimulusIntervalS', stimulus_interval_s, 'blankIntervalS', blank_interval_s, ...
    'fixationTarget', fixation_target, 'nTrials', exp_settings.nTrials, ...
    'nLevels', exp_settings.nLevels, 'pixelsPerDeg', pixels_per_deg, ...
    'currentLevel', current_level, 'subjectStr', exp_settings.subjectStr, ...
    'expTypeStr', exp_settings.expTypeStr, 'currentSession', current_session, ...
    'stimuli', stimuli, 'diffpair', exp_settings.diffpair);

end
