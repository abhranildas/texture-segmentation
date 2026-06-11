function [backgi] = mk_back(hw,n,p1,p2,p3,p4,type,img)
% make a set of 8-bit or double background images
%
% sz = size of images
% n = number of images
% p1,p2,p3,p4 = parameters
% type = type of background (e.g., white noise, 1/f noise, etc.)
% input image (only for type = 3)
%
sz = 2*hw;                       % even image size
backgi = zeros(sz,sz,n);         % storage for background images
bmin = zeros(sz,sz);  bmax = ones(sz,sz)*255;
%
% gaussian white noise; p1 = amplitude, p2 = mean; p3 = integer or real 
if type == 1
  for i = 1:n  
    backg = p1*randn(sz,sz) + p2;
    if p3 == 0
      backg = round(backg);
      backg = max(backg,bmin);
      backg = min(backg,bmax);
    end
    backgi(:,:,i) = backg;
  end
%
% gaussian 1/f noise; p1 = amplitude, p2 = mean; p3 = integer or real
% p4 = exponent
elseif type == 2
  fil1f = mk_fourier_fil(hw,1,p4);
  for i = 1:n
    wnoise = rand(sz,sz); %wnoise = randn(sz,sz);
    ftim = fftshift(fft2(fftshift(wnoise)));    % fourier transform image
    ftim = fil1f.*ftim;                         % apply fourier filter
    iftim = ifftshift(ifft2(ifftshift(ftim)));  % inverse fourier transform
    mif = mean(mean(iftim));                    % mean of iftim
    sd = sqrt( mean(mean(iftim.*iftim)) - mif^2 );
    backg = (iftim-mif)*p1/sd + p2;
    if p3 == 0
      backg = round(backg);
      backg = max(backg,bmin);
      backg = min(backg,bmax);
    end
    backgi(:,:,i) = backg;
  end
%
% phase scrambled image
elseif type == 3
  fimg = fftshift(fft2(fftshift(img)));    % fourier transform image
  aimg = abs(fimg);                        % amplitude spectrum of image
  for i = 1:n
    wnoise = rand(sz,sz); %wnoise = randn(sz,sz);
    ftim = fftshift(fft2(fftshift(wnoise)));    % fourier transform noise
    atim = abs(ftim);
    ftim = (ftim.*aimg)./atim;                  % set amplitude spectrum
    iftim = ifftshift(ifft2(ifftshift(ftim)));  % inverse fourier transform
    backg = iftim;
    if p3 == 0
      backg = round(backg);
      backg = max(backg,bmin);
      backg = min(backg,bmax);
    end
    backgi(:,:,i) = backg;
  end
end
%
end

