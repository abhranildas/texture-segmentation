function giveFeedback(SessionSettings, response, trialNumber)

%% Sound parameters
correctFreqHz   = 900;                      
incorrectFreqHz = 300;                    
errorFreqHz     = 1500;                      

% Feedback
if(response == -1)
    Beeper(errorFreqHz);
    %sound(errorTone, sampleFreqHz);
elseif(SessionSettings.diffpair(trialNumber) == response)
    Beeper(correctFreqHz);
    %sound(correctTone, sampleFreqHz);
else
    Beeper(incorrectFreqHz);
    %sound(incorrectTone, sampleFreqHz);
end