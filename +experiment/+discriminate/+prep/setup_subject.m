function subject_file=setup_subject(exp_type,subject_name)
% Create all settings and output arrays for experiment subjects
load(['exp_files/' exp_type '/exp_settings.mat'],'exp_settings');

nTrials=exp_settings.nTrials; % number of trials per level
nLevels=exp_settings.nLevels; % number of eccentricity levels
nSessions=exp_settings.nSessions; % number of sessions to divide this into.

% randomized stimulus indices
idx=zeros(nTrials*nSessions,nLevels,'uint16');
for i=1:nSessions
    idx(:,i)=randperm(nTrials*nSessions);
end
% split into sessions
subject_file.idx=permute(reshape(idx',nLevels,[],nSessions), [2 1 3]);

subject_file.levelCompleted=zeros(nSessions, 1);
subject_file.response=zeros(nTrials, nLevels, nSessions,'int8');
subject_file.correct=false(size(subject_file.response));

folderOut= ['exp_files/' exp_type '/subject_out'];
mkdir(folderOut);
save([folderOut '/' subject_name '.mat'], 'subject_file');

end
