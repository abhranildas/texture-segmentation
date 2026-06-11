function imgout = aply_otf(imgin,ppd,pd,w)
%
% apply otf to image
%
% imgin = input image (assumes even size, and width = height)
% ppd = pixels per degree
% pd = puil diameter
% w = wavelength
% 
sz = size(imgin,2); fscl = ppd/sz;
imgmn = mean(mean(imgin));
imgin = imgin - imgmn;
ftimg = fftshift(fft2(fftshift(imgin)));      % fourier transform patch
ij0 = sz/2+1;
for i = 1:sz
  for j = 1:sz
    u = sqrt((i-ij0)^2 + (j-ij0)^2)*fscl;
    ftimg(i,j) = ftimg(i,j)*otf(u,pd,w);
  end
end
imgout = ifftshift(ifft2(ifftshift(ftimg)));  % inverse fourier transform
imgout = imgout + imgmn;
end