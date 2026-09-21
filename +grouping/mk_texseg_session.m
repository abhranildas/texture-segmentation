function session = mk_texseg_session(tex_set, n_tex)
% MK_TEXSEG_SESSION  Build and return all trial information for one session.
%   session = grouping.mk_texseg_session(tex_set, n_tex)
%
%   Run once before a session, to fix its trial order, texture assignments,
%   region maps and cue locations; GROUPING.MK_TRL_POINTS then builds each
%   trial's stimulus on the fly during the session itself. Every patch pair on
%   the grid is classified into a geometry bin (separation, smaller
%   eccentricity, eccentricity difference), and each "different" trial is
%   immediately followed by a "same" trial redrawn from the same bin, so the
%   two conditions are matched for geometry pair by pair.
%
%   Inputs
%     tex_set - which texture database this session draws from: 'brodatz',
%               'fabric', or 'pertex'. Stored in the output but not otherwise
%               used here.
%     n_tex   - number of texture sheets to choose from.
%
%   Output
%     session - struct with fields (frozen names - consumed positionally by
%               GROUPING.MK_TRL_POINTS and by
%               EXPERIMENT.GROUPING.PREP.SETUP_EXPERIMENT, so none of these
%               field names may be renamed in Stage 1; see this tranche's
%               findings-log note):
%       cntrst  - n_trials by 1 array of per-trial contrast values.
%       cuelocs - n_trials by 5 array; column 1 is the same/different
%                 condition, columns 2-3 and 4-5 are the two cued patches'
%                 (x, y) locations.
%       m0      - target mean luminance, shared by every trial.
%       maps    - grid_size by grid_size by n_trials array of texture-region
%                 labels, from GROUPING.MK_MASKS.
%       pw      - patch width, in pixels.
%       sz      - side length of the square patch grid, as an integer count
%                 of patches (not pixels).
%       texs    - n_trials by n_tex_regions array of texture numbers, from
%                 GROUPING.MK_TEXS.
%       tex_set - copy of the tex_set input.
%       tperm   - randperm(n_trials), the session's trial presentation order.
%
%   See also GROUPING.MK_TRL_POINTS, GROUPING.MK_TEXS, GROUPING.MK_MASKS,
%   GROUPING.MK_DIST, GROUPING.MK_MECC, GROUPING.MK_DECC, GROUPING.MK_BINDEX,
%   GROUPING.FIND_BIN, GROUPING.FIND_XY, GROUPING.CHECK_XY.

    seed = 0;
    rng(seed);
    block_size = 24;      % trials per contrast block
    n_blocks = 20;        % number of contrast blocks
    n_trials = block_size*n_blocks;
    n_contrasts = 5;
    contrast_values = [0.1, 0.075, 0.05, 0.03, 0.02];
    mean_lum = 128;
    contrast = zeros(n_trials, 1);
    contrast_block_size = n_contrasts*block_size;
    n_tex_regions = 5;     % number of texture regions
    grid_size = 16;        % image size in patches
    patch_width = 64;      % patch width in pixels
    seed_radius_frac = 1.0;  % texture seed radius as fraction of max
    fill_fraction = 1.0;     % proportion of patches taken up by texture regions
    bin_bounds_dist = [1, 2, 4, 8, 16, 32];       % distance bin bounds
    bin_bounds_min_ecc = [0, 1, 2, 4, 8, 12];     % minimum eccentricity bin bounds
    bin_bounds_delta_ecc = [0, 2, 4, 6, 8, 12];   % eccentricity difference bin bounds
    n_bins = (size(bin_bounds_dist,2)-1)*(size(bin_bounds_min_ecc,2)-1)* ...
        (size(bin_bounds_delta_ecc,2)-1);
    bin_table = zeros(2*grid_size^4, n_bins);
    max_attempts = 100;

    % generate random texture numbers for all trials in a session
    tex_nums = grouping.mk_texs(n_tex, n_tex_regions, n_trials);

    % generate masks and maps for all trials in a session
    [~, maps] = grouping.mk_masks(grid_size, n_tex_regions, n_trials, ...
        seed_radius_frac, fill_fraction);

    % make geometry matrices for patch pairs, size of each = grid_size^2 x grid_size^2
    dist = grouping.mk_dist(grid_size);
    min_ecc = grouping.mk_mecc(grid_size);
    delta_ecc = grouping.mk_decc(grid_size);

    % make array of index values to patch geometry bins
    bin_index = grouping.mk_bindex(bin_bounds_dist, bin_bounds_min_ecc, bin_bounds_delta_ecc);

    % load the bin table counts and the specific pairs of patches in each bin
    for patch_index1 = 1:grid_size^2
        for patch_index2 = 1:grid_size^2
            if patch_index1 ~= patch_index2
                bin = grouping.find_bin(patch_index1, patch_index2, dist, min_ecc, ...
                    delta_ecc, bin_bounds_dist, bin_bounds_min_ecc, bin_bounds_delta_ecc, ...
                    bin_index);
                bin_table(1, bin) = bin_table(1, bin) + 1;
                bin_row = 2*bin_table(1, bin);
                bin_table(bin_row, bin) = patch_index1;
                bin_table(bin_row+1, bin) = patch_index2;
            end
        end
    end

    cue_locations = zeros(n_trials, 5);  % locations of texture-region cues

    trial = 1;
    max_count = 0;
    while trial <= n_trials
        % randomly sample condition "same" or "different"
        condition = 0;  % same
        if rand() > 0.5
            condition = 1;  % different
        end

        % randomly sample a patch location and determine its region number
        [x1, y1] = grouping.find_xy(trial, maps, grid_size);
        region1 = maps(x1, y1, trial);

        % random sample a second patch location and determine its region
        done = 0;
        while done == 0
            [x2, y2] = grouping.find_xy(trial, maps, grid_size);
            region2 = maps(x2, y2, trial);
            if (region1 == region2) && (condition == 0)
                done = 1;
            elseif (region1 ~= region2) && (condition == 1)
                done = 1;
            end
            if x1 == x2 && y1 == y2
                done = 0;
            end
        end
        cue_locations(trial, 1) = condition;
        cue_locations(trial, 2) = x1;
        cue_locations(trial, 3) = y1;
        cue_locations(trial, 4) = x2;
        cue_locations(trial, 5) = y2;

        % switch conditions and repeat for same bin
        if condition == 1
            condition = 0;
        else
            condition = 1;
        end
        lookup_index1 = (x1-1)*grid_size + y1;
        lookup_index2 = (x2-1)*grid_size + y2;
        bin = grouping.find_bin(lookup_index1, lookup_index2, dist, min_ecc, ...
            delta_ecc, bin_bounds_dist, bin_bounds_min_ecc, bin_bounds_delta_ecc, bin_index);
        n_pairs = bin_table(1, bin);
        done = 0;
        attempt_count = 0;
        while done == 0 && attempt_count < max_attempts
            attempt_count = attempt_count + 1;
            pair_index = randi(n_pairs);
            patch_index1 = bin_table(2*pair_index, bin);
            patch_index2 = bin_table(2*pair_index+1, bin);
            y1 = mod(patch_index1, grid_size);
            if y1 == 0
                y1 = grid_size;
            end
            x1 = 1 + (patch_index1-y1)/grid_size;
            y2 = mod(patch_index2, grid_size);
            if y2 == 0
                y2 = grid_size;
            end
            x2 = 1 + (patch_index2-y2)/grid_size;
            is_boundary1 = grouping.check_xy(x1, y1, trial+1, maps, grid_size);
            is_boundary2 = grouping.check_xy(x2, y2, trial+1, maps, grid_size);
            if (is_boundary1 == 0) && (is_boundary2 == 0)
                region1 = maps(x1, y1, trial+1);
                region2 = maps(x2, y2, trial+1);
                if (region1 == region2) && (condition == 0)
                    done = 1;
                elseif (region1 ~= region2) && (condition == 1)
                    done = 1;
                end
            end
        end
        if attempt_count < max_attempts
            cue_locations(trial+1, 1) = condition;
            cue_locations(trial+1, 2) = x1;
            cue_locations(trial+1, 3) = y1;
            cue_locations(trial+1, 4) = x2;
            cue_locations(trial+1, 5) = y2;
            trial = trial+2;
        else
            max_count = max_count+1;
        end
    end

    % make contrasts for the trials
    image_width = patch_width*grid_size;
    n_pixels = image_width*image_width;
    trial_order = randperm(n_trials);
    trial = 0;
    for i_group = 1:contrast_block_size:n_trials  % all contrast blocks
        i_contrast = 0;
        for i_subblock = i_group:block_size:i_group+contrast_block_size-1  % contrast block
            i_contrast = i_contrast + 1;
            for i_trial_in_block = i_subblock:i_subblock+block_size-1  % trials in sub-block
                trial = trial + 1;
                contrast(trial) = contrast_values(i_contrast);
            end
        end
    end

    % num = num2str(session);
    session = struct;
    session.cntrst = contrast;
    session.cuelocs = cue_locations;
    session.m0 = mean_lum;
    session.maps = maps;
    session.pw = patch_width;
    session.sz = grid_size;
    session.texs = tex_nums;
    session.tex_set = tex_set;
    session.tperm = trial_order;

    % nameout = append('session',num,'.mat');
    % save(nameout,'texset','m0','sz','pw','tperm','cntrst','cuelocs',...
    %     'texs','maps','-mat');

end
