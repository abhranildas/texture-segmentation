function stimulus_onset_ms = stimulus_interval(session_settings, trial_number)
%STIMULUS_INTERVAL  Draw both stimuli, hold, then blank them.
%   stimulus_onset_ms = experiment.grouping.run.stimulus_interval(session_settings, ...
%       trial_number)
%
%   Draws stimulus 1 and 2 at their screen positions, holds for
%   stimulusIntervalS seconds, then fills both rects with the gamma-
%   corrected background. Called once per trial, from RUN_EXPERIMENT's
%   stimulus hook. Byte-identical to the discriminate tree's copy, so it
%   still reads stim1PosPix/stim2PosPix — fields this tree's own
%   LOAD_STIMULI never sets (see B2.9; it sets a single stimPosPix instead).
%
%   Inputs
%     session_settings  Struct from LOAD_STIMULI. Fields read: window;
%                        stimulusIntervalS (seconds); stimuli (image stack);
%                        stim1PosPix, stim2PosPix (screen pixel
%                        coordinates); bgPixValGamma.
%     trial_number         Index into session_settings.stimuli's 4th
%                           dimension.
%
%   Output
%     stimulus_onset_ms  Flip timestamp (seconds, from Screen('Flip'))
%                         of the blanking flip, despite the "Ms" in its name.
%
%   See also EXPERIMENT.GROUPING.RUN.FIXATION_INTERVAL,
%   EXPERIMENT.GROUPING.RUN.RESPONSE_INTERVAL.
%
% v1.0, 1/20/2016, R. C. Walshe <calen.walshe@utexas.edu>

%% Set up
stimulus_interval_s = session_settings.stimulusIntervalS;

stim1 = session_settings.stimuli(:, :, 1, trial_number);
stim2 = session_settings.stimuli(:, :, 2, trial_number);

stimulus1_texture = Screen('Maketexture', session_settings.window, stim1);
stimulus2_texture = Screen('Maketexture', session_settings.window, stim2);

stim1_pos_xy = session_settings.stim1PosPix;
stim2_pos_xy = session_settings.stim2PosPix;

stimulus_rect = SetRect(0, 0, size(stim1, 2), size(stim1, 1));
stimulus1_destination = floor(CenterRectOnPointd(stimulus_rect, stim1_pos_xy(1), stim1_pos_xy(2)));
stimulus2_destination = floor(CenterRectOnPointd(stimulus_rect, stim2_pos_xy(1), stim2_pos_xy(2)));

%% Display stimulus

Screen('DrawTexture', session_settings.window, stimulus1_texture, [], stimulus1_destination);
Screen('DrawTexture', session_settings.window, stimulus2_texture, [], stimulus2_destination);

[~, stimulus_onset_time] = Screen('Flip', session_settings.window, 0, 1);

WaitSecs(stimulus_interval_s); % Stimulus is on for stimulusIntervalS seconds.

Screen('FillRect', session_settings.window, session_settings.bgPixValGamma, stimulus1_destination);
Screen('FillRect', session_settings.window, session_settings.bgPixValGamma, stimulus2_destination);

[~, stimulus_onset_time] = Screen('Flip', session_settings.window, 0, 1);

stimulus_onset_ms = stimulus_onset_time;

end
