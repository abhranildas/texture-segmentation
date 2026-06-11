% texture_grouping.m
%
clear all;
close all;
rng(2);
sz = 1024; % scene size
bsz = 640; % Brodatz image size
rsz = 256; % region size
psz = 64;  % patch size
nr = sz/rsz;
ni = sz/psz;
nij = ni^2;
nrsp = 2;
critl = 15;
critg = 0.5;
inum = 0;
rsp = zeros(nij,nij,nrsp); % response storage array
%
% load scene
scn = zeros(sz,sz);  % scene
nimg = 60; mnk = 1; 
for i = 1:nr
 for j = 1:nr
  %
  % randomly select a texture image
  %   inum = randi(nimg);
  inum = inum + 1;
  num = num2str(inum-1+mnk);
  name = append('B',num,'.gif');
  imgk = imread(name);
  %
  % randomly select a region within that texture image
  i0 = randi(bsz-rsz); j0 = randi(bsz-rsz);
  imgij = imgk(i0:i0+rsz-1,j0:j0+rsz-1);
  ilo = (i-1)*rsz+1; ihi = ilo+rsz-1;
  jlo = (j-1)*rsz+1; jhi = jlo+rsz-1;
  scn(ilo:ihi,jlo:jhi) = imgij; % insert texture region in to the scene
 end
end
figure; colormap(gray(256)); image(scn); axis image;
%
% make patch-analysis window
r = psz/2; shp = 2;      % window size (if r = psz/2 flat) and shape
win = mk_win(psz,r,shp); % make raised-cosine-boundary window
b = 10;                  % weak power suppression parameter
%
% make histogram edges
bw = 4;                 % histogram bin width parameter, power of 2
nbin = 256/bw;
edges = zeros(nbin,1);  % histogram edges
for i = 1:nbin+1
  edges(i) = (i-1)*bw;
end
%
% compute responses
pcoor = zeros(nij,2);
for i = 1:nij
 ki = floor((i-1)/ni) + 1;
 li = i - (ki-1)*ni;
 % get patch i
 klo = (ki-1)*psz+1; khi = klo+psz-1;
 llo = (li-1)*psz+1; lhi = llo+psz-1;
 pcoor(i,1) = klo; pcoor(i,2) = llo;
 ptchi = scn(klo:khi,llo:lhi);
 for j = 1:nij
  kj = floor((j-1)/ni) + 1;
  lj = j - (kj-1)*ni;
  % get patch j
  klo = (kj-1)*psz+1; khi = klo+psz-1;
  llo = (lj-1)*psz+1; lhi = llo+psz-1;
  ptchj = scn(klo:khi,llo:lhi);
  rsp(i,j,1) = Rp(ptchi,ptchj,b,psz,win);
  rsp(i,j,2) = Rh(ptchi,ptchj,edges);
 end
end
%
% quadratic parameters for decision variable
q2 = [5.273048046354344,0.784966045877294;...
      0.784966045877294,1.323305813271773];
q1 = [0.154037415875747;-24.896804657431097];
q0 = 26.906021503125597;
%
% compute decision variable
dv = zeros(nij,nij);
for i = 1:nij
 for j = 1:nij
  if  i ~= j
    x = [log(rsp(i,j,1));log(rsp(i,j,2))];
    dv(i,j) = x'*q2*x + x'*q1 + q0;
  end
 end
end
%
% find links
links = thresh(dv,nij,critl);
%
% load links and strengths into groups array
groups = zeros(nij,2+nij,2); % group#,#links,link1,link2,...
for i = 1:nij
 for j = 1:nij
  if links(i,j) == 1
    nlnk = groups(i,2,1)+1; groups(i,2,1) = nlnk;
    groups(i,2+nlnk,1) = j;
    groups(i,2+nlnk,2) = dv(i,j);
  end
 end
end
groupset = groups(1:nij,1:nij,1);
%
% remove weak links
for i = 1:nij
 nlnka = groups(i,2,1); % number of links for patch i
 lnka = groups(i,3:3+nlnka-1,1); % list of links for patch i
 for j = 1:nlnka
  nlnkb = groups(lnka(j),2,1); % number of links for link j|i
  lnkb = groups(lnka(j),3:3+nlnkb-1,1); % list of links for link j|i
  nls = nlsame(lnka,nlnka,lnkb,nlnkb); % number of same links
  nlratio = 2*nls/(nlnka+nlnkb);
  if nlnka > 1 && nlratio < critg
   if i ~= lnka(j)
     links(i,lnka(j)) = 0;
   end
  end
 end
end
%
% find groups
gnum = 0;
for i = 1:nij
 nlnka = groups(i,2,1); % number of links for patch i
 lnka = groups(i,3:3+nlnka-1,1); % list of links for patch i
 for j = 1:nlnka
  nlnkb = groups(lnka(j),2,1); % number of links for link j|i
  lnkb = groups(lnka(j),3:3+nlnkb-1,1); % list of links for link j|i
  nls = nlsame(lnka,nlnka,lnkb,nlnkb); % number of same links
  nlratio = 2*nls/(nlnka+nlnkb);
  if nlnka > 1 && nlratio > critg
   if groups(i,1,1) == 0
    gnum = gnum+1;
    groups(i,1,1) = gnum;
    groupset(i,1) = gnum;
   end
   if groups(lnka(j),1,1) == 0
     groups(lnka(j),1,1) = groups(i,1,1);
     groupset(lnka(j),1) = groups(i,1,1);
   end
  end
 end
end
%
% make grouping map
gimg = zeros(sz,sz);
for i = 1:nij
  x = pcoor(i,1); y = pcoor(i,2);
  ptch = ones(psz,psz)*groups(i,1);
  gimg(x:x+psz-1,y:y+psz-1) = ptch;
end
figure; image(gimg,'CDataMapping','scaled'); axis image;

% figure; colormap(gray(256)); image(rthres*255); axis image;
