function [response, rt] = response_interval(session_settings)
%RESPONSE_INTERVAL  Wait for a left/right-arrow response, or ESC to abort.
%   [response, rt] = experiment.discriminate.run.response_interval(session_settings)
%
%   Waits for a response to be made. If the response is made during the
%   response interval the response value is returned. Otherwise, the
%   function returns without any response. ESC aborts the whole experiment
%   (closes the screen and errors out). rt is declared but never assigned
%   (B3.16) — a caller that requests it as a second output errors.
%
%   Inputs
%     session_settings  Struct from LOAD_STIMULI. Fields read: window;
%                        responseIntervalS (seconds); fixationTarget (image
%                        array); fixPosPix (screen pixel coordinates).
%
%   Output
%     response  -1 (no response), 0 (left arrow), or 1 (right arrow).
%     rt         Intended reaction time; not implemented (B3.16).
%
%   See also EXPERIMENT.DISCRIMINATE.RUN.STIMULUS_INTERVAL,
%   EXPERIMENT.DISCRIMINATE.RUN.GIVE_FEEDBACK.
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
    elseif (key_code(KbName('ESCAPE')))
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
