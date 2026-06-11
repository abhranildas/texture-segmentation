%
% mk_texseg_stim.m
%
clearvars; close all;
session = 1;    % session number
texset = 1;     % set of textures: 1=Brodatz,2=Fabric,3=Pertex
nc = 5; c0 = [10,8,6,4,2]; % number of contrasts and contrast values
blksiz = 24;    % block size
nblk = 20;      % number of blocks
ntrl = blksiz*nblk; % number of trials in session
trlstp = nc*blksiz;
ntex = 60;      % number of textures in database
ntexr = 5;      % number of texture regions
sz = 16;        % image size in patches
pw = 64;        % patch width in pixels
seedr = 1.0;    % texture seed radius as fraction of max
pixp = 1.0;     % proportion of pixels taken up by texture regions
bbdist = [1,2,4,8,16,32];   % distance bin bounds
bbmecc = [0,1,2,4,8,12];    % minimum eccentricity bin bounds
bbdecc = [0,2,4,6,8,12];    % eccentricity difference bin bounds
nbins = (size(bbdist,2)-1)*(size(bbmecc,2)-1)*(size(bbdecc,2)-1);
bintbl = zeros(2*sz^4,nbins); % bin table
wcntmx = 100;
iw = sz*pw;
img8b = zeros(iw,iw,ntrl,'uint8');
%
% generate random texture numbers for all trials in a session
texs = mk_texs(ntex,ntexr,ntrl); % texs(1:ntrl,1:ntexr)
%
% generate masks and maps for all trials in a session
[masks,maps] = mk_masks(sz,ntexr,ntrl,seedr,pixp);
%
cue = shape_cue(maps(1:sz,1:sz,1),sz,3);
%
% make geometry matrices for patch pairs, size if each = sz^2 x sz^2
dist = mk_dist(sz); mecc = mk_mecc(sz); decc = mk_decc(sz);
%
% make array of index values to patch geometry bins
bindex = mk_bindex(bbdist,bbmecc,bbdecc);
%
% load the bin table counts and the specific pairs of patches in each bin
for i = 1:sz^2
  for j = 1:sz^2
    if i ~= j
      bin = fnd_bin(i,j,dist,mecc,decc,bbdist,bbmecc,bbdecc,bindex);
      bintbl(1,bin) = bintbl(1,bin) + 1;
      idx = 2*bintbl(1,bin);
      bintbl(idx,bin) = i; bintbl(idx+1,bin) = j;
    end
  end
end
%
cuelocs = zeros(ntrl,5); % locations of texture-region cues
%
trl = 1; mxcnt = 0;
while trl <= ntrl
  %
  % randomly sample condition "same" or "different"
  cond = 0;   % same
  if rand() > 0.5
    cond = 1; % different
  end
    %
  % randomly sample a patch location and determine its region number
  [x1,y1] = fnd_xy(trl,maps,sz);
  regnum1 = maps(x1,y1,trl);
  %
  % random sample a second patch location and determine its region
  done = 0;
  while done == 0
    [x2,y2] = fnd_xy(trl,maps,sz);    
    regnum2 = maps(x2,y2,trl);
    if (regnum1 == regnum2) && (cond == 0)
      done = 1;
    elseif (regnum1 ~= regnum2) && (cond == 1)
      done = 1;
    end
    if x1 == x2 && y1 == y2
      done = 0;
    end
  end
  cuelocs(trl,1) = cond; cuelocs(trl,2) = x1; cuelocs(trl,3) = y1;
  cuelocs(trl,4) = x2; cuelocs(trl,5) = y2;
  %
  % switch conditions and repeat for same bin
  if cond == 1
    cond = 0;
  else
    cond = 1;
  end
  i0 = (x1-1)*sz + y1;
  j0 = (x2-1)*sz + y2;
  bin = fnd_bin(i0,j0,dist,mecc,decc,bbdist,bbmecc,bbdecc,bindex);
  np = bintbl(1,bin);
  done = 0; wcnt = 0;
  while done == 0 && wcnt < wcntmx
    wcnt = wcnt + 1;
    n0 = randi(np);
    i = bintbl(2*n0,bin);
    j = bintbl(2*n0+1,bin);
    y1 = mod(i,sz);
    if y1 == 0
      y1 = sz;
    end
    x1 = 1 + (i-y1)/sz;
    y2 = mod(j,sz);
    if y2 == 0
      y2 = sz;
    end
    x2 = 1 + (j-y2)/sz;
    flg1 = chk_xy(x1,y1,trl+1,maps,sz); flg2 = chk_xy(x2,y2,trl+1,maps,sz);
    if (flg1 == 0)  && (flg2 == 0)
      regnum1 = maps(x1,y1,trl+1);
      regnum2 = maps(x2,y2,trl+1);
      if (regnum1 == regnum2) && (cond == 0)
        done = 1;
      elseif (regnum1 ~= regnum2) && (cond == 1)
        done = 1;
      end
    end
  end
  if wcnt < wcntmx
    cuelocs(trl+1,1) = cond; cuelocs(trl+1,2) = x1; cuelocs(trl+1,3) = y1;
    cuelocs(trl+1,4) = x2; cuelocs(trl+1,5) = y2;
    trl = trl+2;
  else
    mxcnt = mxcnt +1;
  end
end
% for i = 1:ntrl
%   %
%   image(maps(:,:,i)*256/ntexr-1);
%   axis off;
%   axis square;
%   axis equal;
%   cond = cuelocs(i,1);
%   x1 = cuelocs(i,2); y1 =  cuelocs(i,3);
%   x2 = cuelocs(i,4); y2 =  cuelocs(i,5);
%   maps(x1,y1,i) = 0; maps(x2,y2,i) = 0; 
%   figure;
%   image(maps(:,:,i)*256/ntexr-1);
%   axis off;
%   axis square;
%   axis equal;
%   close all;  % put break point here
% end
%
% make all images for the trials
imw = pw*sz;
m0 = 128; npix = imw*imw; % c0 = 0.25
tperm = randperm(ntrl);
trl = 0;
for t0 = 1:trlstp:ntrl % all contrast blocks
  ic = 0;
  for t1 = t0:blksiz:trlstp-1 % contrast block
    ic = ic + 1;  
    for t2 = t1:blksiz-1 % within contrast block trials 
      trl = trl + 1;
      t = tperm(trl);
      %
      % make cue image for a trial
      cimg = ones(imw,imw,3)*128;
      condition = cuelocs(t,1);
      x1 = cuelocs(t,2)*pw - pw/2; y1 = cuelocs(t,3)*pw - pw/2;
      x2 = cuelocs(t,4)*pw - pw/2; y2 = cuelocs(t,5)*pw - pw/2;
      cimg(x1-4:x1+4,y1-4:y1+4,:) = 0;
      cimg(x2-4:x2+4,y2-4:y2+4,:) = 0;
      cimg(imw/2-4:imw/2+4,imw/2-4:imw/2+4,:) = 160;
      figure;
      image(cimg/255); axis('square');
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
        imgin = c0(ic)*m*(imgin-m)/sd + m;  % normalize to contrast of c0
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
      img8b(:,:,trl) =  cast(pimg(:,:,1),'uint8');
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
      % show feedback
      pimg(x1-4:x1+4,y1-4:y1+4,:) = 0;
      pimg(x2-4:x2+4,y2-4:y2+4,:) = 0;
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
  end
end
% save texset,m,c0,tperm,cuelocs,texs,maps

