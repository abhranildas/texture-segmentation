function Rh = Rh(ptch1,ptch2,b1,b2,b3,ncolr,abr)
%
% gray-scale or color histograms: log likelihood ratio of different vs
% same assuming multinomial probability distributions
%
% ptch1, ptch2 = two patches being compared
% b1, b2, b3 = bin bounds for the histogram
% ncolr = the number of dimensions of the histogram
%
if ncolr == 1   % gray scale histogram using b1
  N1 = histcounts(ptch1,b1);
  N2 = histcounts(ptch2,b1);
  n = size(N1,2);
  n1 = sum(N1); n2 = sum(N2);
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
  Rh = snum-sden;
%
elseif ncolr == 2   % two color-channel histogram using b1,b2 (e.g., R,B)
  [N1,~,~] = histcounts2(ptch1(:,:,1),ptch1(:,:,3),b1,b2);
  [N2,~,~] = histcounts2(ptch2(:,:,1),ptch2(:,:,3),b1,b2);
  n = size(N1);
  n1 = sum(sum(N1));
  n2 = sum(sum(N2));
  snum = 0;
  sden = 0;
  for i = 1:n(1)
    for j = 1:n(2)
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
  Rh = snum-sden;
%
elseif ncolr == 3   % three color-channel histogram using b1, b2, & b3
  rgb1=reshape(ptch1,[],3);
  rgb2=reshape(ptch2,[],3);
  if abr == 1 % convert to abr space to use cdf bins
    coeff = [0.500062075849096,-0.576102756138032,-0.646562862116018;...
        0.488868737081028,-0.428474344487190,0.759879657591302;...
        0.714804363586495,0.696071368816759,-0.067374856669754];
    npix = size(rgb1);
    for i = 1:npix(1)
      rgb1(i,:) = rgb1(i,:)*coeff;
      rgb2(i,:) = rgb2(i,:)*coeff;      
    end
  end
  N1 = histcn(rgb1,b1,b2,b3);
  N2 = histcn(rgb2,b1,b2,b3);
  if abr == 1
    n = [size(b1,2)-1,size(b2,2)-1,size(b3,2)-1];
  else
    n = [size(b1,1)-1,size(b2,1)-1,size(b3,1)-1];
  end
  n1 = sum(sum(sum(N1)));
  n2 = sum(sum(sum(N2)));
  snum = 0;
  sden = 0;
  for i = 1:n(1)
    for j = 1:n(2)
      for k = 1:n(3)  
        if N1(i,j,k) > 0
          snum = snum + N1(i,j,k)*log(N1(i,j,k)/n1); 
        end
        if N2(i,j,k) > 0
          snum = snum + N2(i,j,k)*log(N2(i,j,k)/n2); 
        end
        if (N1(i,j,k) + N2(i,j,k)) > 0
          sden = sden + (N1(i,j,k)+N2(i,j,k))*log((N1(i,j,k)...
              +N2(i,j,k))/(n1+n2)); 
        end
      end
    end
  end
  Rh = snum-sden;  
end
end

