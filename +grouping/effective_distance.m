%
% compute effective distance
%
n = 16;
dmx = sqrt(2*(n-1)^2);
ed = zeros(n,n);
for i = 1:n
  for j = i+1:n
    if a(i,j) > 0
      dmn = d(i,j);
      for k = i+1:n
        for l = k+1:n
          if abs(i,l) > 0
           if d(k,l) < dmn
             dmn = d(i,l);
           end
          end
        end
      end
      ed(i,j) = dmn;
    end
  end
end
