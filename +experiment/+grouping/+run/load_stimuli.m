function session_settings = load_stimuli(exp_settings)
%LOAD_STIMULI  Format stimuli for display, and build the fixation target.
%   session_settings = experiment.grouping.run.load_stimuli(exp_settings)
%
%   Converts exp_settings (as returned by LOAD_CURRENT_SESSION) into the
%   session_settings struct the trial-loop hooks read. Unlike the
%   discriminate tree's copy of this file, this version never gamma-corrects
%   session_settings.stimuli or builds a targetOutline, and it references
%   bit_depth_out (old bitDepthOut) below without ever assigning it — it
%   errors immediately on every call (B2.8). It also references
%   exp_settings.diffpair, which this tree's LOAD_CURRENT_SESSION never
%   sets (B2.9), and builds a single stimPosPix rather than the
%   stim1PosPix/stim2PosPix that DISPLAY_LEVEL_START and STIMULUS_INTERVAL
%   (byte-identical to the discriminate tree's copies) both read.
%
%   Inputs
%     exp_settings  Struct from LOAD_CURRENT_SESSION. Fields read: currentLevel,
%                    currentSession, monitorSizePix (pixels), stimuli, bgPixVal
%                    (0-255), ppd (pixels per degree), ecc (degrees, per
%                    level), *IntervalMs (ms), bgPixValGamma, subjectStr,
%                    expTypeStr, nTrials, nLevels, diffpair.
%
%   Output
%     session_settings  Struct intended to be read by every trial-loop
%                        hook; incomplete as written (see above).
%
%   See also EXPERIMENT.GROUPING.RUN.LOAD_CURRENT_SESSION,
%   EXPERIMENT.GROUPING.RUN.RUN_EXPERIMENT.

%% Set up

gamma_value = 2.059;

current_level = exp_settings.currentLevel;

current_session = exp_settings.currentSession;

monitor_size_pix = exp_settings.monitorSizePix;

stimuli = exp_settings.stimuli;
bg_pix_val = exp_settings.bgPixVal;
pixels_per_deg = exp_settings.ppd;

stim_pos_deg = [0 0];
stim_pos_pix = lib.monitor_degrees_to_pixels(stim_pos_deg, monitor_size_pix, pixels_per_deg);

fix_pos_deg = [exp_settings.ecc(current_level) 0];
fix_pos_pix = lib.monitor_degrees_to_pixels(fix_pos_deg, monitor_size_pix, pixels_per_deg);

response_interval_s = exp_settings.responseIntervalMs/1000;
stimulus_interval_s = exp_settings.stimulusIntervalMs/1000;
fixation_interval_s = exp_settings.fixationIntervalMs/1000;
blank_interval_s = exp_settings.blankIntervalMs/1000;

%% Create the fixation target

fixation_size = round(pixels_per_deg.*0.1);
fixation_pixel_val = 0.5*bg_pix_val;
fixation_target = fixation_pixel_val.*ones(fixation_size, fixation_size);
fixation_target = lib.gamma_correct(fixation_target, gamma_value, bit_depth_out);

%% Save

session_settings = struct('stimPosPix', stim_pos_pix, ...
    'fixPosPix', fix_pos_pix, 'bgPixValGamma', exp_settings.bgPixValGamma, ...
    'responseIntervalS', response_interval_s, 'fixationIntervalS', fixation_interval_s, ...
    'stimulusIntervalS', stimulus_interval_s, 'blankIntervalS', blank_interval_s, ...
    'fixationTarget', fixation_target, 'nTrials', exp_settings.nTrials, ...
    'nLevels', exp_settings.nLevels, 'pixelsPerDeg', pixels_per_deg, ...
    'currentLevel', current_level, 'subjectStr', exp_settings.subjectStr, ...
    'expTypeStr', exp_settings.expTypeStr, 'currentSession', current_session, ...
    'stimuli', stimuli, 'diffpair', exp_settings.diffpair);

end
