function [cond,cimg,timg,fimg] = mk_trl_points(t,sz,pw,m0,tex_set,c0,cuelocs,texs,maps)
%
% makes the images for a trial in the texture segment task with point cues
%
% make cue image for a trial
imw = sz*pw; npix = imw*imw;
cimg = ones(imw,imw)*128;
cond = cuelocs(t,1);
x1 = cuelocs(t,2)*pw - pw/2; y1 = cuelocs(t,3)*pw - pw/2;
x2 = cuelocs(t,4)*pw - pw/2; y2 = cuelocs(t,5)*pw - pw/2;
cimg(x1-4:x1+4,y1-4:y1+4,:) = 0;
cimg(x2-4:x2+4,y2-4:y2+4,:) = 0;
cimg(imw/2-4:imw/2+4,imw/2-4:imw/2+4,:) = 160;
%
% make masks for a trial
[~,ntexr] = size(texs);
msks = zeros(imw,imw,ntexr);
for i = 1:ntexr
    for j = 1:sz
        x = (j-1)*pw+1;
        for k = 1:sz
            if maps(j,k,t) == i
                y = (k-1)*pw+1;
                msks(x:x+pw-1,y:y+pw-1,i) = 1;
            end
        end
    end
end
%
% make the texure image for a trial
timg = zeros(imw,imw);
for i = 1:ntexr
    num = texs(t,i);
    % num = num2str(k);
    if strcmpi(tex_set,'brodatz')
        namein = ['global_data\textures\brodatz\B' num2str(num) '.gif'];
        imgin = double(imread(namein));
    elseif strcmpi(tex_set,'fabric')
        namein = ['global_data\textures\fabric\FC' num2str(num) '.png'];
        imgin = double(rgb2gray(imread(namein)));
    elseif strcmpi(tex_set,'pertex')
        namein = sprintf('global_data\\textures\\pertex\\%03d.png',num);
        imgin = double(imread(namein));
    end

    % resize image if necessary
    if size(imgin,1) ~= imw
        imgin = imresize(imgin,[imw,imw],"bilinear");
    end

    % normalize
    m = mean(mean(imgin));
    sd = sqrt(sum(sum((imgin-m).^2))/npix);  % standard deviation
    imgin = c0*m*(imgin-m)/sd + m;  % normalize to a given contrast
    imgin = max(imgin,0)*m0/m;      % normalized to mean of m0
    % imgout = (255^0.5)*imgin.^(1/2);    % gamma compress and quantize
    timg(:,:) = timg(:,:) + imgin(:,:).*msks(:,:,i);
end
% imshow(timg,[]);
%
% feedback img
fimg = timg;
fimg(x1-4:x1+4,y1-4:y1+4,:) = 0;
fimg(x2-4:x2+4,y2-4:y2+4,:) = 0;
end