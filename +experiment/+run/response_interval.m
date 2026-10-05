function [response, rt] = response_interval(session_settings, allow_abort)
%RESPONSE_INTERVAL  Wait for a left/right-arrow response, optionally ESC to abort.
%   [response, rt] = experiment.run.response_interval(session_settings, allow_abort)
%
%   Waits for a response to be made. If the response is made during the
%   response interval the response value is returned. Otherwise, the
%   function returns without any response. If allow_abort is true, ESC
%   aborts the whole experiment (closes the screen and errors out). Called
%   once per trial, from either experiment's RUN_EXPERIMENT response hook.
%
%   Shared by both experiment trees (S2.1): the discriminate and grouping
%   copies of this file were identical apart from the ESC branch, which the
%   grouping copy does not have (B3.15, still open). allow_abort keeps each
%   tree's behaviour: the discriminate tree passes true, the grouping tree
%   false. Every field read below is set the same way by both trees'
%   LOAD_STIMULI.
%
%   rt is declared but never assigned (B3.16) — a caller that requests it as
%   a second output errors. The response = -1 initializer below is likewise
%   never returned, because the response-interval timeout it documents was
%   never implemented (B3.23); it is left in place as the only record of
%   that missing feature.
%
%   Inputs
%     session_settings  Struct from LOAD_STIMULI. Fields read: window;
%                        fixationTarget (image array); fixPosPix (screen
%                        pixel coordinates); responseIntervalS (seconds).
%     allow_abort       Logical. true to let ESC abort the experiment,
%                        false to ignore it.
%
%   Output
%     response  -1 (no response), 0 (left arrow), or 1 (right arrow).
%     rt         Intended reaction time; not implemented (B3.16).
%
%   See also EXPERIMENT.RUN.FIXATION_INTERVAL,
%   EXPERIMENT.DISCRIMINATE.RUN.RUN_EXPERIMENT,
%   EXPERIMENT.GROUPING.RUN.RUN_EXPERIMENT.
%
%  R. Calen Walshe January 14, 2016.

%% Set up
response_interval_s = session_settings.responseIntervalS;

target = session_settings.fixationTarget;
fix_pos_xy = session_settings.fixPosPix;

target_texture = Screen('Maketexture', session_settings.window, target);
target_rect = SetRect(0, 0, size(target, 2), size(target, 1));
target_destination = floor(CenterRectOnPointd(target_rect, fix_pos_xy(1), fix_pos_xy(2)));

%% Draw fixation target and wait for response

Screen('DrawTexture', session_settings.window, target_texture, [], target_destination);
Screen('Flip', session_settings.window, 0, 1);

response = -1;
% rt = -1;

% record first response
while true
    [~, ~, key_code] = KbCheck;
    if (key_code(KbName('rightarrow')))
        response = 1;
        t0 = GetSecs();
        break
    elseif (key_code(KbName('leftarrow')))
        response = 0;
        t0 = GetSecs();
        break
    elseif allow_abort && key_code(KbName('ESCAPE'))
        sca; ShowCursor; ListenChar(0);
        error('Experiment aborted (ESC).')
    end
end

% wait for any altered responses
t = GetSecs();
while t < t0 + response_interval_s/2
    [~, ~, key_code] = KbCheck;
    if (key_code(KbName('rightarrow')))
        response = 1;
    elseif (key_code(KbName('leftarrow')))
        response = 0;
    end
    t = GetSecs();
end

end
