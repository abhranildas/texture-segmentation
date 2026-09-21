% PREP  One-time stimulus generation and file setup for the grouping experiment.
%
% Call these as experiment.grouping.prep.<name>(...) once setup.m has put
% the repo on the path. SETUP_EXPERIMENT is run once, before any subject
% (exp_type is fixed to 'grouping', so it takes no arguments); SETUP_SUBJECT
% is run once per subject, after that.
%
%   setup_experiment - Build and save the grouping experiment's stimuli and settings.
%   setup_subject     - Create a fresh subject progress/response file (B3.14).
