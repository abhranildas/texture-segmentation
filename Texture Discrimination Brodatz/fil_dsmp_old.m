function imgout = fil_dsmp(imgin,pd,w,lev,filter)
%
% filter and downsample grayscale image
%
% imgin = input image (double)
% pd = pupil diameter (mm)
% w = wavelength (nm)
% lev = power of two of downsampling (0, 2, 4, 8, 16)
% filter = 1 then apply optical filter
%
% apply otf
sz = size(imgin,2); sclu = 60/640;
%
% apply 3 x x gaussian kernals and downsample
kern = [1/16 1/8 1/16; 1/8 1/4 1/8; 1/16 1/8 1/16];
if lev >= 1 % no downsample
  if filter == 1
    imgmn = mean(mean(imgin));
    imgin = imgin - imgmn;
    ftimg = fftshift(fft2(fftshift(imgin)));      % fourier transform patch
    ij0 = sz/2+1;
    for i = 1:sz
      for j = 1:sz
        u = sqrt((i-ij0)^2 + (j-ij0)^2)*sclu;
        ftimg(i,j) = ftimg(i,j)*otf(u,pd,w);
      end
    end
    imgout = ifftshift(ifft2(ifftshift(ftimg)));  % inverse fourier transform
    imgout = imgout + imgmn;
  else
    imgout = imgin;
  end
end
%
if lev >= 2 % factor of 2
  imgout = conv2(imgout,kern,'same');    
  imgout = imresize(imgout,0.5,'nearest');
end
%
if lev >= 4 % factor of 4
  imgout = conv2(imgout,kern,'same');
  imgout = imresize(imgout,0.5,'nearest');  
end
%
if lev >= 8 % factor of 8
  imgout = conv2(imgout,kern,'same');
  imgout = imresize(imgout,0.5,'nearest');  
end
%
if lev >= 16 % factor of 16
  imgout = conv2(imgout,kern,'same');
  imgout = imresize(imgout,0.5,'nearest');  
end
%
end
