%% train_cnn.m
% Train the twin (Siamese) CNN on pairs of texture patches.
%   dataset = 'brodatz' : patches loaded from Brodatz image folders
%   dataset = 'nat'     : natural-image near/far pairs from the .mat produced
%                         by general.nat_near_far_patches_cnn
% Validation always uses held-out Brodatz test patches (cross-domain for 'nat').
% Run from the repo root with cnn/ on the MATLAB path.

dataset = 'nat';    % 'brodatz' or 'nat'
down_level = 1;     % resolution scale-down (1,2,4,8); for 'nat' this MUST match
                    % the level used when generating the patch pairs

%% Load the training data
if strcmpi(dataset,'brodatz')
    imdsTrain = imageDatastore('img_data/brodatz/patches/train', ...
        IncludeSubfolders=true,LabelSource='foldernames');
elseif strcmpi(dataset,'nat')
    if down_level>1
        ppfile = ['img_data/nat/patch_pairs_dsmpl_' num2str(down_level) '.mat'];
    else
        ppfile = 'img_data/nat/patch_pairs.mat';
    end
    load(ppfile,'near','far'); % [64 64 2 N] uint8; all pairs used for training
end

% validation always uses Brodatz test patches
imdsTest = imageDatastore('img_data/brodatz/patches/test', ...
    IncludeSubfolders=true,LabelSource='foldernames');

%% Define Network Architecture
% shared subnetwork
layers = [
    imageInputLayer([64 64 1],Normalization=@(img) img/mean(img(:))) % 64x64
    convolution2dLayer(5,64,WeightsInitializer="narrow-normal",BiasInitializer="narrow-normal") % 60x60 x64
    reluLayer
    maxPooling2dLayer(2,Stride=2) % 30x30
    convolution2dLayer(5,128,WeightsInitializer="narrow-normal",BiasInitializer="narrow-normal") % 26x26 x128
    reluLayer
    maxPooling2dLayer(2,Stride=2) % 13x13
    convolution2dLayer(4,128,WeightsInitializer="narrow-normal",BiasInitializer="narrow-normal") % 10x10 x128
    reluLayer
    maxPooling2dLayer(2,Stride=2) % 5x5
    convolution2dLayer(2,256,WeightsInitializer="narrow-normal",BiasInitializer="narrow-normal") % 4x4 x256
    reluLayer
    fullyConnectedLayer(4096,WeightsInitializer="narrow-normal",BiasInitializer="narrow-normal")]; % 4096

net = dlnetwork(layers);

% merge with fully connected layer
fcWeights = dlarray(0.01*randn(1,4096));
fcBias = dlarray(0.01*randn(1,1));
fcParams = struct("FcWeights",fcWeights,"FcBias",fcBias);

%% train network
numIterations = 1e3;
miniBatchSize = 1024;
learningRate = 6e-5;
gradDecay = 0.9;
gradDecaySq = 0.99;
executionEnvironment = "auto";
gpu = gpuDevice([]);
trailingAvgSubnet = [];
trailingAvgSqSubnet = [];
trailingAvgParams = [];
trailingAvgSqParams = [];
monitor = trainingProgressMonitor(Metrics=["TrainingLoss","ValidationLoss","TrainingAccuracy","ValidationAccuracy"],XLabel="Iteration");
groupSubPlot(monitor,"Loss",["TrainingLoss","ValidationLoss"]);
groupSubPlot(monitor,"Accuracy",["TrainingAccuracy","ValidationAccuracy"]);
start = tic;
iteration = 0;

