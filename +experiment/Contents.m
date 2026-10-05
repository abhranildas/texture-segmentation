% EXPERIMENT  Psychtoolbox-based experiment trees for texture discrimination and grouping.
%
% Call these as experiment.<discriminate|grouping>.<package>.<name>(...)
% once setup.m has put the repo on the path. Each experiment type has its
% own +prep (one-time stimulus/file setup) and +run (trial-loop hooks)
% sub-packages, near-duplicate trees that share most of their structure.
% The hooks whose two copies were the same code live once, in the shared
% +run package below (S2.1). The two trees' session-loading and
% subject-setup files stay separate: LOAD_STIMULI builds a different
% display struct per experiment, and LOAD_CURRENT_SESSION/SETUP_SUBJECT
% differ by whether the subject file carries a randomized stimulus index,
% which is still an open question (B2.9, B3.14).
%
%   +run          - Trial-loop hooks shared by both experiments.
%   +discriminate - Texture-patch discrimination experiment.
%   +grouping       - Texture-region grouping experiment.
