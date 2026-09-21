function fixation_interval(session_settings)
%FIXATION_INTERVAL  Draw a fixation cross at the fixation position.
%   experiment.grouping.run.fixation_interval(session_settings)
%
%   Shows the fixation-cross texture for fixationIntervalS seconds. The
%   trailing blank interval that the discriminate tree's copy of this file
%   draws is disabled here (see the commented-out block below; triaged in
%   section 3.1.4). Called once per trial, from RUN_EXPERIMENT's fixation
%   hook.
%
%   Inputs
%     session_settings  Struct from LOAD_CURRENT_SESSION/LOAD_STIMULI. Fields
%                        read: window; fixationTarget (image array);
%                        fixPosPix (screen pixel coordinates);
%                        fixationIntervalS (seconds).
%
%   See also EXPERIMENT.GROUPING.RUN.STIMULUS_INTERVAL,
%   EXPERIMENT.GROUPING.RUN.RUN_EXPERIMENT.
%
% v1.0, 1/20/2016, R. C. Walshe <calen.walshe@utexas.edu>

%% Set up
fix_target = session_settings.fixationTarget;
fix_pos_xy = session_settings.fixPosPix;
fixation_interval_s = session_settings.fixationIntervalS;

fix_texture = Screen('Maketexture', session_settings.window, fix_target);
target_rect = SetRect(0, 0, size(fix_target, 2), size(fix_target, 1));
target_destination = floor(CenterRectOnPointd(target_rect, fix_pos_xy(1), fix_pos_xy(2)));

%% Draw the fixation cross, then blank it

Screen('DrawTexture', session_settings.window, fix_texture, [], target_destination);
Screen('Flip', session_settings.window, 0, 1);
WaitSecs(fixation_interval_s);

% blank_interval_s = session_settings.blankIntervalS;
% Screen('FillRect', session_settings.window, session_settings.bgPixValGamma, target_destination);
% Screen('Flip', session_settings.window);
% WaitSecs(blank_interval_s);

end
