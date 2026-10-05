% GROUPING  Texture-region grouping experiment.
%
% Call these as experiment.grouping.<package>.<name>(...) once setup.m has
% put the repo on the path. Not currently runnable end to end — see
% +run/Contents.m for the specific broken links (B2.8, B2.9).
%
%   +prep - One-time stimulus generation and file setup (run before any subject).
%   +run    - Session loading, and RUN_EXPERIMENT, which wires the trial-loop
%             hooks shared with the discriminate tree (experiment.run).
