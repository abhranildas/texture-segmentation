% RUN  Trial-loop hooks shared by both experiment trees.
%
% Call these as experiment.run.<name>(...) once setup.m has put the repo on
% the path. Both experiments' RUN_EXPERIMENT wire them as hooks for the
% shared vislab.psychframework.run_experiment harness, alongside the hooks
% that are still specific to one tree (see +discriminate/+run and
% +grouping/+run). A hook belongs here once its two copies are the same
% code and read only fields both trees' LOAD_STIMULI set. Where the two
% copies differed in behaviour, the difference is one logical argument that
% each tree's RUN_EXPERIMENT passes explicitly, so each tree still behaves
% exactly as its own copy did (S2.1).
%
%   fixation_interval  - Draw a fixation cross, then optionally a blank, at the fixation position.
%   response_interval  - Wait for a left/right-arrow response, optional ESC abort (B3.15, B3.16).
