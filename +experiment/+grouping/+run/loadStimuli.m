function SessionSettings = loadStimuli(exp_settings)
% Formats and loads stimuli for experiment 

%% Set up 

gammaValue = 2.059;

currentLevel = exp_settings.currentLevel;

currentSession = exp_settings.currentSession;

monitorSizePix = exp_settings.monitorSizePix;

stimuli = exp_settings.stimuli;
bgPixVal = exp_settings.bgPixVal; 
pixelsPerDeg = exp_settings.ppd; 

stimPosDeg = [0 0];
stimPosPix = lib.monitorDegreesToPixels(stimPosDeg, monitorSizePix, pixelsPerDeg);

fixPosDeg = [exp_settings.ecc(currentLevel) 0];
fixPosPix = lib.monitorDegreesToPixels(fixPosDeg, monitorSizePix, pixelsPerDeg);
  
responseIntervalS = exp_settings.responseIntervalMs/1000;
stimulusIntervalS = exp_settings.stimulusIntervalMs/1000;
fixationIntervalS = exp_settings.fixationIntervalMs/1000;
blankIntervalS    = exp_settings.blankIntervalMs/1000;

%% Create the fixation target

fixationSize = round(pixelsPerDeg.*0.1);
fixationPixelVal = 0.5*bgPixVal;
fixationTarget = fixationPixelVal.*ones(fixationSize, fixationSize);
fixationTarget = lib.gammaCorrect(fixationTarget, gammaValue, bitDepthOut);

%% Save

SessionSettings = struct('stimPosPix', stimPosPix,...
    'fixPosPix', fixPosPix,'bgPixValGamma', exp_settings.bgPixValGamma, ...
    'responseIntervalS', responseIntervalS, 'fixationIntervalS', fixationIntervalS, ...
    'stimulusIntervalS', stimulusIntervalS, 'blankIntervalS', blankIntervalS, ...
    'fixationTarget', fixationTarget, 'nTrials', exp_settings.nTrials, 'nLevels', exp_settings.nLevels, ...
    'pixelsPerDeg', pixelsPerDeg, ...
    'currentLevel', currentLevel, 'subjectStr', exp_settings.subjectStr, 'expTypeStr', exp_settings.expTypeStr, ...
    'currentSession', currentSession, ...
    'stimuli', stimuli,'diffpair',exp_settings.diffpair);