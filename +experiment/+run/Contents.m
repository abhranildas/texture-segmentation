% RUN  Trial-loop hooks shared by both experiment trees.
%
% Call these as experiment.run.<name>(...) once setup.m has put the repo on
% the path. Both experiments' RUN_EXPERIMENT wire them as hooks for the
% shared vislab.psychframework.run_experiment harness. A hook belongs here
% once its two copies are the same code. Where the two copies differed in
% behaviour, the difference is one logical argument that each tree's
% RUN_EXPERIMENT passes explicitly, so each tree still behaves exactly as
% its own copy did (S2.1). The other four hooks were the same code in both
% trees (S1.1), but they read fields that only the discriminate tree's
% loaders set (stim1PosPix, stim2PosPix, targetOutline, diffpair), so in
% the grouping tree they error on a live call (B2.9).
%
%   display_level_start - Show the target outline and start-of-block prompt (B2.9).
%   fixation_interval   - Draw a fixation cross, then optionally a blank, at the fixation position.
%   stimulus_interval   - Draw both stimuli, hold, then blank them (B2.9).
%   response_interval   - Wait for a left/right-arrow response, optional ESC abort (B3.15, B3.16).
%   give_feedback       - Beep to indicate a correct, incorrect, or missed response (B2.9).
%   save_current_level  - Save one level's responses into the subject's progress file (B2.9).
