function runExperiment(exp_type, subject_name, condition, sessionNumber, levelNumber)
%STARTEXPERIMENT Launch the detection experiment.
%
% Example: 
%   blockData = STARTEXPERIMENT(ExpSettings, blockNumber);
%   
%   See also RUNEXPERIMENTBLOCK
%
% v2.0, 1/27/2016, Steve Sebastian, R. C. Walshe <calen.walshe@utexas.edu>

%% Load in the settings
if(nargin < 4)
    exp_settings = experiment.discriminate.run.loadCurrentSession(subject_name, exp_type);
else
    exp_settings = experiment.discriminate.run.loadCurrentSession(subject_name, exp_type, condition, sessionNumber, levelNumber);
end


% Clear the workspace
close all;
sca;

% Setup PTB with some default values
PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 1); % skip sync tests

% Seed the random number generator
rng('shuffle');

% Set the screen number to the external secondary monitor if there is one
% connected
screenNumber = 1; %max(Screen('Screens'));

% Open the screen
[window, windowRect] = Screen('OpenWindow', screenNumber, exp_settings.bgPixValGamma);
LoadIdentityClut(window);

exp_settings.monitorSizePix = windowRect(3:4);

SessionSettings = exp_settings.loadSessionStimuli(exp_settings);
SessionSettings.window = window;

% Set the text size
Screen('TextSize', window, 60);

% Set the blend function for the screen
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

experiment.discriminate.run.runLevel(SessionSettings);