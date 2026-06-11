function session=mk_texseg_session(tex_set,ntex)
% mk_texseg_session_points.m
%
% makes and saves all the information for the trials in a session
% run this before running the session
%
% during the session call mk_trl_points to create, on the fly,
% the stimulus for the current trial
%
seed = 0; rng(seed);
blksiz = 24;    % block size
nblk = 20;      % number of blocks
ntrl = blksiz*nblk; % number of trials in session
nc = 5; c0 = [0.1,0.075,0.05,0.03,0.02]; % number of contrasts and contrast values
m0 = 128;
cntrst = zeros(ntrl,1);
trlstp = nc*blksiz;
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
%
% generate random texture numbers for all trials in a session
texs = grouping.mk_texs(ntex,ntexr,ntrl);
%
% generate masks and maps for all trials in a session
[~,maps] = grouping.mk_masks(sz,ntexr,ntrl,seedr,pixp);
%
% make geometry matrices for patch pairs, size if each = sz^2 x sz^2
dist = grouping.mk_dist(sz); mecc = grouping.mk_mecc(sz); decc = grouping.mk_decc(sz);
%
% make array of index values to patch geometry bins
bindex = grouping.mk_bindex(bbdist,bbmecc,bbdecc);
%
% load the bin table counts and the specific pairs of patches in each bin
for i = 1:sz^2
  for j = 1:sz^2
    if i ~= j
      bin = grouping.fnd_bin(i,j,dist,mecc,decc,bbdist,bbmecc,bbdecc,bindex);
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
  [x1,y1] = grouping.fnd_xy(trl,maps,sz);
  regnum1 = maps(x1,y1,trl);
  %
  % random sample a second patch location and determine its region
  done = 0;
  while done == 0
    [x2,y2] = grouping.fnd_xy(trl,maps,sz);    
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
  bin = grouping.fnd_bin(i0,j0,dist,mecc,decc,bbdist,bbmecc,bbdecc,bindex);
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
    flg1 = grouping.chk_xy(x1,y1,trl+1,maps,sz); flg2 = grouping.chk_xy(x2,y2,trl+1,maps,sz);
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
%
% make contrasts for the trials
imw = pw*sz;
npix = imw*imw;
tperm = randperm(ntrl);
trl = 0;
for t0 = 1:trlstp:ntrl % all contrast blocks
  ic = 0;
  for t1 = t0:blksiz:t0+trlstp-1 % contrast block
    ic = ic + 1;  
    for t2 = t1:t1+blksiz-1 % within contrast block trials 
      trl = trl + 1;
      cntrst(trl) = c0(ic);
    end
  end
end
% num = num2str(session);
session=struct;
session.cntrst=cntrst;
session.cuelocs=cuelocs;
session.m0=m0;
session.maps=maps;
session.pw=pw;
session.sz=sz;
session.texs=texs;
session.tex_set=tex_set;
session.tperm=tperm;

% nameout = append('session',num,'.mat');
% save(nameout,'texset','m0','sz','pw','tperm','cntrst','cuelocs',...
%     'texs','maps','-mat');

