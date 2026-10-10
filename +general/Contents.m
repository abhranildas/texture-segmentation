% GENERAL  Whole-experiment simulation and analysis functions.
%
% Call these as general.<name>(...) once setup.m has put the repo on the path.
%
% Simulation and model fitting
%   simulate_discrimination     - Simulate texture discrimination from image
%                                 patches: draw same/different Brodatz patch
%                                 pairs, compute a decision variable per cue,
%                                 and fit a quadratic boundary per cue and one
%                                 combining them all. Its data paths now come
%                                 from CONFIG and all resolve (S2.4, B2.14),
%                                 but it still does not run: its first
%                                 LIB.EDGE_PROPS_STIM call errors (B2.15), and
%                                 the experimental-overlay section reads a
%                                 nonexistent exp_files/norm (B3.1).
%   nat_near_far_patches_bayes  - Cut near and far patch pairs from the CPS
%                                 natural-image sets and save one .mat per set
%                                 into cfg.paths.stimuli. Its image and output
%                                 paths now come from CONFIG (B2.3), but it
%                                 still does not run: three missing functions
%                                 (B2.12) and two .mat files that are not in
%                                 the shared data store (B2.13).
%
% Subject-data analysis
%   compute_exp_error_mat       - Texture-discrimination error matrix from
%                                 subject data, plus an accuracy-vs-
%                                 eccentricity curve. Takes exp_settings and
%                                 subject_file as its two inputs.
%
% See also LIB, GROUPING, EXPERIMENT.
