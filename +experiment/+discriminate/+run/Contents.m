% RUN  Trial-loop hooks for the discrimination experiment.
%
% Call these as experiment.discriminate.run.<name>(...) once setup.m has put
% the repo on the path. RUN_EXPERIMENT wires the trial-loop hooks for the
% shared vislab.psychframework.run_experiment harness. The hooks themselves
% live in the shared +experiment/+run package, which both experiment trees
% call (S2.1, S1.1). What stays here is this tree's own session loading.
%
%   load_current_session - Load the stimuli and settings for the next session.
%   load_stimuli          - Format and gamma-correct a session's stimuli for display.
%   run_experiment         - Launch the discrimination experiment.
