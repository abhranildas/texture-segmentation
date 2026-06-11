function [rthresh] = thresh(rsp,sz,th)
rthresh = zeros(sz,sz);
for i = 1:sz
 for j = 1:sz
  if rsp(i,j) > th
   rthresh(i,j) = 1;
  end
  if i == j
   rthresh(i,j) = 1;
  end
 end
end
end

