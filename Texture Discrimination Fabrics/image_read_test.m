% read image test
img = imread('F2.png');
img2 = imresize(img,[640 640],"bilinear");
r = img2(:,:,1);