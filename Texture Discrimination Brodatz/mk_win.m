function win = mk_win(sz,r,shp)
% make raised-cosine-boundray window
win = zeros(sz,sz); win1 = zeros(sz,1);
ij0 = sz/2+0.5;
if shp == 1
  for i = 1:sz
    for j = 1:sz
      z = sqrt((i-ij0)^2 + (j-ij0)^2);
      if z <= r
        win(i,j) = 1;
      elseif z <= sz/2
        win(i,j) = 0.5*(cos(pi*(z-r)/(sz/2-r))+1);
      end
    end
  end
elseif shp == 2
  for i = 1:sz
    z = abs(i-ij0);
    if z <= r
      win1(i) = 1;
    else
      win1(i) = 0.5*(cos(pi*(z-r)/(sz/2-r))+1);
    end   
  end
  for j = 1:sz
    win(:,j) = win1;
  end
  for i = 1:sz
    win(i,:) = win(i,:).*win1.';
  end
end  
end