% Loop over mini-batches.
while iteration < numIterations && ~monitor.Stop
    iteration = iteration + 1;

    % Extract mini-batch of training image pairs and pair labels
    if strcmpi(dataset,'brodatz')
        [X1,X2,pairLabels] = getTwinBatch(imdsTrain,miniBatchSize,'down_level',down_level);
    elseif strcmpi(dataset,'nat')
        [X1,X2,pairLabels] = getTwinBatch_nat(near,far,miniBatchSize);
    end

    % move to GPU
    X1 = dlarray(gpuArray(X1),"SSCB");
    X2 = dlarray(gpuArray(X2),"SSCB");
    pairLabels = gpuArray(pairLabels);

    % Evaluate the model loss on training images
    [training_loss,gradientsSubnet,gradientsParams] = dlfeval(@modelLoss,net,fcParams,X1,X2,pairLabels);

    % Update the twin subnetwork parameters.
    [net,trailingAvgSubnet,trailingAvgSqSubnet] = adamupdate(net,gradientsSubnet, ...
        trailingAvgSubnet,trailingAvgSqSubnet,iteration,learningRate,gradDecay,gradDecaySq);

    % Update the fullyconnect parameters.
    [fcParams,trailingAvgParams,trailingAvgSqParams] = adamupdate(fcParams,gradientsParams, ...
        trailingAvgParams,trailingAvgSqParams,iteration,learningRate,gradDecay,gradDecaySq);

    % Evaluate predictions using trained network
    Y = predictTwin(net,fcParams,X1,X2);

    % OPTIMIZATION: compute accuracy on the GPU, only gather the final scalar
    Y = round(extractdata(Y));
    training_acc = gather(sum(Y == pairLabels)/miniBatchSize);

    % Extract mini-batch of validation image pairs (always Brodatz test)
    [X1,X2,pairLabels] = getTwinBatch(imdsTest,miniBatchSize,'down_level',down_level);

    % move to GPU
    X1 = dlarray(gpuArray(X1),"SSCB");
    X2 = dlarray(gpuArray(X2),"SSCB");
    pairLabels = gpuArray(pairLabels);

    % Evaluate the model loss on validation images
    validation_loss = dlfeval(@modelLoss,net,fcParams,X1,X2,pairLabels);

    % Evaluate predictions using trained network
    Y = predictTwin(net,fcParams,X1,X2);
    Y = round(extractdata(Y));
    validation_acc = gather(sum(Y == pairLabels)/miniBatchSize);

    % Update the training progress monitor.
    recordMetrics(monitor,iteration,TrainingLoss=gather(training_loss),ValidationLoss=gather(validation_loss),TrainingAccuracy=training_acc,ValidationAccuracy=validation_acc);
    monitor.Progress = 100 * iteration/numIterations;
end

%% save the trained network
if down_level>1
    netfile = ['net_on_' dataset '_dsmpl_' num2str(down_level) '.mat'];
else
    netfile = ['net_on_' dataset '.mat'];
end
save(netfile,'net','fcParams')

%% Test accuracy over five random mini-batches of Brodatz test pairs
accuracy = zeros(1,5);
accuracyBatchSize = 512;

for i = 1:5
    [X1,X2,pairLabelsAcc] = getTwinBatch(imdsTest,accuracyBatchSize,'down_level',down_level);
    X1 = gpuArray(dlarray(X1,"SSCB"));
    X2 = gpuArray(dlarray(X2,"SSCB"));
    Y = predictTwin(net,fcParams,X1,X2);
    Y = gather(extractdata(Y));
    Y = round(Y);
    accuracy(i) = sum(Y == pairLabelsAcc)/accuracyBatchSize;
end

averageAccuracy = mean(accuracy)*100

%% Display test pairs with predictions
testBatchSize = 20;

[XTest1,XTest2,pairLabelsTest] = getTwinBatch(imdsTest,testBatchSize,'down_level',down_level);

XTest1 = gpuArray(dlarray(XTest1,"SSCB"));
XTest2 = gpuArray(dlarray(XTest2,"SSCB"));

% calculate predicted probability
YScore = predictTwin(net,fcParams,XTest1,XTest2);
YScore = gather(extractdata(YScore));

% Convert the predictions to binary 0 or 1.
YPred = round(YScore);
XTest1 = extractdata(XTest1);
XTest2 = extractdata(XTest2);

% Plot images with predicted label and predicted score.
f = figure;
tiledlayout(4,5);

predLabels = categorical(YPred,[0 1],["diff" "same"]);
targetLabels = categorical(pairLabelsTest,[0 1],["diff","same"]);

for i = 1:numel(pairLabelsTest)
    nexttile
    imshow([XTest1(:,:,:,i) XTest2(:,:,:,i)],[]);
    title(string(targetLabels(i)) + " / " + ...
        string(predLabels(i)) + newline + YScore(i))
end
