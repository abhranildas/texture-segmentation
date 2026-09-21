function setup()
% SETUP  Put texture-segmentation and its dependencies on the MATLAB path.
%   setup()
%
%   Run once per MATLAB session before using the code:
%       >> setup
%
%   Adds to the path:
%     * this repo (its +experiment, +general, +grouping, +lib packages and root
%       helper functions). +lib is self-contained: the functions that used to
%       live only in the lab-root +lib were copied in (edge_props_stim plus its
%       subtree target_mask / steerable_grad / steerable_filter /
%       create_pink_noise_line / local_sd), and lib.otf_filter was repointed to
%       vislab.lib.otf_filter -- so this repo no longer depends on the lab-root
%       +lib (mirrors camouflage_detection).
%     * vislab (the shared lab library) -- the folder holding the +vislab
%       package inside the sibling vislab-common repo (the lab's local dev
%       layout). Cloned automatically if it is missing and git and a network
%       are available.
%
%   Also VERIFIES/self-heals the required MATLAB add-on toolboxes (installed via
%   the Add-On Explorer / File Exchange -- NOT bundled or fetched as source):
%     * Integrate and Classify Normal Distributions  (classify_normals, quad2fun)
%         https://github.com/abhranildas/IntClassNorm
%     * Generalized chi-square distribution  (gx2*, used by the above)
%         https://github.com/abhranildas/gx2
%
%   Mirrors setup.m in the sibling texture-learning / camouflage_detection
%   repos.
%
%   Inputs
%     none.
%
%   Output
%     none. The MATLAB path is modified for the current session only; nothing
%     is saved, so setup must be re-run in every new session.
%
%   Note: what setup does NOT add is the shared data store itself. It only
%   checks that ../vislab-common/data exists and warns if it does not; the
%   folder is never put on the path, and addpath is not recursive, so the
%   vislab-common folder added below exposes the +vislab package but not
%   data/. Code that wants a data file must therefore build a real path (see
%   CONFIG), not a bare relative one. This is half of Stage 4 item B2.14 in
%   docs/repo-cleanup.md.
%
%   See also CONFIG.

    repo_root = fileparts(mfilename('fullpath'));

    % --- shared lab library (vislab): a sibling folder next to this repo.
    %     If not found, try to clone it automatically (needs git + network). ---
    vislab_dir = locate_folder(repo_root, '+vislab');
    if isempty(vislab_dir)
        vislab_dir = fetch_vislab(repo_root);
    end
    if isempty(vislab_dir)
        warning('texture_segmentation:setup:noCommons', ...
            ['vislab-common not found and could not be fetched automatically. ', ...
            'Clone it next to this repo:  git clone https://github.com/abhranildas/vislab-common']);
    else
        % exposes vislab.lib.*, vislab.nat_stat_bayes.*
        addpath(fileparts(vislab_dir));
    end

    % --- this repo (its own +lib is self-contained; no lab-root +lib needed) ---
    % exposes the experiment/general/grouping/lib packages + the root functions
    addpath(repo_root);

    % --- installed add-on toolboxes (self-heal headless path) ---
    ensure_addon_on_path('gx2cdf', 'Generalized chi-square distribution*', ...
        'Generalized chi-square distribution (gx2)', 'https://github.com/abhranildas/gx2');
    ensure_addon_on_path('classify_normals', ...
        'Integrate and Classify Normal Distributions*', ...
        'Integrate and Classify Normal Distributions', ...
        'https://github.com/abhranildas/IntClassNorm');

    % --- shared data store: vislab-common/data (~23 GB, obtained manually) ---
    if ~isfolder(fullfile(repo_root, '..', 'vislab-common', 'data'))
        warning('texture_segmentation:setup:noData', ...
            ['vislab-common/data not found next to this repo. It is the large (~23 GB) shared data store ', ...
            '(natural images + texture sheets); obtain it separately and place it in vislab-common/data ', ...
            '(see README). Code that reads it will fail until then.']);
    end
end

function folder = fetch_vislab(repo_root)
% Auto-fetch the shared library by cloning the vislab-common repo as a sibling
% (../vislab-common); the +vislab package lives inside it. Needs git on the PATH
% and network access; returns '' if the clone fails (caller then warns).
    folder = '';
    repo_dir = fullfile(repo_root, '..', 'vislab-common');
    url = 'https://github.com/abhranildas/vislab-common.git';
    fprintf('vislab-common not found; trying to clone it to %s ...\n', repo_dir);
    [status, git_output] = system(sprintf('git clone "%s" "%s"', url, repo_dir));
    package_dir = fullfile(repo_dir, '+vislab');
    if status == 0 && isfolder(fullfile(package_dir, '+lib'))
        folder = package_dir;
        fprintf('Cloned vislab-common.\n');
    else
        fprintf(2, 'Could not auto-fetch vislab-common (git missing or offline?).\n%s\n', ...
            git_output);
    end
end

function folder = locate_folder(repo_root, package_name)
% Find the +vislab package: inside the sibling vislab-common repo (canonical),
% else as a sibling of / inside this repo (older dev layouts).
    candidates = {fullfile(repo_root, '..', 'vislab-common', package_name), ...
        fullfile(repo_root, package_name), ...
        fullfile(repo_root, '..', package_name)};
    folder = '';
    % ii is a neutral name: the same old counter name i served two unrelated
    % roles in this file, and a Stage 1 rename map must be a bijection (C-6).
    for ii = 1:numel(candidates)
        if isfolder(candidates{ii})
            folder = candidates{ii};
            return;
        end
    end
end

function ensure_addon_on_path(probe_function, folder_pattern, toolbox_name, url)
% Ensure an INSTALLED add-on toolbox's functions are on the path.
%   If PROBE_FUNCTION already resolves, do nothing. Otherwise find the installed
%   add-on folder (matching FOLDER_PATTERN under the add-ons install directory)
%   and add it -- this uses the installed add-on, never any lab-local source.
%   Warn with install guidance only if it still cannot be found (not installed).
    if exist(probe_function, 'file') ~= 0
        return;
    end
    toolboxes_path = addons_toolboxes_dir();
    if ~isempty(toolboxes_path)
        hits = dir(fullfile(toolboxes_path, folder_pattern));
        for ii = 1:numel(hits)
            if hits(ii).isdir
                addpath(genpath(fullfile(toolboxes_path, hits(ii).name)));
            end
        end
    end
    if exist(probe_function, 'file') == 0
        warning('texture_segmentation:setup:missingToolbox', ...
            ['Required MATLAB toolbox "%s" not found (cannot find %s). Install it via the ', ...
            'MATLAB Add-On Explorer / File Exchange: %s'], toolbox_name, probe_function, url);
    end
end

function toolboxes_dir = addons_toolboxes_dir()
% Best-effort path to the "<...>/MATLAB Add-Ons/Toolboxes" install directory,
% without hardcoding a username. Try the add-ons install-folder setting first,
% then fall back to the parent folder of an already-resolvable add-on function.
    toolboxes_dir = '';
    try
        addons_root = settings().matlab.addons.InstallationFolder.ActiveValue;
        candidate = fullfile(addons_root, 'Toolboxes');
        if isfolder(candidate), toolboxes_dir = candidate; return; end
        if isfolder(addons_root), toolboxes_dir = addons_root; return; end
    catch
        % settings tree not available in this release -- use the fallback below
    end
    for probe_name = {'gx2cdf', 'gx2pdf', 'gx2inv'}
        probe_path = which(probe_name{1});
        if ~isempty(probe_path)
            toolboxes_dir = fileparts(fileparts(probe_path));
            return;
        end
    end
end
