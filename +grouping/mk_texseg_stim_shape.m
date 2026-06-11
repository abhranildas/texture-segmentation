%
% mk_texseg_shape.m
%
clearvars; close all;
blksiz = 24;    % block size
nblk = 20;      % number of blocks
ntrl = blksiz*nblk; % number of trials in session
ntex = 60;      % number of textures in database
ntexr = 5;      % number of texture regions
sz = 16;        % image size in patches
pw = 64;        % patch width in pixels
seedr = 0.75;    % texture seed radius as fraction of max
pixp = 0.5;     % proportion of pixels taken up by texture regions
%
% generate random texture numbers for all trials in a session
texs = mk_texs(ntex,ntexr,ntrl); % texs(1:ntrl,1:ntexr)
%
% generate masks and maps for all trials in a session
[masks,maps] = mk_masks(sz,ntexr,ntrl,seedr,pixp);
%
% make all images for the trials
imw = pw*sz;
m0 = 128; c0 = 0.25; npix = imw*imw; % c0 = 0.25
tperm = randperm(ntrl);
for t0 = 1:ntrl
  t = tperm(t0);
  %
  % make cue image for a trial
  cimg = ones(imw,imw,3)*128;
  %
  % region number of cue
  rnum = randi(ntexr);
  %
  % same/different flag for current trial
  sdflg = 0;
  if rand() > 0.5
    sdflg = 1;
  end
  if sdflg == 0
    [cue,cuemap] = shape_cue(maps(1:sz,1:sz,t),sz,rnum);
  else
    [cue,cuemap] = shape_cue(maps(1:sz,1:sz,randi(ntrl)),sz,rnum);
  end
  figure;
  image(cue/255); axis('square');
  x0=900;
  y0=100;
  width=1000;
  height=1000;
  set(gcf,'position',[x0,y0,width,height])
  axis off;
  pause
  close all;
  %  
  % make masks for a trial
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
  pimg = zeros(imw,imw,3);
  for i = 1:ntexr
    k = texs(t,i);
    num = num2str(k);
    namein = append('B',num,'.gif');
    % num = num2str(6);
    % namein = append('00',num,'.png');
    imgin0 = double(imread(namein));
    imgin = imresize(imgin0,[imw,imw],"bilinear");
    % normalize  
    m = mean(mean(imgin));
    sd = sqrt(sum(sum((imgin-m).^2))/npix);  % standard deviation
    imgin = c0*m*(imgin-m)/sd + m;           % normalize to contrast of c0
    imgin = max(imgin,0)*m0/m;      % normalized to mean of m0
    img = zeros(imw,imw,3);
    img(:,:,1) = imgin;
    img(:,:,2) = imgin;
    img(:,:,3) = imgin;
    img = 255^(1/2.1)*lin2rgb(img,ColorSpace='adobe-rgb-1998');
    pimg(:,:,1) = pimg(:,:,1) + img(:,:,1).*msks(:,:,i);
    pimg(:,:,2) = pimg(:,:,2) + img(:,:,2).*msks(:,:,i);
    pimg(:,:,3) = pimg(:,:,3) + img(:,:,3).*msks(:,:,i);
  end
  msk = zeros(imw,imw);
  for i = 1:ntexr
    msk(:,:) = msk(:,:) + msks(:,:,i);
  end
  for x = 1:imw
    for y = 1:imw
      if msk(x,y) == 0
        pimg(x,y,1) = 128;
        pimg(x,y,2) = 128;
        pimg(x,y,3) = 128;
      end
    end
  end
  figure;
  image(pimg/255); axis('square');
  x0=900;
  y0=100;
  width=1000;
  height=1000;
  set(gcf,'position',[x0,y0,width,height])
  axis off;
  pause
  close all;
  %
  %
  if sdflg == 0
    pimg(1:16,1:16,:) = 255; % yes cue is present/same
    % pimg(1:16,1:16,:) = pimg(1:16,1:16,:).*cuemap; % yes cue is present/same
  else
    pimg(1:16,1:16,:) = 0; % no cue is not present/different
  end    
  figure;
  image(pimg/255); axis('square');
  x0=900;
  y0=100;
  width=1000;
  height=1000;
  set(gcf,'position',[x0,y0,width,height])
  axis off;
  pause
  close all;
end

