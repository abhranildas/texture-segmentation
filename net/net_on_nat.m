%% Load the training data from folder names.
% dataFolderTrain = fullfile("../img_data/brodatz/patches/train");
% dataFolderTrain = fullfile("../img_data/nat/patches");

imds = imageDatastore('img_data/nat/patches', ...
    IncludeSubfolders=true, ...
    LabelSource='foldernames');

numTrainFiles = round(numel(imds.Files)/2*3/4);

[imdsTrain,imdsValidation] = splitEachLabel(imds,numTrainFiles,'randomize');

% Display a random selection of the images.
% idx = randperm(numel(imdsTrain.Files),8);
% 
% figure
% for i = 1:numel(idx)
%     subplot(4,2,i)
%     imshow(readimage(imdsTrain,idx(i)))
%     title(imdsTrain.Labels(idx(i)),Interpreter="none");
% end

% Create Pairs of Similar and Dissimilar Images
% batchSize = 10;
% [pairImage1,pairImage2,pairLabel] = getTwinBatch_nat(imdsTrain,batchSize);
% 
% figure
% for i = 1:batchSize
%     if pairLabel(i) == 1
%         s = "similar";
%     else
%         s = "dissimilar";
%     end
%     subplot(2,5,i)
%     imshow([pairImage1(:,:,:,i) pairImage2(:,:,:,i)],[]);
%     title(s)
% end

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

fcParams = struct(...
    "FcWeights",fcWeights,...
    "FcBias",fcBias);

%% train network
numIterations = 1e4;
miniBatchSize = 200;
learningRate = 6e-5;
gradDecay = 0.9;
gradDecaySq = 0.99;
executionEnvironment = "auto";
% gpu = gpuDevice;

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
    [X1,X2,pairLabels] = getTwinBatch_nat(imdsTrain,miniBatchSize);

    % Convert mini-batch of data to dlarray. Specify the dimension labels
    % "SSCB" (spatial, spatial, channel, batch) for image data. Then
    % convert to gpuArray
    X1 = gpuArray(dlarray(X1,"SSCB"));
    X2 = gpuArray(dlarray(X2,"SSCB"));

    % Evaluate the model loss on training images, and gradients using dlfeval and the modelLoss
    % function listed at the end of the example.
    [training_loss,gradientsSubnet,gradientsParams] = dlfeval(@modelLoss,net,fcParams,X1,X2,pairLabels);

    % Update the twin subnetwork parameters.
    [net,trailingAvgSubnet,trailingAvgSqSubnet] = adamupdate(net,gradientsSubnet, ...
        trailingAvgSubnet,trailingAvgSqSubnet,iteration,learningRate,gradDecay,gradDecaySq);

    % Update the fullyconnect parameters.
    [fcParams,trailingAvgParams,trailingAvgSqParams] = adamupdate(fcParams,gradientsParams, ...
        trailingAvgParams,trailingAvgSqParams,iteration,learningRate,gradDecay,gradDecaySq);

    % Evaluate predictions using trained network
    Y = predictTwin(net,fcParams,X1,X2);

    % Convert predictions to binary 0 or 1
    Y = gather(extractdata(Y));
    Y = round(Y);

    % Compute average training accuracy for the minibatch
    training_acc = sum(Y == pairLabels)/miniBatchSize;

    % Extract mini-batch of validation image pairs and pair labels
    [X1,X2,pairLabels] = getTwinBatch_nat(imdsValidation,miniBatchSize);

    % Convert mini-batch of data to dlarray. Specify the dimension labels
    % "SSCB" (spatial, spatial, channel, batch) for image data. Then
    % convert to gpuArray
    X1 = gpuArray(dlarray(X1,"SSCB"));
    X2 = gpuArray(dlarray(X2,"SSCB"));

    % Evaluate the model loss on validation images
    validation_loss = dlfeval(@modelLoss,net,fcParams,X1,X2,pairLabels);

    % Evaluate predictions using trained network
    Y = predictTwin(net,fcParams,X1,X2);

    % Convert predictions to binary 0 or 1
    Y = gather(extractdata(Y));
    Y = round(Y);

    % Compute average validation accuracy for the minibatch
    validation_acc = sum(Y == pairLabels)/miniBatchSize;

    % Update the training progress monitor.
    recordMetrics(monitor,iteration,TrainingLoss=training_loss,ValidationLoss=validation_loss,TrainingAccuracy=training_acc,ValidationAccuracy=validation_acc);
    monitor.Progress = 100 * iteration/numIterations;

end

%% save the trained network
save('net_on_nat.mat','net','fcParams')

%% Test generalization on Brodatz

imdsGen = imageDatastore("img_data/brodatz/patches/generalize", ...
    IncludeSubfolders=true, ...
    LabelSource="foldernames");

accuracy = zeros(1,5);
accuracyBatchSize = 150;

for i = 1:5
    % Extract mini-batch of image pairs and pair labels
    [X1,X2,pairLabelsAcc] = getTwinBatch(imdsGen,accuracyBatchSize);

    X1 = gpuArray(dlarray(X1,"SSCB"));
    X2 = gpuArray(dlarray(X2,"SSCB"));

    % Evaluate predictions using trained network
    Y = predictTwin(net,fcParams,X1,X2);

    % Convert predictions to binary 0 or 1
    Y = gather(extractdata(Y));
    Y = round(Y);

    % Compute average accuracy for the minibatch
    accuracy(i) = sum(Y == pairLabelsAcc)/accuracyBatchSize;
end

averageAccuracy = mean(accuracy)*100

% Display test pairs with Predictions

testBatchSize = 20;

[XTest1,XTest2,pairLabelsTest] = getTwinBatch(imdsGen,testBatchSize);

XTest1 = dlarray(XTest1,"SSCB");
XTest2 = dlarray(XTest2,"SSCB");
XTest1 = gpuArray(XTest1);
XTest2 = gpuArray(XTest2);

% calculate predicted probability
YScore = predictTwin(net,fcParams,XTest1,XTest2);
YScore = gather(extractdata(YScore));

% Convert the predictions to binary 0 or 1.
YPred = round(YScore);
% Extract the data for plotting.
XTest1 = extractdata(XTest1);
XTest2 = extractdata(XTest2);

% Plot images with predicted label and predicted score.
f = figure;
tiledlayout(4,5);
% f.Position(3) = 2*f.Position(3);

predLabels = categorical(YPred,[0 1],["dissimilar" "similar"]);
targetLabels = categorical(pairLabelsTest,[0 1],["dissimilar","similar"]);

for i = 1:numel(pairLabelsTest)
    nexttile
    imshow([XTest1(:,:,:,i) XTest2(:,:,:,i)],[]);

    title( ...
        "Target: " + string(targetLabels(i)) + newline + ...
        "Predicted: " + string(predLabels(i)) + newline + ...
        "Score: " + YScore(i))
end