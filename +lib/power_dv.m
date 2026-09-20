function dv = power_dv(patch_a, patch_b, noise_const)
% POWER_DV  Same/different decision variable from two patches' power spectra.
%   dv = lib.power_dv(patch_a, patch_b, noise_const)
%
%   Each patch is mean-subtracted, Fourier transformed, and its power spectrum
%   normalized to unit mean; noise_const is then added to suppress the
%   contribution of near-zero spectral components. The returned measure is the
%   mean over spatial frequencies of log((P1 + P2)^2 / (4 P1 P2)), which is
%   zero when the two spectra agree and positive otherwise.
%
%   Inputs
%     patch_a     - first image patch, square, in gray levels.
%     patch_b     - second image patch, same size as patch_a, in gray levels.
%     noise_const - noise suppression constant, added to each normalized power
%                   spectrum; dimensionless, since the spectra are normalized
%                   to unit mean (10 at the call site in
%                   +general/simulate_discrimination.m).
%
%   Output
%     dv - the power difference measure, in nats per pixel. Larger means more
%          evidence the two patches differ.
%
%   See also LIB.HIST_DV.

    patch_size = size(patch_a, 1);

    % patch a
    patch_a = patch_a - mean(mean(patch_a));
    patch_fft = fftshift(fft2(fftshift(patch_a)));  % fourier transform patch
    power1 = abs(patch_fft).^2;
    power1 = power1/mean(mean(power1)) + noise_const;

    % patch b
    patch_b = patch_b - mean(mean(patch_b));
    patch_fft = fftshift(fft2(fftshift(patch_b)));  % fourier transform patch
    power2 = abs(patch_fft).^2;
    power2 = power2/mean(mean(power2)) + noise_const;

    % compute power difference measure
    power_num = (power1 + power2).^2;
    power_den = 4*power1.*power2;
    dv = sum(sum(log(power_num./power_den)))/patch_size^2;
end
