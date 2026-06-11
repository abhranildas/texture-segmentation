function bindex = mk_bindex(bbdist,bbmecc,bbdecc)
%
% create bindex array where the value varies from 1 to nbin where the
% coordinates of the array are the bin numbers for the three sets of bin
% bounds bbdist, bbmecc, bbdecc
%
ndist = size(bbdist,2)-1; nmecc = size(bbmecc,2)-1;
ndecc = size(bbdecc,2)-1;
%
bindex = zeros(ndist,nmecc,ndecc);
indx = 0;
for i = 1:ndist
  for j = 1:nmecc
    for k = 1:ndecc
       indx = indx + 1;
       bindex(i,j,k) = indx;
    end
  end
end
%
end