function Rpout = power_dv(patch_a,patch_b,b)
% power difference response
%
% ptch1 & ptch2 = two patches that are compared
% b = noise suppression constant
%
patch_sz=size(patch_a,1);

% ptch1
patch_a = patch_a - mean(mean(patch_a));
ftim = fftshift(fft2(fftshift(patch_a)));      % fourier transform patch
pim1 = abs(ftim).^2;
pim1 = pim1/mean(mean(pim1)) + b;
%
%   ptch2
patch_b = patch_b - mean(mean(patch_b));
ftim = fftshift(fft2(fftshift(patch_b)));       % fourier transform image
pim2 = abs(ftim).^2;
pim2 = pim2/mean(mean(pim2)) + b;
%
% compute power difference measure
pnum = (pim1 + pim2).^2;
pden = 4*pim1.*pim2;
Rpout = sum(sum(log(pnum./pden)))/patch_sz^2;
%
end

