function cfg = config()
% CONFIG  Central configuration for the texture-segmentation project.
%   cfg = config()
%
%   Returns a struct of data paths and shared physical/optical constants. Pass
%   it to code that needs a path or a parameter, instead of relying on a
%   hardcoded absolute path or on the ambient MATLAB path. Every path is built
%   from this file's own location, so the struct is correct from any working
%   directory.
%
%   EDIT cfg.paths.data_root below if the shared data store (vislab-common/data)
%   is not next to this repo.
%
%   Mirrors the config.m convention in the sibling texture-learning /
%   camouflage_detection repos, so the three projects share one layout.
%
%   Inputs
%     none.
%
%   Output
%     cfg - configuration struct, with fields:
%       paths.repo_root       - this repo's root folder (absolute).
%       paths.data_root       - shared lab data store, ../vislab-common/data.
%       paths.natural_images  - CPS natural images (16-bit linear .png sheets).
%       paths.textures        - texture sheets (brodatz/, fabric/, ...).
%       paths.exp_files       - per-experiment settings and subject output.
%       paths.data            - this repo's own data/ folder.
%       paths.stimuli         - derived patch sets, under data/ (textures/ only,
%                               as of 2026-09-21).
%       paths.model           - model and analysis artifacts, under data/
%                               (the fitted discrimination boundaries).
%       optics.ppd            - pixels per degree of visual angle.
%       optics.pupil_diameter - pupil diameter, in mm.
%       optics.wavelength     - wavelength, in nm.
%       color.rgb_to_lms      - 3x3 camera-RGB to human-LMS cone matrix,
%                               dimensionless; a row-vector RGB pixel times
%                               this matrix gives [L M S].
%       norm.target_mean      - target patch mean, in gray levels (0-255).
%       norm.target_contrast  - target RMS contrast, dimensionless fraction.
%       seed                  - RNG seed, for reproducible runs.
%
%   The optics triple is exactly what vislab.lib.otf_filter takes as its last
%   three arguments, and color.rgb_to_lms exactly what vislab.lib.rgb2lms takes
%   as its second; both are shared lab constants, not per-project choices.
%
%   Note: nothing in this repo reads cfg yet except tools/golden_harness.m --
%   the pipeline code still builds its own paths, mostly wrongly (Stage 3 item
%   S2.4 in docs/repo-cleanup.md routes them through here).
%
%   See also SETUP, vislab.lib.OTF_FILTER, vislab.lib.RGB2LMS.

    repo_root = fileparts(mfilename('fullpath'));

    % --- data locations ---
    cfg.paths.repo_root      = repo_root;
    cfg.paths.data_root      = fullfile(repo_root, '..', 'vislab-common', 'data');
    cfg.paths.natural_images = fullfile(cfg.paths.data_root, 'CPS natural images');
    cfg.paths.textures       = fullfile(cfg.paths.data_root, 'textures');
    cfg.paths.exp_files      = fullfile(repo_root, 'exp_files');
    cfg.paths.data           = fullfile(repo_root, 'data');
    cfg.paths.stimuli        = fullfile(cfg.paths.data, 'stimuli');
    cfg.paths.model          = fullfile(cfg.paths.data, 'model');

    % --- eye optics (Watson OTF); shared lab constants ---
    cfg.optics.ppd            = 60;
    cfg.optics.pupil_diameter = 4;
    cfg.optics.wavelength     = 550;

    % --- camera RGB -> human LMS cone matrix (same as sibling repos) ---
    cfg.color.rgb_to_lms = [ 4.370,  1.338,  0.118;
                             6.984,  8.373, -0.922;
                            -1.096, -0.667,  5.814];

    % --- luminance/contrast normalization ---
    cfg.norm.target_mean     = 128;
    cfg.norm.target_contrast = 0.25;

    % --- reproducibility ---
    cfg.seed = 0;
end
