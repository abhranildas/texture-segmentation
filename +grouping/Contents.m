% GROUPING  Texture-segmentation-by-grouping stimulus generation.
%
% Call these as grouping.<name>(...) once setup.m has put the repo on the path.
%
% Geometry and bin helpers
%   mk_dist            - Distance between every ordered pair of patches on the patch grid.
%   mk_mecc            - Smaller of the two eccentricities of every patch pair on the grid.
%   mk_decc            - Eccentricity difference of every patch pair on the patch grid.
%   mk_bindex          - Number the geometry bins formed by three sets of bin bounds.
%   mk_pair_geometry   - Build the patch-pair geometry matrices and the bin index.
%   find_bin           - Geometry bin of one pair of patch locations on the patch grid.
%
% Region growing and patch tests
%   mk_masks           - Grow random texture-region maps and masks for a whole session.
%   mk_texs            - Assign a texture to every region of every trial in a session.
%   check_tlst         - Test whether the patch on one side of a given patch is unfilled.
%   check_xy           - Test whether a patch lies on a texture-region boundary.
%   find_xy            - Draw a random patch location that is not on a region boundary.
%   shape_cue          - Crop one texture region's outline into a small cue thumbnail.
%
% Session and trial stimulus scripts
%   mk_texseg_session       - Build and return all trial information for one session.
%   mk_trl_points           - Build the cue, stimulus and feedback images for one trial.
%   demo_mk_trl_points      - Demonstrate one call to GROUPING.MK_TRL_POINTS. Broken - see B2.5.
%   mk_texseg_stim_points   - Build and display a full session of point-cue stimuli.
%                             Broken - see B2.6/B2.7.
%   mk_texseg_stim_shape    - Build and display a session of shape-cue stimuli. Broken - see B2.6.
%   tex_regions             - Build and display one texture-region-grouping stimulus.
%                             Broken - see B2.6.
%   s_gtr_img               - Segment a GTR (grouping) stimulus image into patch pairs.
%                             Never assigns its output - see B3.11.
%
% Unfinished, callerless (see docs/repo-cleanup.md S3.3)
%   find_tex_regions    - Enumerate the patch grid and every unordered patch pair.
