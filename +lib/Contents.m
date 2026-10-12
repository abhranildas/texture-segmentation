% LIB  Stimulus, image-filtering and decision-variable helpers.
%
% Call these as lib.<name>(...) once setup.m has put the repo on the path.
%
% Stimuli and masks
%   texture_patch          - Sample a patch at a random location from a Brodatz texture.
%   target_mask            - Build a target region mask, its boundary, and its normals.
%   create_pink_noise_line - Generate a 1-D 1/f (pink) noise signal.
%
% Gradients and local statistics
%   steerable_filter       - Build a pair of first-derivative-of-Gaussian kernels.
%   steerable_grad         - Image gradient from a pair of steerable filters.
%   local_sd               - Local standard deviation of an image over a disk neighborhood.
%
% Decision variables
%   hist_dv                - Same/different decision variable from two gray-level histograms.
%   edge_props_stim        - Same/different evidence from a stimulus's edge statistics.
%   edge_dv                - Edge-contour decision variables for two patches. Broken - see B2.1.
%   re                     - Edge similarity decision variable from zero-crossing contours.
%   rs                     - Spatial pattern similarity decision variable (best-shift dot product).
%   rs_new                 - Spatial pattern similarity, subpatch-correlation variant of RS.
%   mk_contour             - Order a list of edge pixels into one connected contour walk.
%
% Display and image utilities
%   gamma_correct          - Gamma-compress an image and scale it to integer pixel values.
%   monitor_degrees_to_pixels - Convert a screen position from degrees to pixels.
%   compute_p_clipped      - Fraction of an image's pixels that fall outside [0, 1].
