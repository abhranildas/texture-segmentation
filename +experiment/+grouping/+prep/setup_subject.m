function subject_file = setup_subject(exp_type, subject_name)
%SETUP_SUBJECT  Create a fresh subject progress/response file for the grouping experiment.
%   subject_file = experiment.grouping.prep.setup_subject(exp_type, subject_name)
%
%   Loads the shared exp_settings.mat this exp_type's SETUP_EXPERIMENT
%   saved, builds empty per-session/level response/correctness arrays, and
%   saves the result to exp_files/<exp_type>/subject_out/<subject_name>.mat
%   for the +run package to load and update trial by trial. Unlike the
%   discriminate tree's copy of this file, does not build a randomized
%   subject_file.idx (see the disabled block below, and B3.14).
%
%   Inputs
%     exp_type       Experiment variant string; names the exp_settings.mat
%                    and subject_out/ folder to use.
%     subject_name   Subject identifier; names the saved .mat file.
%
%   Output
%     subject_file   Struct with fields levelCompleted, response, correct
%                    (see Note) — also saved to disk.
%
%   Note: exp_settings/subject_file (the loaded/saved variable names) and
%   the field names inside subject_file are frozen cross-file/serialized
%   vocabulary shared with the +run package, and are left unrenamed even
%   though several are camelCase; only local variables were converted to
%   snake_case.
%
%   See also EXPERIMENT.GROUPING.PREP.SETUP_EXPERIMENT,
%   EXPERIMENT.GROUPING.RUN.LOAD_CURRENT_SESSION.

load(['exp_files/' exp_type '/exp_settings.mat'], 'exp_settings');

n_trials = exp_settings.nTrials; % number of trials per level
n_levels = exp_settings.nLevels; % number of eccentricity levels
n_sessions = exp_settings.nSessions; % number of sessions to divide this into.

% randomized stimulus indices
% idx = zeros(n_trials*n_sessions, n_levels, 'uint16');
% for i_session = 1:n_sessions
%     idx(:, i_session) = randperm(n_trials*n_sessions);
% end
% % split into sessions
% subject_file.idx = permute(reshape(idx', n_levels, [], n_sessions), [2 1 3]);

subject_file.levelCompleted = zeros(n_sessions, 1);
subject_file.response = false(n_trials, n_levels, n_sessions);
subject_file.correct = false(size(subject_file.response));

folder_out = ['exp_files/' exp_type '/subject_out'];
mkdir(folder_out);
save([folder_out '/' subject_name '.mat'], 'subject_file');

end
