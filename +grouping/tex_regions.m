%
% texture-regions stimuli
%
clearvars; close all;
pw = 64;        % 64 patch width (pixels)
np = 16;        % 16 number of patches per row and per column (pixels)
imw = pw*np;    % image width (pixels)
ntr = 5;       % number of texture regions
map = zeros(np,np); % texture label map
tlst = zeros(ntr,round(3*np^2/ntr) + 1); % list of patches for each region
%
% seed the texture label map
seeds = zeros(ntr,2);
for i = 1:ntr
  sflg = 1;
  while sflg == 1
    sflg = 0;
    x = randi(np);
    y = randi(np);
    for j = 1:ntr
      if seeds(j,1) == x && seeds(j,2) == y
        sflg = 1;
      end
    end
  end
  seeds(i,1) = x; seeds(i,2) = y;
  map(x,y) = i;  % write first patch label to map
  tlst(i,1) = 1; tlst(i,2) = x; tlst(i,3) = y; % save coorinates of first patch label
end
%
% grow the texture regions
while min(min(map)) == 0 % fill the image (no background pixels)
% while sum(tlst(:,1)) < np^2/6 % some percentage of background pixels
  iprm = randperm(ntr); % add to regions in a random order on each pass
  for i = 1:ntr
    j = iprm(i);
    n = tlst(j,1);
    nprm = randperm(n); % check patches in region for a free side in random order 
    k = 1; chkflg = 0;
    while n == tlst(j,1) && k <= n
      x = tlst(j,2*nprm(k)); y = tlst(j,2*nprm(k)+1);
      dprm = randperm(4); % check four sides of patch in random order
      l = 0;
      while l < 4 && chkflg == 0
        l = l+1;
        [chkflg,xout,yout] = chktlst(dprm(l),x,y,map,np);
      end
      if chkflg == 1
        tlst(j,1) = tlst(j,1) + 1; % when 1 is added move on to next region
        tlst(j,2*(n+1)) = xout; tlst(j,2*(n+1)+1) = yout;
        map(xout,yout) = j;
      end
      k = k+1; % if k exceeds n then move on to next region
    end
  end
end
%
figure;
image(map*256/ntr-1);
axis off;
axis square;
axis equal;
%
% make masks
msks = zeros(imw,imw,ntr);
for i = 1:ntr
  for j = 1:np
    x = (j-1)*pw+1; 
    for k = 1:np
      if map(j,k) == i
        y = (k-1)*pw+1; 
        msks(x:x+pw-1,y:y+pw-1,i) = 1;
      end
    end
  end
end
%
% to save compactly: lmsks = cast(msks,'logical');
%
% figure;
% image(255*msks(:,:,1));
% axis off;
% axis square;
% axis equal;
% figure;
% image(255*msks(:,:,ntr));
% axis off;
% axis square;
% axis equal;
%
% create texture region image
m0 = 128; c0 = 0.25; npix = imw*imw;
texnums = [2,7,11,24,31,33,37,42];
% texnums = [2,4,10,24,37,44,55,56];
pimg = zeros(imw,imw,3);
for i = 1:ntr %8
  k = texnums(i);
  num = num2str(k);
  namein = append('B',num,'.gif');
  imgin0 = double(imread(namein));
  imgin = imresize(imgin0,[imw,imw],"bilinear");
  % normalize  
  m = mean(mean(imgin));
  sd = sqrt(sum(sum((imgin-m).^2))/npix);  % standard deviation
  imgin = c0*m*(imgin-m)/sd + m;           % normalize to contrast of c0
  imgin = max(imgin,0)*m0/m;      % normalized to mean of m0
  %
  % img = zeros(640,640,3);
  img = zeros(imw,imw,3);
  img(:,:,1) = imgin;
  img(:,:,2) = imgin;
  img(:,:,3) = imgin;
  img = 255^(1/2.1)*lin2rgb(img,ColorSpace='adobe-rgb-1998');
  pimg(:,:,1) = pimg(:,:,1) + img(:,:,1).*msks(:,:,i);
  pimg(:,:,2) = pimg(:,:,2) + img(:,:,2).*msks(:,:,i);
  pimg(:,:,3) = pimg(:,:,3) + img(:,:,3).*msks(:,:,i);
end
figure;
image(pimg/255); axis('square');
axis off;
%
% segment GRT image
% [simg] = s_pimg(pimg,pw,np,ncc);
