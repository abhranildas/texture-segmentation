function response = runTrial(SessionSettings, trialNumber)
%SINGLETRIALDETECTION Runs a single trialNumber of the detection experiment
%
% Example:
%   [response, responseOnsetMs] = SINGLETRIALDETECTION(experimentStruct, stimulus, levelNumber, trialNumber);
%
%   See also PRESENTFIXATIONCROSS, DRAWSTIMULUS.
%
% v1.0, 1/20/2016, R. C. Walshe <calen.walshe@utexas.edu>

experiment.run.fixationInterval(SessionSettings);

experiment.run.stimulusInterval(SessionSettings, trialNumber);

response = experiment.run.responseInterval(SessionSettings);

experiment.run.giveFeedback(SessionSettings, response, trialNumber);