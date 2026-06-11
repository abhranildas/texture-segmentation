%
% Test if multinomial distributions are a reasonable model of
% natural texture gray-scale histograms
%
clearvars;
close all;
ntex = 60; % number of textures
ftex = 1;
sz = 640;
psz = 64;
n = 1; mnk = 1;
ntype = 1; m0 = 128; c0 = 0.5;
itype = 0;
bw = 16; npix = psz^2;
nbin = 256/bw;
pow = 1.0;
edgeflag = 1;
img = zeros(sz,sz);
%
% create gray-level histogram edges
if edgeflag == 0
  edges = zeros(nbin,1); % histogram edges
  for i = 1:nbin+1
    edges(i) = (i-1)*bw;
  end
elseif edgeflag == 1
  load("cdfs-9-10-12_4.mat"); % natural image cdfs
  edges = mk_bins(ea,Na,nbin)/1.7;
end
%
figure; hold on;  
for k = ftex:ftex+ntex-1
  hg = zeros(100,nbin);
  if itype == 0 % texture image
    num = num2str(k-1+mnk);
    name = append('B',num,'.gif');
    imgk = imread(name);
  elseif itype == 1 % white noise
    imgk = mk_back(sz/2,1,32,128,0,2,itype,img);
  elseif itype == 2 % filtered noise
    imgk = mk_back(sz/2,1,16,128,0,2,itype,img);
  elseif itype == 3 % phase scrambled texture image
    num = num2str(k-1+mnk);
    name = append('B',num,'.gif');
    img = imread(name);
    imgk = mk_back(sz/2,1,16,128,0,2,itype,img); 
  end
  n = 0;
  for j = 1:10
    y = (j-1)*psz + 1;
    for i = 1:10
      n = n+1;
      x = (i-1)*psz + 1;
      ptch = double(imgk(x:x+psz-1,y:y+psz-1));
      ptch = ptch_norm(ptch,m0,c0,ntype);
      hg(n,:) = histcounts(ptch,edges);
    end 
  end
  mhg = sum(hg)/n;
  vhg = var(hg,0,1);
  phg = sum(hg)/sum(sum(hg));
  pmhg = npix*phg;
  pvhg = npix*(phg).*(1-phg);
  powm = pvhg.^pow;
  scatter(vhg,powm);
end
set(gca,'yscale','log');
set(gca,'xscale','log');
xlim([10 10^6]); ylim([10 10^3]);
% axis equal;
% scatter(vhg,powm); 
% axis equal;
% set(gca,'yscale','log');
% set(gca,'xscale','log');
