function response = runTrial(SessionSettings, trialNumber)
%SINGLETRIALDETECTION Runs a single trialNumber of the detection experiment
%
% Example:
%   [response, responseOnsetMs] = SINGLETRIALDETECTION(experimentStruct, stimulus, levelNumber, trialNumber);
%
%   See also PRESENTFIXATIONCROSS, DRAWSTIMULUS.
%
% v1.0, 1/20/2016, R. C. Walshe <calen.walshe@utexas.edu>

experiment.discriminate.run.fixationInterval(SessionSettings);

experiment.discriminate.run.stimulusInterval(SessionSettings, trialNumber);

response = experiment.discriminate.run.responseInterval(SessionSettings);

experiment.discriminate.run.giveFeedback(SessionSettings, response, trialNumber);