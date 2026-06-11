function nls = nlsame(lnka,nlnka,lnkb,nlnkb)
%
% find how many links are in common for two linked patches
nls = 0;
for i = 1:nlnka
 for j = 1:nlnkb
  if lnka(i) == lnkb(j)
    nls = nls+1;
  end
 end
end
end

