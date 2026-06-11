function [X1,X2,pairLabels] = getTwinBatch_nat(imds,miniBatchSize)

% Initialize the output.
pairLabels = zeros(1,miniBatchSize);
imgSize = size(readimage(imds,1),1);
X1 = zeros([imgSize imgSize 1 miniBatchSize],"single");
X2 = zeros([imgSize imgSize 1 miniBatchSize],"single");

n_files=numel(imds.Labels);
first_same=find(imds.Labels==categorical({'same'}),1);

% Create a batch containing similar and dissimilar pairs of images.
for i = 1:miniBatchSize
    choice = rand(1);

    % Randomly select a similar or dissimilar pair of images.
    if choice < 0.5 % similar pair
        pairIdx=randi([first_same n_files]);
        % if it's even, go one below. if odd, one above:
        % pairIdx2=pairIdx1+2*(mod(pairIdx1,2)-.5);
        % [pairIdx1,pairIdx2,pairLabels(i)] = getSimilarPair(imds.Labels);
        pairLabels(i)=1;
    else % different pair        
        pairIdx=randi([1 first_same-1]);
        % if it's even, go one below. if odd, one above:
        % pairIdx2=pairIdx1+2*(mod(pairIdx1,2)-.5);
        % [pairIdx1,pairIdx2,pairLabels(i)] = getDissimilarPair(imds.Labels);
        pairLabels(i)=0;
    end
    patch_pair=mean(imds.readimage(pairIdx),3);
    X1(:,:,:,i) = patch_pair(:,1:imgSize);
    X2(:,:,:,i) = patch_pair(:,imgSize+1:end);
end

end