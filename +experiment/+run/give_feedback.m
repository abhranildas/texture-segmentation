function give_feedback(session_settings, response, trial_number)
%GIVE_FEEDBACK  Beep to indicate a correct, incorrect, or missed response.
%   experiment.run.give_feedback(session_settings, response, trial_number)
%
%   response == -1 (no response made) beeps errorFreqHz; a response that
%   matches session_settings.diffpair(trial_number) beeps correctFreqHz;
%   any other response beeps incorrectFreqHz. Called once per trial, from
%   either experiment's RUN_EXPERIMENT feedback hook.
%
%   Shared by both experiment trees (S1.1): their two copies were the same
%   code. The grouping tree's loaders never set diffpair, so any response
%   other than -1 errors there on a live call (B2.9).
%
%   Inputs
%     session_settings  Struct from LOAD_CURRENT_SESSION/LOAD_STIMULI. Field
%                        read: diffpair (per-trial correct-response vector).
%     response           Recorded response for this trial: -1 (no
%                         response), 0, or 1.
%     trial_number        Index into session_settings.diffpair (integer count).
%
%   See also EXPERIMENT.RUN.RESPONSE_INTERVAL, EXPERIMENT.RUN.SAVE_CURRENT_LEVEL.

%% Sound parameters
correct_freq_hz = 900;
incorrect_freq_hz = 300;
error_freq_hz = 1500;

% Feedback
if (response == -1)
    Beeper(error_freq_hz);
    %sound(errorTone, sampleFreqHz);
elseif (session_settings.diffpair(trial_number) == response)
    Beeper(correct_freq_hz);
    %sound(correctTone, sampleFreqHz);
else
    Beeper(incorrect_freq_hz);
    %sound(incorrectTone, sampleFreqHz);
end

end
