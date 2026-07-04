function SessionData = run_shared(subject_name, exp_type, condition, sessionNumber, levelNumber)
% RUN_SHARED  Launch the grouping experiment via the shared harness.
%   run_shared(subject_name, exp_type [, condition, sessionNumber, levelNumber])
%
%   Behaviour-equivalent replacement for runExperiment.m that delegates the
%   level/trial loop and screen setup to the shared vision-commons harness
%   (psychexp.run_experiment), wiring this package's existing interval functions
%   (fixationInterval / stimulusInterval / responseInterval / giveFeedback /
%   displayLevelStart) as hooks. Runs the single current level (as the original
%   runExperiment/runLevel did) and prints per-level percent-correct. Foveal, so
%   no EyeLink hooks. The original runExperiment.m is kept until this is validated
%   on a Psychtoolbox machine (see ../../../CLEANUP.md).
%
%   Note: the calls here use the correct experiment.grouping.run.* namespace; the
%   original runLevel/runTrial referenced experiment.run.* (a latent bug).
%
%   Run `setup` first (adds vision-commons). Requires Psychtoolbox.

    if nargin < 4
        ExpSettings = experiment.grouping.run.loadCurrentSession(subject_name, exp_type);
    else
        ExpSettings = experiment.grouping.run.loadCurrentSession(subject_name, exp_type, condition, sessionNumber, levelNumber);
    end
    ExpSettings.screenNumber = 1;    % original forced screen 1

    hooks.load_session = @load_session;
    hooks.level_start  = @(S, l)       experiment.grouping.run.displayLevelStart(S);
    hooks.fixation     = @(S, t, l)    experiment.grouping.run.fixationInterval(S);
    hooks.stimulus     = @(S, t, l)    experiment.grouping.run.stimulusInterval(S, t);
    hooks.response     = @(S, t, l)    experiment.grouping.run.responseInterval(S);
    hooks.feedback     = @(S, r, t, l) experiment.grouping.run.giveFeedback(S, r, t);
    hooks.save_level   = @(S, resp, l) experiment.grouping.run.saveCurrentLevel(S, resp, l);
    hooks.level_end    = @level_end;

    SessionData = psychexp.run_experiment(ExpSettings, hooks);
end

% ------------------------------------------------------------------------------
function S = load_session(ExpSettings)
% Use the settings' injected stimulus loader, then run just the current level.
    S = ExpSettings.loadSessionStimuli(ExpSettings);             % = @loadStimuli
    S.level_list = S.currentLevel;
end

function level_end(S, responses, ~)
% 2AFC percent-correct summary (was the tail of runLevel.m).
    pCorrect = mean(S.diffpair == responses) * 100;
    Screen('FillRect', S.window, S.bgPixValGamma);
    Screen('TextSize', S.window, 25);
    DrawFormattedText(S.window, sprintf('End of level: %d%% correct.', round(pCorrect)), 'center', 'center');
    Screen('Flip', S.window);
    WaitSecs(1);
end
