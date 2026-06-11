function Reout = Re(ptch1,ptch2,psz,thresh,ndm,bd,bth,bdth,bg,eflag)
%
% edge geometry histogram difference response
%
% ptch1 & ptch2 = two patches that are compared
% psz = patch size
% thres = gradient threshold
% ndm = number of bins to include in likelihood ratio
% bd = dx and dy bin bounds
% bth = orientation bin bounds
% bg = edge gradient bin bounds
% eflag = type of edge statistic 1 = num edges and orientation hist,
% 2 = edge hist, 3 = both, 4 = gradient hist
%
% normalize patches to have same mean and standard deviation
nth = size(bth,2)-1; ndth = size(bdth,2)-1; nd = size(bd,2)-1;
hst1 = zeros(nd,nd,ndth); hst2 = zeros(nd,nd,ndth);
ptch1 = ptch1*128/mean(mean(ptch1)) - 128;
ptch2 = ptch2*128/mean(mean(ptch2)) - 128;
sd1 = sqrt(sum(sum(ptch1.*ptch1))/psz^2);
sd2 = sqrt(sum(sum(ptch2.*ptch2))/psz^2);
ptch1 = ptch1*42/sd1 + 128;
ptch2 = ptch2*42/sd2 + 128;
% find zero crossings using log
% zc1 = edge(ptch1,'log',0,ks);
% zc2 = edge(ptch2,'log',0,ks);
% zc1 = edge(ptch1,'sobel');
% zc2 = edge(ptch2,'sobel');
zc1 = edge(ptch1,'Canny');
zc2 = edge(ptch2,'Canny');
%
% compute image gradient magnitude and direction
[gm1,gd1] = imgradient(ptch1);
[gm2,gd2] = imgradient(ptch2);
%
% find gradient magnitudes at zero crossings
% gm1 = gm1.*zc1;
% gm2 = gm2.*zc2;
% % figure; colormap(gray(256)); image(gm1); axis image;
% gd1 = gd1.*zc1;
% gd2 = gd2.*zc2;
% figure; colormap(gray(256)); image(gd1); axis image;
%
% threshold zero crossings based on gradient magnitude
% and create list of significant edge elements for each patch
elst1 = zeros(psz^2,2);
elst2 = zeros(psz^2,2);
gmr1 =  zeros(psz^2,1);
gmr2 =  zeros(psz^2,2);
gdr1 =  zeros(psz^2,1);
gdr2 =  zeros(psz^2,1);
cnt1 = 0; cnt2 = 0;
for i = 1:psz
  for j = 1:psz
    if gm1(i,j) <= thresh
       gm1(i,j) = 0;
       zc1(i,j) = 0;
       gd1(i,j) = 0;
    else
       cnt1 = cnt1 + 1;
       elst1(cnt1,1) = i;
       elst1(cnt1,2) = j;
       gmr1(cnt1) = gm1(i,j);
       gdr1(cnt1) = gd1(i,j);     
    end
    if gm2(i,j) <= thresh
       gm2(i,j) = 0;
       zc2(i,j) = 0;
       gd2(i,j) = 0;
    else
       cnt2 = cnt2 + 1;
       elst2(cnt2,1) = i;
       elst2(cnt2,2) = j;
       gmr2(cnt2) = gm2(i,j);
       gdr2(cnt2) = gd2(i,j);
    end
  end
end
% figure; hold on; histogram(gmg1(1:cnt1)); histogram(gmg2(1:cnt2));
% figure; hold on; histogram(gdr1(1:cnt1)); histogram(gdr2(1:cnt2));
%
% edge count likelihood ratio
nmx = psz^2;
n1 = cnt1; n2 = cnt2;
Lm = n1*log(2*n1/(n1+n2))+(nmx-n1)*log(2*(nmx-n1)/(2*nmx-n1-n2))+...
     n2*log(2*n2/(n1+n2))+(nmx-n2)*log(2*(nmx-n2)/(2*nmx-n1-n2));
