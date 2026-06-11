function flg = chk_xy(x,y,trl,maps,sz)
%
% find a location that is not a boundary location
%
% x,y = location
% trl = trial number
% maps = map of region numbers for each trial number
% sz = size map
%
% flg = 1 boundary, flg = 0 not boundary 
%
rnum = maps(x,y,trl);
flg = 0;
if x < sz
  if maps(x+1,y,trl) ~= rnum
    flg = 1;
  end
end
if y < sz
  if maps(x,y+1,trl) ~= rnum
    flg = 1;
  end
end
if x < sz && y < sz
  if maps(x+1,y+1,trl) ~= rnum
    flg = 1;
  end
end
if x > 1
  if maps(x-1,y,trl) ~= rnum
    flg = 1;
  end
end
if y > 1
  if maps(x,y-1,trl) ~= rnum
    flg = 1;
  end
end
if x > 1 && y > 1
  if maps(x-1,y-1,trl) ~= rnum
    flg = 1;
  end
end
if x > 1 && y < sz
  if maps(x-1,y+1,trl) ~= rnum
    flg = 1;
  end
end
if x < sz && y > 1
  if maps(x+1,y-1,trl) ~= rnum
    flg = 1;
  end
end
%
end