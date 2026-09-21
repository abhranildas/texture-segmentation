% GENERAL  Whole-experiment simulation and analysis scripts.
%
% All three files here are scripts, not functions, so none of them can be
% called as general.<name>; run the file directly. Converting them into
% proper functions is Stage 3 item S2.5.
%
% Simulation and model fitting
%   simulate_discrimination     - Simulate texture discrimination from image
%                                 patches: draw same/different Brodatz patch
%                                 pairs, compute a decision variable per cue,
%                                 and fit a quadratic boundary per cue and one
%                                 combining them all. Does not run as written:
%                                 its natural-image-bins and Brodatz paths do
%                                 not resolve (B2.14, S2.4).
%   nat_near_far_patches_bayes  - Cut near and far patch pairs from the CPS
%                                 natural-image sets and save one .mat per
%                                 set. Does not run as written: hardcoded
%                                 addpath (B2.3), three missing functions
%                                 (B2.12), two missing .mat files (B2.13), and
%                                 wrong image-set-12 slice bounds (B1.3).
%
% Subject-data analysis
%   compute_exp_error_mat       - Texture-discrimination error matrix from
%                                 subject data, plus an accuracy-vs-
%                                 eccentricity curve. Needs exp_settings and
%                                 subject_file already in the workspace.
%
% See also LIB, GROUPING, EXPERIMENT.