%
% edge orientation histogram likelihood ratio
N1 = histcounts(gdr1(1:cnt1),bth);
N2 = histcounts(gdr2(1:cnt2),bth);
n = size(N1,2); n1 = sum(N1); n2 = sum(N2);
snum = 0;
sden = 0;
for i = 1:n
  if N1(i) > 0
    snum = snum + N1(i)*log(N1(i)/n1); 
  end
  if N2(i) > 0
    snum = snum + N2(i)*log(N2(i)/n2); 
  end
  if (N1(i) + N2(i)) > 0
    sden = sden + (N1(i)+N2(i))*log((N1(i)+N2(i))/(n1+n2)); 
  end
end
Lth = snum-sden;
%
% edge gradient magnitude histogram likelihood ratio
N1 = histcounts(gmr1(1:cnt1),bg);
N2 = histcounts(gmr2(1:cnt2),bg);
n = size(N1,2); n1 = sum(N1); n2 = sum(N2);
snum = 0;
sden = 0;
for i = 1:n
  if N1(i) > 0
    snum = snum + N1(i)*log(N1(i)/n1); 
  end
  if N2(i) > 0
    snum = snum + N2(i)*log(N2(i)/n2); 
  end
  if (N1(i) + N2(i)) > 0
    sden = sden + (N1(i)+N2(i))*log((N1(i)+N2(i))/(n1+n2)); 
  end
end
Lg = snum-sden;
%
% distance and orientation difference histograms for patch 1
dth = zeros(psz^4,2);
hcnt1 = 0;
for i = 1:cnt1-1
  xi = elst1(i,1); yi = elst1(i,2);
  for j = i+1:cnt1
    hcnt1 = hcnt1 + 1;
    xj = elst1(j,1); yj = elst1(j,2);  
    dth(hcnt1,1) = sqrt((xi-xj)^2 + (yi-yj)^2);    
    adt = abs(gd1(xi,yi)-gd1(xj,yj));
    if adt > 180
      adt = 360-adt;
    end
    dth(hcnt1,2) = adt;
  end
end
N1 = histcounts2(dth(1:hcnt1,1),dth(1:hcnt1,2),bd,bdth);
%
% distance and orientation difference histograms for patch 2
dth = zeros(psz^4,2);
hcnt2 = 0;
for i = 1:cnt2-1
  xi = elst2(i,1); yi = elst2(i,2);
  for j = i+1:cnt2
    hcnt2 = hcnt2 + 1;
    xj = elst2(j,1); yj = elst2(j,2);  
    dth(hcnt2,1) = sqrt((xi-xj)^2 + (yi-yj)^2);    
    adt = abs(gd2(xi,yi)-gd2(xj,yj));
    if adt > 180
      adt = 360-adt;
    end
    dth(hcnt2,2) = adt;
  end
end
N2 = histcounts2(dth(1:hcnt2,1),dth(1:hcnt2,2),bd,bdth);
%
% oriention difference histogram likelihood ratio
n1 = sum(sum(N1)); n2 = sum(sum(N2));
snum = 0;
sden = 0;
for i = 1:nd
  for j = 1:ndth
    if N1(i,j) > 0
      snum = snum + N1(i,j)*log(N1(i,j)/n1); 
    end
    if N2(i,j) > 0
      snum = snum + N2(i,j)*log(N2(i,j)/n2); 
    end
    if (N1(i,j) + N2(i,j)) > 0
      sden = sden + (N1(i,j)+N2(i,j))*log((N1(i,j)+N2(i,j))/(n1+n2)); 
    end
  end
