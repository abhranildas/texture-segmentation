function displayLevelStart(SessionSettings)
%% presenttargetonly
%   Used for the beginning of blocks. Presents that target, with text, at
%   the beginning of the block.


% Display the fixation and stimulus position from a random trial in the
% block

fixPosPixXY = SessionSettings.fixPosPix;
stim1PosPixXY = SessionSettings.stim1PosPix;
stim2PosPixXY = SessionSettings.stim2PosPix;

w = SessionSettings.window;

%% Set up 
fixTarget = SessionSettings.fixationTarget; 
fixTexture  = Screen('Maketexture', SessionSettings.window, fixTarget);
fixRect         = SetRect(0, 0, size(fixTarget,2), size(fixTarget,1));
fixDestination  = floor(CenterRectOnPointd(fixRect, fixPosPixXY(1), fixPosPixXY(2)));  

%% Draw fixTarget followed by blank if foveal experiment

Screen('TextSize', w, 25);
DrawFormattedText(w, sprintf('Session %d Level %d\n\n Press any key to start.',SessionSettings.currentSession,SessionSettings.currentLevel), ...
    'center',SessionSettings.pixelsPerDeg);

target = SessionSettings.targetOutline;
targetTexture = Screen('MakeTexture', SessionSettings.window, target);

targetRect         = SetRect(0, 0, size(target,2), size(target,1));
target1Destination  = floor(CenterRectOnPointd(targetRect, stim1PosPixXY(1), stim1PosPixXY(2))); 
target2Destination  = floor(CenterRectOnPointd(targetRect, stim2PosPixXY(1), stim2PosPixXY(2))); 
 


% if SessionSettings.bFovea % If foveal experiment, then draw stimulus after fixation cross.
%     Screen('DrawTexture', SessionSettings.window, fixTexture, [], fixDestination);
%     Screen('DrawTexture', SessionSettings.window, targetTexture, [], targetDestination);
% else
    Screen('DrawTexture', SessionSettings.window, targetTexture, [], target1Destination);    
    Screen('DrawTexture', SessionSettings.window, targetTexture, [], target2Destination);    
    Screen('DrawTexture', SessionSettings.window, fixTexture, [], fixDestination);
% end
Screen('Flip',SessionSettings.window);
   
%WaitSecs(10); %Adapt to background luminance

KbWait();

WaitSecs(1);

