function SettingsOut = loadCurrentSession(subjectStr, expTypeStr, condition, sessionNumber, levelNumber)
%LOADCURRENTSESSION Load the stimuli and experiment info for the next
%session. Called only during experiment.
%
% v1.0, 1/26/2016, Steve Sebastian <sebastian@utexas.edu>

%% Determine current session

filePathSubject = ['exp_files/' expTypeStr '/subject_out/' subjectStr '.mat'];
load(filePathSubject);
if(nargin < 4)
    nLevels = size(subject_file.response,2);        

    % Check for experiment files that have not been completed
    % Check for not completed session
    [notCompletedSession, notCompletedBin] = ...
        find(subject_file.levelCompleted < nLevels);

    if(isempty(notCompletedBin) && isempty(notCompletedSession))
        error('Error: All bins, sessions, and levels have been completed');
    end

    % lower sessions first
    sIndex = find(min(notCompletedSession)==notCompletedSession);
    
    currentBin     = notCompletedBin(sIndex(1));
    currentSession = notCompletedSession(sIndex(1));
    
    %condition = SubjectExpFile.condition(currentBin, :);
    levelCompleted = subject_file.levelCompleted(currentSession, currentBin);
    currentLevel = levelCompleted + 1;
else
    currentSession = sessionNumber; 
    currentBin = find(ismember(subject_file.binIndex, condition, 'rows') == 1);
    currentLevel = levelNumber;
end


% disp(['Loading bin: L' num2str(SubjectExpFile.luminance) ' C' num2str(SubjectExpFile.contrast)]);
disp(['Session ' num2str(currentSession) ', Level ' num2str(currentLevel)]);

%% Load settings

filePathSession = ['exp_files/' expTypeStr '/exp_settings.mat'];
load(filePathSession);

save(filePathSubject, 'subject_file');

SettingsOut=exp_settings;
% SettingsOut.stimuli=exp_settings.stimuli(:,:,:,subject_file.idx(:,currentLevel,currentSession));
% SettingsOut.diffpair=cellfun(@(x) numel(x)==2,exp_settings.tex(subject_file.idx(:,currentLevel,currentSession)));
SettingsOut.bgPixVal = exp_settings.bgPixVal./255;
SettingsOut.bgPixValGamma = lib.gammaCorrect(SettingsOut.bgPixVal, 2.089, 8);
SettingsOut.subjectStr = subjectStr;
SettingsOut.expTypeStr = expTypeStr;
SettingsOut.currentLevel = currentLevel;
SettingsOut.currentBin = currentBin;
SettingsOut.currentSession = currentSession;

