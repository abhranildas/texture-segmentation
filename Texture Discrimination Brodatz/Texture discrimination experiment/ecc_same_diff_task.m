%
% find eccentricities for same-different task
%
clear all;
jmx = 1200;
i = 0;
fx = 0; fy = 0; scl = 1; ppd = 60;
sp = zeros(jmx,1);
for j = 1:jmx
  sp(j) = sp_pix(i,j,fy,fx,scl,ppd);
end
j1 = 40;
sp1 =sp(j1);
ecc1 = 0;
for j = 1:jmx
  if (sp(j) <= 2*sp1) && (sp(j+1) >= 2*sp1)
     sp2 = sp(j);
     j2 = j;
     ecc2 = sqrt(j2^2 - 40^2)/ppd;
  end
end
for j = 1:jmx
  if (sp(j) <= 4*sp1) && (sp(j+1) >= 4*sp1)
     sp3 = sp(j);
     j3 = j;
     ecc3 = sqrt(j3^2 - 40^2)/ppd;
  end
end
sptar = 5*sp1;
for j = 1:jmx
  if (sp(j) <= 6*sp1) && (sp(j+1) >= 6*sp1)
     sp4 = sp(j);
     j4 = j;
     ecc4 = sqrt(j4^2 - 40^2)/ppd;
  end
end
px1 = round(ecc1*ppd); px2 = round(ecc2*ppd);
px3 = round(ecc3*ppd); px4 = round(ecc4*ppd);