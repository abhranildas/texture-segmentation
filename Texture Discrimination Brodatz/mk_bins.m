function eg = mk_bins(e,N,nbin)
%
% make bin edges from cdf
%
[~,ncdf] = size(e);
ne = 1;
eg = zeros(1,nbin+1);
pstp = 1/nbin;
p = pstp;
for i = 1:ncdf-2
  if (N(i) < p) && (N(i+1) > p)
    ne = ne + 1;
    eg(ne) = e(i);
    p = p + pstp;
  end
end
eg(nbin+1) = inf;
eg(1) = -inf;
%
end