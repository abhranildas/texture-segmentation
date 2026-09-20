function SessionData = run_experiment(exp_type, subject_name, condition, sessionNumber, levelNumber)
% RUN_EXPERIMENT  Launch the discrimination experiment.
%   run_experiment(exp_type, subject_name [, condition, sessionNumber, levelNumber])
%
%   Delegates the level/trial loop and screen setup to the shared vislab
%   harness (vislab.psychframework.run_experiment), wiring this package's interval functions
%   (fixation_interval / stimulus_interval / response_interval / give_feedback /
%   display_level_start) as hooks. Runs the single current level and prints per-level
%   percent-correct. Foveal, so no EyeLink hooks. The old runExperiment + runLevel
%   + runTrial were retired in favour of this shared harness.
%
%   Run `setup` first (adds vislab). Requires Psychtoolbox.

    if nargin < 4
        ExpSettings = experiment.discriminate.run.load_current_session(subject_name, exp_type);
    else
        ExpSettings = experiment.discriminate.run.load_current_session(subject_name, exp_type, condition, sessionNumber, levelNumber);
    end
    ExpSettings.screenNumber = 1;    % original forced screen 1

    hooks.load_session = @load_session;
    hooks.level_start  = @(S, l)       experiment.discriminate.run.display_level_start(S);
    hooks.fixation     = @(S, t, l)    experiment.discriminate.run.fixation_interval(S);
    hooks.stimulus     = @(S, t, l)    experiment.discriminate.run.stimulus_interval(S, t);
    hooks.response     = @(S, t, l)    experiment.discriminate.run.response_interval(S);
    hooks.feedback     = @(S, r, t, l) experiment.discriminate.run.give_feedback(S, r, t);
    hooks.save_level   = @(S, resp, l) experiment.discriminate.run.save_current_level(S, resp, l);
    hooks.level_end    = @level_end;

    SessionData = vislab.psychframework.run_experiment(ExpSettings, hooks);
end

% ------------------------------------------------------------------------------
function S = load_session(ExpSettings)
% Use the settings' injected stimulus loader, then run just the current level.
    S = ExpSettings.loadSessionStimuli(ExpSettings);             % = @load_stimuli
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
