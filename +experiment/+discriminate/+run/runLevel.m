function runLevel(SessionSettings)
% Runs a single level of an experiment.

nTrials = SessionSettings.nTrials;
currentLevel = SessionSettings.currentLevel;
responseVector = zeros(nTrials, 1);

experiment.discriminate.run.displayLevelStart(SessionSettings);

for iTrial = 1:nTrials    
    response = experiment.discriminate.run.runTrial(SessionSettings, iTrial);    
    responseVector(iTrial) = response;
end

pCorrect=mean(SessionSettings.diffpair == responseVector)*100;

experiment.discriminate.run.saveCurrentLevel(SessionSettings, responseVector, currentLevel);

Screen('FillRect', SessionSettings.window, SessionSettings.bgPixValGamma)
Screen('TextSize', SessionSettings.window, 25);
DrawFormattedText(SessionSettings.window, sprintf('End of level: %d%% correct.',round(pCorrect)),'center', 'center');
Screen('Flip', SessionSettings.window);
WaitSecs(1);