% RUN  Trial-loop hooks for the grouping experiment.
%
% Call these as experiment.grouping.run.<name>(...) once setup.m has put the
% repo on the path. RUN_EXPERIMENT wires the trial-loop hooks for the
% shared vislab.psychframework.run_experiment harness. The hooks themselves
% live in the shared +experiment/+run package, which both experiment trees
% call (S2.1, S1.1). What stays here is this tree's own session loading.
% This tree is not currently runnable end to end: LOAD_STIMULI errors on
% every call (B2.8), and four of the shared hooks read fields it and
% LOAD_CURRENT_SESSION never set (B2.9) — see each file's own header for
% specifics.
%
%   load_current_session - Load the stimuli and settings for the next session (B2.9, B3.14).
%   load_stimuli          - Format stimuli for display, and build the fixation target (B2.8, B2.9).
%   run_experiment         - Launch the grouping experiment.
