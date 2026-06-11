function bin = fnd_bin(i0,j0,dist,mecc,decc,bbdist,bbmecc,bbdecc,bindex)
%
% find the geometry bin for a given pair of patch locations
%
ndist = size(bbdist,2)-1; nmecc = size(bbmecc,2)-1;
ndecc = size(bbdecc,2)-1;
d = dist(i0,j0);
me = mecc(i0,j0);
de = decc(i0,j0);
id = 0;
for i = 1:ndist
  if d >= bbdist(i)  && d <= bbdist(i+1)
    id = i;
  end
end
for i = 1:nmecc
  if me >= bbmecc(i)  && me <= bbmecc(i+1)
    ime = i;
  end
end
for i = 1:ndecc
  if de >= bbdecc(i)  && de <= bbdecc(i+1)
    ide = i;
  end
end
if id == 0
  err = 1;
end
bin = bindex(id,ime,ide);
%
end