end
% Ldth = snum-sden;
% %
% % distance histogram likelihood ratio
% n = size(N1d,2); n1 = sum(N1d); n2 = sum(N2d);
% snum = 0;
% sden = 0;
% for i = 1:n
%   if N1d(i) > 0
%     snum = snum + N1d(i)*log(N1d(i)/n1); 
%   end
%   if N2d(i) > 0
%     snum = snum + N2d(i)*log(N2d(i)/n2); 
%   end
%   if (N1d(i) + N2d(i)) > 0
%     sden = sden + (N1d(i)+N2d(i))*log((N1d(i)+N2d(i))/(n1+n2)); 
%   end
% end
% Ld = snum-sden;
%
% edge histogram likelihood ratio
if eflag > 1
%
% make histogram 1
  for i = 1:cnt1-1
    xi = elst1(i,1); yi = elst1(i,2);
    for j = i+1:cnt1
      xj = elst1(j,1); yj = elst1(j,2);  
      adx = abs(xi-xj);
      ady = abs(yi-yj);    
      adt = abs(gd1(xi,yi)-gd1(xj,yj));
      if adt > 180
        adt = 360-adt;
      end
      for k = 1:nd
        if (bd(k) <= adx) && (adx < bd(k+1))
          xh = k;
        end
        if (bd(k) <= ady) && (ady < bd(k+1))
          yh = k;
        end
      end
      for k = 1:nth
        if (bdth(k) <= adt) && (adt <= bdth(k+1))
          th = k;
        end
      end
      hst1(xh,yh,th) = hst1(xh,yh,th) + 1;
    end
  end
%
% make histogram 2
  for i = 1:cnt2-1
    xi = elst2(i,1); yi = elst2(i,2);
    for j = i+1:cnt2
      xj = elst2(j,1); yj = elst2(j,2);  
      adx = abs(xi-xj);
       ady = abs(yi-yj); 
      adt = abs(gd2(xi,yi)-gd2(xj,yj));
      if adt > 180
        adt = 360-adt;
      end    
      for k = 1:nd
        if (bd(k) <= adx) && (adx < bd(k+1))
          xh = k;
        end
        if (bd(k) <= ady) && (ady < bd(k+1))
          yh = k;
        end
      end
      for k = 1:nth
        if (bdth(k) <= adt) && (adt <= bdth(k+1))
          th = k;
        end
      end
      hst2(xh,yh,th) = hst2(xh,yh,th) + 1;
    end
  end
  %
  % compute log likelihood ratio
  snum = 0;
  sden = 0;
  n1 = sum(sum(sum(hst1(1:ndm,1:ndm,1:nth))));
  n2 = sum(sum(sum(hst2(1:ndm,1:ndm,1:nth))));
  for i = 1:ndm
    for j = 1:ndm
      for k = 1:nth
        if hst1(i,j,k) > 0
          snum = snum + hst1(i,j,k)*log(hst1(i,j,k)/n1);
        end
        if hst2(i,j,k) > 0
          snum = snum + hst2(i,j,k)*log(hst2(i,j,k)/n2);
        end
        if (hst1(i,j,k)+hst2(i,j,k)) > 0
          sden = sden + (hst1(i,j,k)+hst2(i,j,k))*...
            log((hst1(i,j,k)+hst2(i,j,k))/(n1+n2));
        end
      end 
    end
  end
  Lxyth = snum-sden;
end
if eflag == 1
  % Reout = Lth + Lm;
  % Reout = Lth + Lm + Ldth*(cnt1+cnt2)/(hcnt1+hcnt2);  
  % Reout = Ldth;
  Reout = Lth + Lg + Lm;
elseif eflag == 2
  Reout = Lxyth;
elseif eflag == 3
  Reout = Lxyh + Lm;
end
%
% figure; colormap(gray(256)); image(ptch1); axis image;
% figure; colormap(gray(256)); image(ptch2); axis image;
% figure; colormap(gray(256)); image(zc1*255); axis image;
% figure; colormap(gray(256)); image(gm1); axis image;
% figure; colormap(gray(256)); image(zc2*255); axis image;
% figure; colormap(gray(256)); image(gm2); axis image;
%
% plot histograms
% figure;
% x = [0;15;30;45;60;75;90;105;120;135;150;165];
% z = zeros(12,1);
% k = 0;
% for i = 1:8
%   for j = 1:8
%     k = k + 1;
%     subplot(8,8,k)
%     for l = 1:12
%       z(l) = hst1(i,j,l);
%     end
%     bar(x,z);
%   end
% end
% figure;
% k = 0;
% for i = 1:8
%   for j = 1:8
%     k = k + 1;
%     subplot(8,8,k)
%     for l = 1:12
%       z(l) = hst2(i,j,l);
%     end
%     bar(x,z);
%   end
% end
end

