% EXPERIMENT  Psychtoolbox-based experiment trees for texture discrimination and grouping.
%
% Call these as experiment.<discriminate|grouping>.<package>.<name>(...)
% once setup.m has put the repo on the path. Each experiment type has its
% own +prep (one-time stimulus/file setup) and +run (trial-loop hooks)
% sub-packages, near-duplicate trees that share most of their structure
% (see S1.1/S2.1 for the recorded merge candidates).
%
%   +discriminate - Texture-patch discrimination experiment.
%   +grouping       - Texture-region grouping experiment.
