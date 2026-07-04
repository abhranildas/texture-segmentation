function [X1,X2,pairLabels] = getTwinBatch_nat(near,far,miniBatchSize)

% near, far: [psz psz 2 N] uint8 patch pairs (as produced by
% make_nat_patches.m), with dim 3 holding the two patches of a pair.
% Draws a balanced batch of near (positive, label 1) and far
% (negative, label 0) pairs.

imgSize = size(near,1);
n_near = size(near,4);
n_far  = size(far,4);

% Initialize the output.
pairLabels = zeros(1,miniBatchSize);
X1 = zeros([imgSize imgSize 1 miniBatchSize],"single");
X2 = zeros([imgSize imgSize 1 miniBatchSize],"single");

% Create a batch containing near and far pairs of images.
for i = 1:miniBatchSize
    choice = rand(1);

    % Randomly select a near or far pair of images.
    if choice < 0.5 % near (positive) pair
        k = randi(n_near);
        X1(:,:,1,i) = single(near(:,:,1,k));
        X2(:,:,1,i) = single(near(:,:,2,k));
        pairLabels(i) = 1;
    else % far (negative) pair
        k = randi(n_far);
        X1(:,:,1,i) = single(far(:,:,1,k));
        X2(:,:,1,i) = single(far(:,:,2,k));
        pairLabels(i) = 0;
    end
end

end
