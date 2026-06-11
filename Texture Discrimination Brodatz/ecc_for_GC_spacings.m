%
% find eccentricities for set of GC spacings
%
clearvars;
close all;
jmx = 3000;
i = 0;
fx = 0; fy = 0; scl = 1; ppd = 60;
sp = zeros(jmx,1);
for j = 1:jmx
  sp(j) = sp_pix(i,j,fy,fx,scl,ppd);
end
j1 = 1;
sp1 =sp(j1);
ecc1 = 0;
for j = 1:jmx
  if (sp(j) <= 2*sp1) && (sp(j+1) >= 2*sp1) % factor of 2 increase
     sp2 = sp(j);
     j2 = j;
     ecc2 = sqrt(j2^2 - j1^2)/ppd;
  end
end
for j = 1:jmx
  if (sp(j) <= 4*sp1) && (sp(j+1) >= 4*sp1) % factor of 4 increase
     sp3 = sp(j);
     j3 = j;
     ecc3 = sqrt(j3^2 - j1^2)/ppd;
  end
end
for j = 1:jmx
  if (sp(j) <= 8*sp1) && (sp(j+1) >= 8*sp1) % factor of 8 increase
     sp4 = sp(j);
     j4 = j;
     ecc4 = sqrt(j4^2 - j1^2)/ppd;
  end
end
for j = 1:jmx
  if (sp(j) <= 16*sp1) && (sp(j+1) >= 16*sp1) % factor of 16 increase
     sp5 = sp(j);
     j5 = j;
     ecc5 = sqrt(j5^2 - j1^2)/ppd;
  end
end
px1 = round(ecc1*ppd); px2 = round(ecc2*ppd);
px3 = round(ecc3*ppd); px4 = round(ecc4*ppd);
px5 = round(ecc5*ppd);