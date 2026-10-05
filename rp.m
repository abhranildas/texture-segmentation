function dv = rp(patch1, patch2, noise_const, patch_size, win)
    %RP  Power difference decision variable from two windowed patches.
    %   dv = rp(patch1, patch2, noise_const, patch_size, win)
    %
    %   Windowed counterpart of VISLAB.NAT_STAT_BAYES.DV_POWER: each patch is
    %   multiplied by win before being mean-subtracted, Fourier transformed,
    %   and its power spectrum normalized to unit mean; noise_const is then
    %   added to suppress the contribution of near-zero spectral components.
    %   The returned measure is the mean over spatial frequencies of
    %   log((P1 + P2)^2 / (4 P1 P2)), which is zero when the two spectra agree
    %   and positive otherwise.
    %
    %   The math is exactly dv_power(patch1.*win, patch2.*win, noise_const,
    %   patch_size); only the order of the mean and sum reductions differs,
    %   which moves the result by about 1e-15 relative. Kept because
    %   tools/golden_harness.m checksums this function's exact output, and
    %   RS_NEW's error (Stage 4 item B3.13) is raised in here. Stage 3 item
    %   S2.3 (docs/repo-cleanup.md).
    %
    %   Inputs
    %     patch1      - first image patch, square, in gray levels.
    %     patch2      - second image patch, same size as patch1, in gray
    %                   levels.
    %     noise_const - noise suppression constant, added to each normalized
    %                   power spectrum; dimensionless, since the spectra are
    %                   normalized to unit mean.
    %     patch_size  - patch side length, in pixels.
    %     win         - window function applied to each patch before the
    %                   Fourier transform, same size as patch1/patch2 (see
    %                   MK_WIN).
    %
    %   Output
    %     dv - the power difference measure, in nats per pixel. Larger means
    %          more evidence the two patches differ.
    %
    %   See also VISLAB.NAT_STAT_BAYES.DV_POWER, MK_WIN, RS_NEW.

    % patch1
    patch1 = patch1.*win;
    patch1 = patch1 - mean(mean(patch1));
    ft_img = fftshift(fft2(fftshift(patch1)));      % fourier transform patch
    power1 = abs(ft_img).^2;
    power1 = power1/mean(mean(power1)) + noise_const;

    %   patch2
    patch2 = patch2.*win;
    patch2 = patch2 - mean(mean(patch2));
    ft_img = fftshift(fft2(fftshift(patch2)));       % fourier transform image
    power2 = abs(ft_img).^2;
    power2 = power2/mean(mean(power2)) + noise_const;

    % compute power difference measure
    power_num = (power1 + power2).^2;
    power_den = 4*power1.*power2;
    dv = sum(sum(log(power_num./power_den)))/patch_size^2;
end
