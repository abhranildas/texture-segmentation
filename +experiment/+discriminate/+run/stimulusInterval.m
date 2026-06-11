function stimulusOnsetMs = stimulusInterval(SessionSettings, trialNumber)
%DRAWSTIMULUS Draw the detection stimulus.
%
% Description:
%   The stimulus is presented at the x and y coordinates provided.
%
% Example:
%   stimulusOnsetMs = DRAWSTIMULUS(SessionSettings, x, y, stimulus);
% v1.0, 1/20/2016, R. C. Walshe <calen.walshe@utexas.edu>

%% Set up
stimulusIntervalS = SessionSettings.stimulusIntervalS;

stim1 = SessionSettings.stimuli(:,:,1,trialNumber);
stim2 = SessionSettings.stimuli(:,:,2,trialNumber);

stimulus1Texture = Screen('Maketexture', SessionSettings.window, stim1);
stimulus2Texture = Screen('Maketexture', SessionSettings.window, stim2);

stim1PosXY = SessionSettings.stim1PosPix;
stim2PosXY = SessionSettings.stim2PosPix;

stimulusRect         = SetRect(0, 0, size(stim1,2), size(stim1,1));
stimulus1Destination  = floor(CenterRectOnPointd(stimulusRect, stim1PosXY(1), stim1PosXY(2)));
stimulus2Destination  = floor(CenterRectOnPointd(stimulusRect, stim2PosXY(1), stim2PosXY(2)));

%% Display stimulus

Screen('DrawTexture', SessionSettings.window, stimulus1Texture, [], stimulus1Destination);
Screen('DrawTexture', SessionSettings.window, stimulus2Texture, [], stimulus2Destination);

[~, StimulusOnsetTime] = Screen('Flip', SessionSettings.window, 0, 1);

WaitSecs(stimulusIntervalS); % Stimulus is on for stimulusIntervalS seconds.

Screen('FillRect', SessionSettings.window, SessionSettings.bgPixValGamma, stimulus1Destination);
Screen('FillRect', SessionSettings.window, SessionSettings.bgPixValGamma, stimulus2Destination);

[~, StimulusOnsetTime] = Screen('Flip', SessionSettings.window, 0, 1);

stimulusOnsetMs = StimulusOnsetTime;
