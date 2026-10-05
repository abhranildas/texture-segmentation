% DISCRIMINATE  Texture-patch discrimination experiment.
%
% Call these as experiment.discriminate.<package>.<name>(...) once setup.m
% has put the repo on the path.
%
%   +prep - One-time stimulus generation and file setup (run before any subject).
%   +run    - Trial-loop hooks, wired together by RUN_EXPERIMENT (which also
%             wires the two hooks shared with the grouping tree, in
%             experiment.run).
