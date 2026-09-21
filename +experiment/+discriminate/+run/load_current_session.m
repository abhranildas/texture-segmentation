function settings_out = load_current_session(subject_str, exp_type_str, ...
    condition, session_number, level_number)
%LOAD_CURRENT_SESSION  Load the stimuli and settings for the next session.
%   settings_out = experiment.discriminate.run.load_current_session(subject_str, exp_type_str)
%   settings_out = experiment.discriminate.run.load_current_session(subject_str, ...
%       exp_type_str, condition, session_number, level_number)
%
%   With 2 arguments, auto-selects the lowest not-yet-completed
%   session/level from the subject's saved progress file. With 5
%   arguments, loads the given session/level/condition directly. Either
%   way, reads the shared exp_settings.mat for this exp_type_str and
%   slices out just this level's stimuli. Called only during the
%   experiment, from RUN_EXPERIMENT.
%
%   Inputs
%     subject_str     Subject identifier; names exp_files/<exp_type_str>/
%                      subject_out/<subject_str>.mat.
%     exp_type_str     Experiment type string; names exp_files/<exp_type_str>/.
%     condition        Bin condition row to match against subject_file.binIndex
%                       (only used when session_number/level_number are given).
%     session_number   1-based session index (only used with condition/level_number).
%     level_number      1-based level index within that session.
%
%   Output
%     settings_out  exp_settings, sliced to this level's stimuli, plus the
%                    resolved subjectStr/expTypeStr/currentLevel/currentBin/
%                    currentSession fields RUN_EXPERIMENT and its hooks read.
%
%   See also EXPERIMENT.DISCRIMINATE.RUN.RUN_EXPERIMENT,
%   EXPERIMENT.DISCRIMINATE.RUN.SAVE_CURRENT_LEVEL.
%
% v1.0, 1/26/2016, Steve Sebastian <sebastian@utexas.edu>

%% Determine current session

file_path_subject = ['exp_files/' exp_type_str '/subject_out/' subject_str '.mat'];
load(file_path_subject);
if (nargin < 4)
    n_levels = size(subject_file.idx, 2);

    % Check for experiment files that have not been completed
    % Check for not completed session
    [not_completed_session, not_completed_bin] = ...
        find(subject_file.levelCompleted < n_levels);

    if (isempty(not_completed_bin) && isempty(not_completed_session))
        error('Error: All bins, sessions, and levels have been completed');
    end

    % lower sessions first
    s_index = find(min(not_completed_session) == not_completed_session);

    current_bin = not_completed_bin(s_index(1));
    current_session = not_completed_session(s_index(1));

    % condition = SubjectExpFile.condition(currentBin, :);
    level_completed = subject_file.levelCompleted(current_session, current_bin);
    current_level = level_completed + 1;
else
    current_session = session_number;
    current_bin = find(ismember(subject_file.binIndex, condition, 'rows') == 1);
    current_level = level_number;
end

% disp(['Loading bin: L' num2str(SubjectExpFile.luminance) ' C' num2str(SubjectExpFile.contrast)]);
disp(['Session ' num2str(current_session) ', Level ' num2str(current_level)]);

%% Load settings

file_path_session = ['exp_files/' exp_type_str '/exp_settings.mat'];
load(file_path_session);

save(file_path_subject, 'subject_file');

settings_out = exp_settings;
settings_out.stimuli = exp_settings.stimuli(:, :, :, ...
    subject_file.idx(:, current_level, current_session));
settings_out.diffpair = cellfun(@(x) numel(x) == 2, ...
    exp_settings.tex(subject_file.idx(:, current_level, current_session)));
settings_out.bgPixVal = exp_settings.bgPixVal./255;
settings_out.bgPixValGamma = lib.gamma_correct(settings_out.bgPixVal, 2.089, 8);
settings_out.subjectStr = subject_str;
settings_out.expTypeStr = exp_type_str;
settings_out.currentLevel = current_level;
settings_out.currentBin = current_bin;
settings_out.currentSession = current_session;

end
