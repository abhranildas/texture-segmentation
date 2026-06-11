function saveCurrentLevel(SessionSettings, response, levelNumber)
%LOADCURRENSESSIONS Saves the stimuli and experiment info for the next
%session. Called only during experiment.
%
% v1.0, 1/26/2016, Steve Sebastian <sebastian@utexas.edu>

%% Determine current session and update to completed

subjectStr    = SessionSettings.subjectStr;
expTypeStr    = SessionSettings.expTypeStr;

filePathSubject = ['exp_files/' expTypeStr '/subject_out/' subjectStr '.mat'];
load(filePathSubject);

sessionNumber = SessionSettings.currentSession;

subject_file.levelCompleted(sessionNumber)=subject_file.levelCompleted(sessionNumber)+1;

subject_file.diffpair(:,levelNumber,sessionNumber)=SessionSettings.diffpair;

%% Performance
subject_file.response(:,levelNumber,sessionNumber)=int8(response);
subject_file.correct(:,levelNumber,sessionNumber) = SessionSettings.diffpair == response;

disp(['Level ' num2str(levelNumber) ' complete: '...
    num2str(mean(SessionSettings.diffpair == response)*100) '% correct.']);

save(filePathSubject, 'subject_file');