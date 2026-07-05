function cfg = config()
% CONFIG  Central configuration for the texture-segmentation project.
%   cfg = config()  returns a struct of data paths and shared physical/optical
%   constants. Pass it to code that needs paths or parameters instead of relying
%   on hardcoded absolute paths or the ambient MATLAB path.
%
%   EDIT cfg.paths.data_root below if the shared vislab_data store is not a
%   sibling of this repo.
%
%   (Mirrors the config.m convention in the sibling texture-learning /
%   camouflage_detection repos so the three projects share one layout.)

    repo_root = fileparts(mfilename('fullpath'));

    % --- data locations ---
    cfg.paths.repo_root      = repo_root;
    cfg.paths.data_root      = fullfile(repo_root, '..', 'vislab_data');   % shared lab data store
    cfg.paths.natural_images = fullfile(cfg.paths.data_root, 'CPS natural images');
    cfg.paths.textures       = fullfile(cfg.paths.data_root, 'textures');  % brodatz/, fabric/, ...
    cfg.paths.exp_files      = fullfile(repo_root, 'exp_files');           % per-experiment settings + subject output
    cfg.paths.data           = fullfile(repo_root, 'data');               % analysis artifacts (boundaries, etc.)
    cfg.paths.img_data       = fullfile(repo_root, 'img_data');           % derived patch sets (train/test, near/far)

    % --- eye optics (Watson OTF); shared lab constants ---
    cfg.optics.ppd            = 60;      % pixels per degree
    cfg.optics.pupil_diameter = 4;       % mm
    cfg.optics.wavelength     = 550;     % nm

    % --- camera RGB -> human LMS cone matrix (same as sibling repos) ---
    cfg.color.rgb_to_lms = [ 4.370, 1.338,  0.118;
                             6.984, 8.373, -0.922;
                            -1.096,-0.667,  5.814];

    % --- luminance/contrast normalization ---
    cfg.norm.target_mean     = 128;
    cfg.norm.target_contrast = 0.25;

    % --- reproducibility ---
    cfg.seed = 0;
end
