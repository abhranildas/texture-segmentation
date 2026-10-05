function save_current_level(session_settings, response, level_number)
%SAVE_CURRENT_LEVEL  Save one level's responses into the subject's progress file.
%   experiment.run.save_current_level(session_settings, response, level_number)
%
%   Loads the subject's progress file, marks this session's levelCompleted
%   counter one higher, records the per-trial diffpair/response/correct
%   columns for this level, prints the level's percent correct, and saves
%   the file back. Called once per level, from either experiment's
%   RUN_EXPERIMENT save_level hook.
%
%   Shared by both experiment trees (S1.1): their two copies were the same
%   code. The grouping tree's loaders never set diffpair, so a live call
%   from that tree errors at its first read (B2.9).
%
%   Inputs
%     session_settings  Struct from LOAD_STIMULI. Fields read: subjectStr,
%                        expTypeStr, currentSession, diffpair.
%     response            Per-trial response vector for this level.
%     level_number         1-based level index within the current session.
%
%   See also EXPERIMENT.DISCRIMINATE.RUN.LOAD_CURRENT_SESSION,
%   EXPERIMENT.GROUPING.RUN.LOAD_CURRENT_SESSION, EXPERIMENT.RUN.GIVE_FEEDBACK.
%
% v1.0, 1/26/2016, Steve Sebastian <sebastian@utexas.edu>

%% Determine current session and update to completed

subject_str = session_settings.subjectStr;
exp_type_str = session_settings.expTypeStr;

file_path_subject = ['exp_files/' exp_type_str '/subject_out/' subject_str '.mat'];
load(file_path_subject);

session_number = session_settings.currentSession;

subject_file.levelCompleted(session_number) = subject_file.levelCompleted(session_number) + 1;

subject_file.diffpair(:, level_number, session_number) = session_settings.diffpair;

%% Performance
subject_file.response(:, level_number, session_number) = int8(response);
subject_file.correct(:, level_number, session_number) = session_settings.diffpair == response;

disp(['Level ' num2str(level_number) ' complete: ' ...
    num2str(mean(session_settings.diffpair == response)*100) '% correct.']);

save(file_path_subject, 'subject_file');

end
