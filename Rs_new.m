function Rsout = Rs_new(ptch1,ptch2,psz,np)
%
% spatial pattern similarity response
%
% ptch1 & ptch2 = two patches that are compared
% psz = patch size
% np = number of subpatches
%
% normalize patches
p1 = ptch1-mean(mean(ptch1));
p2 = ptch2-mean(mean(ptch2));
p1 = p1/sqrt(sum(sum(p1.^2)));
p2 = p2/sqrt(sum(sum(p2.^2)));
%
pstp = psz/np;
xsz = psz+pstp-1;
pszc= psz-pstp;
a = pstp;
thresh = 0;
b = 10;
Rsout = 0;
% s11 = 0; s22 = 0; s12 = 0; s21 = 0;
for i = 1:pstp:psz-pstp
 for j = 1:pstp:psz-pstp
   p1k = p1(i:i+pstp-1,j:j+pstp-1);
   p1k = p1k-mean(mean(p1k));
   p1k = p1k/sum(sum(p1k.*p1k));
   p11 = xcorr2(p1,p1k);
   p11c = p11(a:xsz-a,a:xsz-a);
%    p11c = abs(p11(a:xsz-a,a:xsz-a));
   p12 = xcorr2(p2,p1k);
   p12c = p12(a:xsz-a,a:xsz-a);
%    p12c = abs(p12(a:xsz-a,a:xsz-a));
   p2k = p2(i:i+pstp-1,j:j+pstp-1);
   p2k = p2k-mean(mean(p2k));
   p2k = p2k/sum(sum(p2k.*p2k));
   p22 = xcorr2(p2,p2k);
   p22c = p22(a:xsz-a,a:xsz-a);
%    p22c = abs(p22(a:xsz-a,a:xsz-a));   
   p21 = xcorr2(p1,p2k);
   p21c = p21(a:xsz-a,a:xsz-a);
%    p21c = abs(p21(a:xsz-a,a:xsz-a));
%
   p11c = max(p11c,thresh)-thresh;
   p22c = max(p22c,thresh)-thresh;
   p12c = max(p12c,thresh)-thresh;
   p21c = max(p21c,thresh)-thresh; 
%
   r1 = Rp(p11c,p21c,b,pszc);
   r2 = Rp(p22c,p12c,b,pszc);
   Rsout = Rsout + r1 + r2;
% 
%    s11 = s11 + sum(sum(p11c));
%    s12 = s12 + sum(sum(p12c));
%    s22 = s22 + sum(sum(p22c));
%    s21 = s21 + sum(sum(p21c));
 end
end
% Rsout = s12/s11 + s21/s22;
end

