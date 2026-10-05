function session_data = run_experiment(exp_type, subject_name, condition, ...
    session_number, level_number)
% RUN_EXPERIMENT  Launch the grouping experiment.
%   session_data = run_experiment(exp_type, subject_name ...
%       [, condition, session_number, level_number])
%
%   Delegates the level/trial loop and screen setup to the shared vislab
%   harness (vislab.psychframework.run_experiment), wiring this package's own interval
%   functions (stimulus_interval / give_feedback / display_level_start) and the two
%   shared with the discriminate tree (experiment.run.fixation_interval /
%   experiment.run.response_interval) as hooks. Runs the single current level (as the old
%   runExperiment/runLevel did) and prints per-level percent-correct. Foveal, so
%   no EyeLink hooks. The old runExperiment + runLevel + runTrial were retired in
%   favour of this shared harness (which also fixes their latent experiment.run.*
%   namespace references).
%
%   Run `setup` first (adds vislab). Requires Psychtoolbox.
%
%   Inputs
%     exp_type        Experiment type string; selects exp_files/<exp_type>/.
%     subject_name    Subject identifier.
%     condition        Bin condition row (only used with session_number/level_number).
%     session_number   1-based session index (only used with condition/level_number).
%     level_number      1-based level index within that session.
%
%   Output
%     session_data  Whatever VISLAB.PSYCHFRAMEWORK.RUN_EXPERIMENT returns for
%                    the completed level (its own responses/timing record).
%
%   See also EXPERIMENT.GROUPING.RUN.LOAD_CURRENT_SESSION,
%   EXPERIMENT.GROUPING.RUN.LOAD_STIMULI.

    if nargin < 4
        exp_settings = experiment.grouping.run.load_current_session(subject_name, exp_type);
    else
        exp_settings = experiment.grouping.run.load_current_session(subject_name, ...
            exp_type, condition, session_number, level_number);
    end
    exp_settings.screenNumber = 1;    % original forced screen 1

    hooks.load_session = @load_session;
    hooks.level_start  = @(s, l)       experiment.grouping.run.display_level_start(s);
    hooks.fixation     = @(s, t, l)    experiment.run.fixation_interval(s, false);  % no blank
    hooks.stimulus     = @(s, t, l)    experiment.grouping.run.stimulus_interval(s, t);
    hooks.response     = @(s, t, l)    experiment.run.response_interval(s, false);  % no ESC (B3.15)
    hooks.feedback     = @(s, r, t, l) experiment.grouping.run.give_feedback(s, r, t);
    hooks.save_level   = @(s, resp, l) experiment.grouping.run.save_current_level(s, resp, l);
    hooks.level_end    = @level_end;

    session_data = vislab.psychframework.run_experiment(exp_settings, hooks);
end

% ------------------------------------------------------------------------------
function s = load_session(exp_settings)
% Use the settings' injected stimulus loader, then run just the current level.
    s = exp_settings.loadSessionStimuli(exp_settings);             % = @load_stimuli
    s.level_list = s.currentLevel;
end

function level_end(s, responses, ~)
% 2AFC percent-correct summary (was the tail of runLevel.m).
    p_correct = mean(s.diffpair == responses) * 100;
    Screen('FillRect', s.window, s.bgPixValGamma);
    Screen('TextSize', s.window, 25);
    DrawFormattedText(s.window, sprintf('End of level: %d%% correct.', round(p_correct)), ...
        'center', 'center');
    Screen('Flip', s.window);
    WaitSecs(1);
end
