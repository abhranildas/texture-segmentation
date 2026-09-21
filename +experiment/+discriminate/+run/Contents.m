% RUN  Trial-loop hooks for the discrimination experiment.
%
% Call these as experiment.discriminate.run.<name>(...) once setup.m has put
% the repo on the path. RUN_EXPERIMENT wires the rest as hooks for the
% shared vislab.psychframework.run_experiment harness.
%
% Session and level
%   load_current_session - Load the stimuli and settings for the next session.
%   load_stimuli          - Format and gamma-correct a session's stimuli for display.
%   run_experiment         - Launch the discrimination experiment.
%   save_current_level     - Save one level's responses into the subject's progress file.
%
% Per-trial display and response
%   display_level_start   - Show the target outline and start-of-block prompt.
%   fixation_interval      - Draw a fixation cross, then a blank, at the fixation position.
%   stimulus_interval      - Draw both stimuli, hold, then blank them.
%   response_interval      - Wait for a left/right-arrow response, or ESC to abort (B3.16).
%   give_feedback          - Beep to indicate a correct, incorrect, or missed response.
