function display_level_start(session_settings)
%DISPLAY_LEVEL_START  Show the target outline and start-of-block prompt.
%   experiment.run.display_level_start(session_settings)
%
%   Draws both target-outline stimuli and the fixation cross at the trial
%   positions used for this block, together with a "Session N Level M,
%   press any key to start" prompt, then waits for a keypress before
%   returning. Called once per block, from either experiment's
%   RUN_EXPERIMENT level_start hook.
%
%   Shared by both experiment trees (S1.1): their two copies were the same
%   code. Only the discriminate tree's loaders set every field read below.
%   The grouping tree's LOAD_STIMULI sets neither stim1PosPix/stim2PosPix
%   (it sets a single stimPosPix) nor targetOutline, so a live call from
%   that tree errors (B2.9).
%
%   Inputs
%     session_settings  Struct from LOAD_CURRENT_SESSION/LOAD_STIMULI. Fields
%                        read: window; fixPosPix, stim1PosPix, stim2PosPix
%                        (screen pixel coordinates); fixationTarget,
%                        targetOutline (gamma-corrected image arrays);
%                        pixelsPerDeg; currentSession; currentLevel.
%
%   See also EXPERIMENT.DISCRIMINATE.RUN.RUN_EXPERIMENT,
%   EXPERIMENT.GROUPING.RUN.RUN_EXPERIMENT, EXPERIMENT.RUN.FIXATION_INTERVAL.

% Display the fixation and stimulus position from a random trial in the block
fix_pos_pix_xy = session_settings.fixPosPix;
stim1_pos_pix_xy = session_settings.stim1PosPix;
stim2_pos_pix_xy = session_settings.stim2PosPix;

win = session_settings.window;

%% Set up
fix_target = session_settings.fixationTarget;
fix_texture = Screen('Maketexture', session_settings.window, fix_target);
fix_rect = SetRect(0, 0, size(fix_target, 2), size(fix_target, 1));
fix_destination = floor(CenterRectOnPointd(fix_rect, fix_pos_pix_xy(1), fix_pos_pix_xy(2)));

%% Draw the target outline, then the fixation cross on top

Screen('TextSize', win, 25);
DrawFormattedText(win, sprintf('Session %d Level %d\n\n Press any key to start.', ...
    session_settings.currentSession, session_settings.currentLevel), ...
    'center', session_settings.pixelsPerDeg);

target_img = session_settings.targetOutline;
target_texture = Screen('MakeTexture', session_settings.window, target_img);

target_rect = SetRect(0, 0, size(target_img, 2), size(target_img, 1));
target1_destination = floor(CenterRectOnPointd(target_rect, ...
    stim1_pos_pix_xy(1), stim1_pos_pix_xy(2)));
target2_destination = floor(CenterRectOnPointd(target_rect, ...
    stim2_pos_pix_xy(1), stim2_pos_pix_xy(2)));

% if SessionSettings.bFovea % If foveal experiment, then draw stimulus after fixation cross.
%     Screen('DrawTexture', SessionSettings.window, fixTexture, [], fixDestination);
%     Screen('DrawTexture', SessionSettings.window, targetTexture, [], targetDestination);
% else
Screen('DrawTexture', session_settings.window, target_texture, [], target1_destination);
Screen('DrawTexture', session_settings.window, target_texture, [], target2_destination);
Screen('DrawTexture', session_settings.window, fix_texture, [], fix_destination);
% end
Screen('Flip', session_settings.window);

%WaitSecs(10); %Adapt to background luminance

KbWait();

WaitSecs(1);

end
