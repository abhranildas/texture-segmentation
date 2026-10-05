function fixation_interval(session_settings, blank_after)
%FIXATION_INTERVAL  Draw a fixation cross, then optionally a blank, at the fixation position.
%   experiment.run.fixation_interval(session_settings, blank_after)
%
%   Shows the fixation-cross texture for fixationIntervalS seconds. If
%   blank_after is true it then blanks it (fills the same rect with the
%   gamma-corrected background) for blankIntervalS seconds. Called once per
%   trial, from either experiment's RUN_EXPERIMENT fixation hook.
%
%   Shared by both experiment trees (S2.1). The two copies were the same
%   code except that the grouping copy had the trailing blank commented out
%   (Stage 1 triage verdict: alternative). blank_after keeps each tree's
%   behaviour: the discriminate tree passes true, the grouping tree false.
%   It does not fold into blankIntervalS, because the blank also flips the
%   screen, which a zero-length wait would still do. Whether the grouping
%   tree should blank too is still open; its SETUP_EXPERIMENT does set
%   blankIntervalMs to 50, which suggests it once did.
%
%   Inputs
%     session_settings  Struct from LOAD_CURRENT_SESSION/LOAD_STIMULI. Fields
%                        read: window; fixationTarget (image array);
%                        fixPosPix (screen pixel coordinates);
%                        fixationIntervalS (seconds); and, only when
%                        blank_after is true, blankIntervalS (seconds) and
%                        bgPixValGamma.
%     blank_after       Logical. true to blank the fixation rect after the
%                        fixation interval, false to leave it drawn.
%
%   See also EXPERIMENT.RUN.RESPONSE_INTERVAL,
%   EXPERIMENT.DISCRIMINATE.RUN.RUN_EXPERIMENT,
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

%% Draw the fixation cross, then optionally blank it

Screen('DrawTexture', session_settings.window, fix_texture, [], target_destination);
Screen('Flip', session_settings.window, 0, 1);
WaitSecs(fixation_interval_s);

if blank_after
    blank_interval_s = session_settings.blankIntervalS;
    Screen('FillRect', session_settings.window, session_settings.bgPixValGamma, target_destination);
    Screen('Flip', session_settings.window);
    WaitSecs(blank_interval_s);
end

end
