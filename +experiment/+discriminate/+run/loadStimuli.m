function SessionSettings = loadStimuli(exp_settings)
% Formats and loads stimuli for a session of the experiment 

%% Set up 

gammaValue = 2.059;

currentLevel = exp_settings.currentLevel;

currentSession = exp_settings.currentSession;

monitorSizePix = exp_settings.monitorSizePix;

stimuli = exp_settings.stimuli;
bgPixVal = exp_settings.bgPixVal; 
pixelsPerDeg = exp_settings.ppd; 

stim1PosDeg = [0 .75];
stim2PosDeg = [0 -.75];
stim1PosPix = lib.monitorDegreesToPixels(stim1PosDeg, monitorSizePix, pixelsPerDeg);
stim2PosPix = lib.monitorDegreesToPixels(stim2PosDeg, monitorSizePix, pixelsPerDeg);

if strcmpi(exp_settings.exp_type,'joined')
    % put the two texture patches adjacent to each other
    stim1PosPix(2)=monitorSizePix(2)/2-exp_settings.stim_size/2;
    stim2PosPix(2)=monitorSizePix(2)/2+exp_settings.stim_size/2;
end

fixPosDeg = [exp_settings.ecc(currentLevel) 0];
fixPosPix = lib.monitorDegreesToPixels(fixPosDeg, monitorSizePix, pixelsPerDeg);
  
responseIntervalS = exp_settings.responseIntervalMs/1000;
stimulusIntervalS = exp_settings.stimulusIntervalMs/1000;
fixationIntervalS = exp_settings.fixationIntervalMs/1000;
blankIntervalS    = exp_settings.blankIntervalMs/1000;

%% Gamma correct stimuli
% and change to 8-bits

bitDepthOut = 8;

for iTrial = 1:size(stimuli,4)
    for iPair=[1 2]
        stim = stimuli(:,:,iPair,iTrial);
        
        % clip:
        stim(stim>1)=1;
        stim(stim<0)=0;
        
        stim=lib.gammaCorrect(stim, gammaValue, bitDepthOut);        
        stimuli(:,:,iPair,iTrial) = stim;
    end
end

%% Create target examples

% target outline
target_outline=zeros(exp_settings.stim_size);
target_outline(:,[1 end])=1;
target_outline([1 end],:)=1;
target_outline=double(~target_outline);
target_outline(target_outline==1)=exp_settings.luminance;
targetOutline=lib.gammaCorrect(target_outline,gammaValue,bitDepthOut);

%% Create the fixation target

fixationSize = round(pixelsPerDeg.*0.1);
fixationPixelVal = 0.7*bgPixVal;
fixationTarget = fixationPixelVal.*ones(fixationSize, fixationSize);
fixationTarget = lib.gammaCorrect(fixationTarget, gammaValue, bitDepthOut);

%% Save

SessionSettings = struct('stim1PosPix', stim1PosPix, 'stim2PosPix', stim2PosPix,...
    'fixPosPix', fixPosPix,'bgPixValGamma', exp_settings.bgPixValGamma, 'targetOutline', targetOutline, ...
    'responseIntervalS', responseIntervalS, 'fixationIntervalS', fixationIntervalS, ...
    'stimulusIntervalS', stimulusIntervalS, 'blankIntervalS', blankIntervalS, ...
    'fixationTarget', fixationTarget, 'nTrials', exp_settings.nTrials, 'nLevels', exp_settings.nLevels, ...
    'pixelsPerDeg', pixelsPerDeg, ...
    'currentLevel', currentLevel, 'subjectStr', exp_settings.subjectStr, 'expTypeStr', exp_settings.expTypeStr, ...
    'currentSession', currentSession, ...
    'stimuli', stimuli,'diffpair',exp_settings.diffpair);