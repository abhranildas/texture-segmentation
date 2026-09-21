% RUN  Trial-loop hooks for the grouping experiment.
%
% Call these as experiment.grouping.run.<name>(...) once setup.m has put the
% repo on the path. RUN_EXPERIMENT wires the rest as hooks for the shared
% vislab.psychframework.run_experiment harness. This tree is not currently
% runnable end to end: LOAD_STIMULI errors on every call (B2.8), and several
% of these files depend on fields it and LOAD_CURRENT_SESSION never set
% (B2.9) — see each file's own header for specifics.
%
% Session and level
%   load_current_session - Load the stimuli and settings for the next session (B2.9, B3.14).
%   load_stimuli          - Format stimuli for display, and build the fixation target (B2.8, B2.9).
%   run_experiment         - Launch the grouping experiment.
%   save_current_level     - Save one level's responses into the subject's progress file (B2.9).
%
% Per-trial display and response
%   display_level_start   - Show the target outline and start-of-block prompt (B2.9).
%   fixation_interval      - Draw a fixation cross at the fixation position.
%   stimulus_interval      - Draw both stimuli, hold, then blank them (B2.9).
%   response_interval      - Wait for a left/right-arrow response (B3.15, B3.16).
%   give_feedback          - Beep to indicate a correct, incorrect, or missed response (B2.9).
