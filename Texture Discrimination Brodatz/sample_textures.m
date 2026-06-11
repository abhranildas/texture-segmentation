%
% Sample textures
close all;
clear all;
rng(0);
sz = 640;
nptch = 1000;
ntex = 60;
psz = 64;
ptch = zeros(psz,psz,nptch);
for k = 1:ntex
  num = num2str(k);
  name = append('B',num,'.gif');
  imgk = imread(name);
  for j = 1:nptch
      x = randi(sz-psz);
      y = randi(sz-psz);
      ptch(:,:,j) = double(imgk(x:x+psz-1,y:y+psz-1));
  end
    name = append('sB',num,'.mat');
    save(name,'ptch','-v7');
end
ptchj = ptch(:,:,30);
figure; colormap(gray(256)); image(ptchj); axis image;
samp = load('sB1.mat');
