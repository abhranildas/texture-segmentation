%
% scaled multinomial distribution
%
% d = uniform delta range around 1
% p = bin probability
% dd = delta d
clearvars; close all;
n = 64^2;
pmax = 0.2;
nstp = 40;
dp = pmax/nstp;
p = zeros(nstp,1);
mvar = zeros(nstp,1);
pvar = zeros(nstp,1);
figure; hold on;
for d = 0.05:0.1:0.45
  for i = 1:nstp
    p(i) = i*dp;
    evn = (n*p(i)/(2*d))*((1+d)^2 - (1-d)^2)/2 - (n*p(i)^2/(2*d))...
          *((1+d)^3 - (1-d)^3)/3;
    ven = ((2*d*n*p(i))^2)/12;
    mvar(i) = ven + evn;
    pvar(i) = n*p(i)*(1-p(i));
  end
  % scatter(n*p,mvar);
  scatter(mvar,pvar);
end
axis equal; xlim([10 10^5]); ylim([10 10^5]);
set(gca,'yscale','log');
set(gca,'xscale','log');