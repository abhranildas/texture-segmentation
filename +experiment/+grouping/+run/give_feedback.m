function give_feedback(session_settings, response, trial_number)
%GIVE_FEEDBACK  Beep to indicate a correct, incorrect, or missed response.
%   experiment.grouping.run.give_feedback(session_settings, response, trial_number)
%
%   response == -1 (no response made) beeps errorFreqHz; a response that
%   matches session_settings.diffpair(trial_number) beeps correctFreqHz;
%   any other response beeps incorrectFreqHz. Called once per trial, from
%   RUN_EXPERIMENT's feedback hook. session_settings.diffpair is never set
%   in this tree (see B2.9), so the elseif on line below errors on every
%   live call.
%
%   Inputs
%     session_settings  Struct from LOAD_CURRENT_SESSION/LOAD_STIMULI. Field
%                        read: diffpair (per-trial correct-response vector).
%     response           Recorded response for this trial: -1 (no
%                         response), 0, or 1.
%     trial_number        Index into session_settings.diffpair (integer count).
%
%   See also EXPERIMENT.GROUPING.RUN.RESPONSE_INTERVAL,
%   EXPERIMENT.GROUPING.RUN.SAVE_CURRENT_LEVEL.

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
