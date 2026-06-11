function [ffil] = mk_fourier_fil(hw,type,nex)
%
% creates a Fourier filter
%
% hw = half filter width
% type = the type of filter (e.g., 1/f, Gaussian, etc.)
% nex = exponent of falloff: 1/f^nex
%

sz = 2*hw;                         % even size
ffil = zeros(sz,sz);
%
if type == 1                       % 1/f filter
  for i=1:sz
    for j=1:sz
      z = double((i-hw-1)^2 + (j-hw-1)^2);
      z = z^0.5;
    if (i == hw+1) && (j == hw+1)  % fft origin
      ffil(i,j) = 0;
    else
      ffil(i,j) = 1/z^nex;
    end
    end
  end
%  
elseif type == 2                    % empty
end
%
end

