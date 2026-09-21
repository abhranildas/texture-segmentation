% PREP  One-time stimulus generation and file setup for the discrimination experiment.
%
% Call these as experiment.discriminate.prep.<name>(...) once setup.m has put
% the repo on the path. SETUP_EXPERIMENT is run once per experiment type,
% before any subject; SETUP_SUBJECT is run once per subject, after that.
%
%   setup_experiment - Build and save this experiment type's stimuli and settings.
%   generate_stimuli   - Sample the texture-patch stimuli SETUP_EXPERIMENT saves.
%   setup_subject     - Create a fresh subject progress/response file.
