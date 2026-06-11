function [X1,X2,pairLabels] = getTwinBatch(imds,miniBatchSize,varargin)

parser = inputParser;
parser.KeepUnmatched = true;
addRequired(parser,'imds');
addRequired(parser,'miniBatchSize');
addParameter(parser,'down_level',1);

parse(parser,imds,miniBatchSize,varargin{:});
down_level=parser.Results.down_level;


% Initialize the output.
pairLabels = zeros(1,miniBatchSize);
imgSize = size(readimage(imds,1));
X1 = zeros([imgSize 1 miniBatchSize],"single");
X2 = zeros([imgSize 1 miniBatchSize],"single");

% Create a batch containing similar and dissimilar pairs of images.
for i = 1:miniBatchSize
    choice = rand(1);

    % Randomly select a similar or dissimilar pair of images.
    if choice < 0.5
        [pairIdx1,pairIdx2,pairLabels(i)] = getSimilarPair(imds.Labels);
    else
        [pairIdx1,pairIdx2,pairLabels(i)] = getDissimilarPair(imds.Labels);
    end

    img_1=imds.readimage(pairIdx1);
    img_2=imds.readimage(pairIdx2);

    % if needed, downsample, then upsample to same size
    if down_level>1
        img_1=lib.downsample(img_1,down_level);
        img_1=imresize(img_1,down_level,'nearest');

        img_2=lib.downsample(img_2,down_level);
        img_2=imresize(img_2,down_level,'nearest');
    end
    X1(:,:,:,i)=img_1;
    X2(:,:,:,i)=img_2;
end

end