function [sig_1f, wn] = create_pink_noise_line(n_samples, exponent)
% CREATE_PINK_NOISE_LINE  Generate a 1-D 1/f (pink) noise signal.
%   [sig_1f, wn] = lib.create_pink_noise_line(n_samples, exponent)
%
%   White Gaussian noise is Fourier transformed, multiplied by a radially
%   symmetric 1/f filter, and transformed back.
%
%   Inputs
%     n_samples - length of the signal, a count of samples (not pixels or
%                 degrees).
%     exponent  - exponent of the 1/f filter, dimensionless. Note: the guard
%                 below tests for a variable named 'alpha', which never
%                 exists, so this argument is currently overwritten with 1 on
%                 every call. Recorded as a bug; not fixed here.
%
%   Output
%     sig_1f - the pink-noise signal, 1-by-n_samples. The 1/f filter is even,
%              so the result is real up to rounding error, but ifft returns it
%              as a complex array.
%     wn     - the underlying white-noise signal it was filtered from,
%              1-by-n_samples, standard normal.
%
%   See also LIB.TARGET_MASK.

    if ~exist('alpha', 'var')
        exponent = 1;
    end

    % create 1/f Fourier filter.
    fil_1f = ones(1, n_samples);
    for i_sample = 1:n_samples
        sqrt_dist = sqrt(norm(i_sample - n_samples/2 - 1));
        if sqrt_dist  % leave fft origin at 1
            fil_1f(i_sample) = sqrt_dist^(-exponent);
        end
    end

    % white noise signal:
    wn = normrnd(0, 1, [1 n_samples]);

    % Fourier transform image, then fftshift to shift 0-frequency
    % to the center of the image, to align with 1/f filter whose
    % 0-frequency is also at the center. Otherwise multiplying
    % them together will not multiply corresponding elements.
    wnf = fftshift(fft(wn));

    % multiply with 1/f filter
    wnf_fil = fil_1f .* wnf;

    % ifftshift to first shift back the fourier transform
    % to have 0-frequency at the start again. This lets
    % ifft do the inverse Fourier transform correctly:
    sig_1f = ifft(ifftshift(wnf_fil));
end
