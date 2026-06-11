%% Define the training and test data
dataset='nat';

if strcmpi(dataset,'brodatz')
    imdsTrain = imageDatastore('img_data/brodatz/patches/train',IncludeSubfolders=true,LabelSource='foldernames');
    down_level=1; % downsampling

elseif strcmpi(dataset,'nat')
    % Directly assign the entire nat dataset to the training datastore
    imdsTrain = imageDatastore('img_data/nat/patches',IncludeSubfolders=true,LabelSource='foldernames');
end

% Define the validation set universally so it always uses Brodatz test patches
imdsTest = imageDatastore('img_data/brodatz/patches/test',IncludeSubfolders=true,LabelSource='foldernames');

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
        [X1,X2,pairLabels] = getTwinBatch_nat(imdsTrain,miniBatchSize);
    end
    
    % move labels to GPU
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
    
    % OPTIMIZATION: Compute accuracy entirely on the A2000, only gather the final scalar
    Y = round(extractdata(Y));
    training_acc = gather(sum(Y == pairLabels)/miniBatchSize); 
    
    % Extract mini-batch of test image pairs and pair labels
    if strcmpi(dataset,'brodatz')
        [X1,X2,pairLabels] = getTwinBatch(imdsTest,miniBatchSize,'down_level',down_level);
    elseif strcmpi(dataset,'nat')
        [X1,X2,pairLabels] = getTwinBatch(imdsTest,miniBatchSize);
    end
    
    % OPTIMIZATION: Apply same single-precision and GPU-labeling to validation set
    X1 = dlarray(gpuArray(X1),"SSCB");
    X2 = dlarray(gpuArray(X2),"SSCB");
    pairLabels = gpuArray(pairLabels);
    
    % Evaluate the model loss on validation images
    validation_loss = dlfeval(@modelLoss,net,fcParams,X1,X2,pairLabels);
    
    % Evaluate predictions using trained network
    Y = predictTwin(net,fcParams,X1,X2);
    
    % OPTIMIZATION: Compute validation accuracy on GPU
    Y = round(extractdata(Y));
    validation_acc = gather(sum(Y == pairLabels)/miniBatchSize);
    
    % Update the training progress monitor. (Ensure loss is gathered for the monitor)
    recordMetrics(monitor,iteration,TrainingLoss=gather(training_loss),ValidationLoss=gather(validation_loss),TrainingAccuracy=training_acc,ValidationAccuracy=validation_acc);
    monitor.Progress = 100 * iteration/numIterations;
end


%% save the trained network
save('net_on_nat.mat','net','fcParams')

%% Test accuracy over five random mini-batches of test pairs.
accuracy = zeros(1,5);
accuracyBatchSize = 512;

for i = 1:5
    % Extract mini-batch of image pairs and pair labels
    [X1,X2,pairLabelsAcc] = getTwinBatch(imdsTest,accuracyBatchSize);

    % Convert mini-batch of data to dlarray. Specify the dimension labels
    % "SSCB" (spatial, spatial, channel, batch) for image data. Then
    % convert to gpuArray
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

[XTest1,XTest2,pairLabelsTest] = getTwinBatch(imdsTest,testBatchSize);

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

predLabels = categorical(YPred,[0 1],["diff" "same"]);
targetLabels = categorical(pairLabelsTest,[0 1],["diff","same"]);

for i = 1:numel(pairLabelsTest)
    nexttile
    imshow([XTest1(:,:,:,i) XTest2(:,:,:,i)],[]);

    title(string(targetLabels(i)) + " / " + ...
        string(predLabels(i)) + newline +YScore(i))
end