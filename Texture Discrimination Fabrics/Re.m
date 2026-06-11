function Reout = Re(ptch1,ptch2,psz,thresh,bgo,bgm,eflag)
%
% edge geometry histogram log-likelihood ratio
%
% ptch1 & ptch2 = two patches that are compared
% psz = patch size
% thres = gradient threshold
% bgo = gradient orientation bin bounds
% bgm = gradient magnitude bin bounds
% eflag = type of edge statistics
%       1 = separate orientation and magnitude
%       2 = joint orientation and magnitude
%       3 = 
%
% normalize patches to have same mean and standard deviation
ptch1 = ptch1*128/mean(mean(ptch1)) - 128;
ptch2 = ptch2*128/mean(mean(ptch2)) - 128;
sd1 = sqrt(sum(sum(ptch1.*ptch1))/psz^2);
sd2 = sqrt(sum(sum(ptch2.*ptch2))/psz^2);
ptch1 = ptch1*42/sd1 + 128;
ptch2 = ptch2*42/sd2 + 128;
%
% compute image gradient magnitude and direction
[gm1,go1] = imgradient(ptch1);
[gm2,go2] = imgradient(ptch2);
%
% threshold gradient vectors based on gradient magnitude
% and create list of significant gradient elements for each patch
g1 = zeros(psz^2,4);
g2 = zeros(psz^2,4);
% elst1 = zeros(psz^2,2);
% elst2 = zeros(psz^2,2);
% gmr1 =  zeros(psz^2,1);
% gmr2 =  zeros(psz^2,1);
% gdr1 =  zeros(psz^2,1);
% gdr2 =  zeros(psz^2,1);
cnt1 = 0; cnt2 = 0;
for i = 1:psz
  for j = 1:psz
    if gm1(i,j) <= thresh
       gm1(i,j) = 0;
       go1(i,j) = 0;
    else
       cnt1 = cnt1 + 1;
       g1(cnt1,1) = i;
       g1(cnt1,2) = j;
       g1(cnt1,3) = gm1(i,j);
       g1(cnt1,4) = go1(i,j);     
    end
    if gm2(i,j) <= thresh
       gm2(i,j) = 0;
       go2(i,j) = 0;
    else
       cnt2 = cnt2 + 1;
       g2(cnt2,1) = i;
       g2(cnt2,2) = j;
       g2(cnt2,3) = gm2(i,j);
       g2(cnt2,4) = go2(i,j);
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
if isnan(Lm) == true
  Lm = 0;
end
if eflag == 1
  %
  % edge orientation histogram likelihood ratio
  N1 = histcounts(g1(1:cnt1,4),bgo);
  N2 = histcounts(g2(1:cnt2,4),bgo);
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
  Lgo = snum-sden;
  %
  % edge gradient magnitude histogram likelihood ratio
  N1 = histcounts(g1(1:cnt1,3),bgm);
  N2 = histcounts(g2(1:cnt2,3),bgm);
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
  Lgm = snum-sden;
  Reout = Lgo + Lgm + Lm;  % combined log likelihood ratios
elseif eflag == 2
  %
  % edge gradient magnitude histogram likelihood ratio
  N1 = histcounts2(g1(1:cnt1,3),g1(1:cnt1,4),bgm,bgo);
  N2 = histcounts2(g2(1:cnt1,3),g2(1:cnt1,4),bgm,bgo);  
  ni = size(N1,1); nj = size(N1,2);
  n1 = sum(sum(N1)); n2 = sum(sum(N2));
  snum = 0;
  sden = 0;
  for i = 1:ni
    for j = 1:nj  
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
  Lgmo = snum-sden;
  Reout = Lgmo + Lm; % joint log likelihood ratio
elseif eflag == 3
  %
end

end

