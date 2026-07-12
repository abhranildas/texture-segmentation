function A = texture_image_to_A(file, is_gray, is_gamma, resize_pertex, ppd, pd, w, down_level)
% TEXTURE_IMAGE_TO_A  Process one texture sheet into its achromatic (A) channel.
%   A = texture_image_to_A(FILE, IS_GRAY, IS_GAMMA, RESIZE_PERTEX, PPD, PD, W, DOWN_LEVEL)
%   returns the achromatic (A) channel as a uint8 image scaled to 0-255.
%
%   Mirrors the Bayesian texture ingestion in texture-learning's load_texture_images.m
%   (resize pertex 1024->640, grayscale-replicate, gamma-linearize, eye optics OTF,
%   RGB->LMS) and then extracts the achromatic channel the same way the natural-image
%   patches do (LMS->ABR via apply_color_rotation, keep channel 1), so the CNN's texture
%   TEST patches are processed consistently with its natural-image TRAINING patches
%   (see general.nat_image_to_A).
%
%   Per-database flags (from load_texture_images.m):
%     IS_GRAY       grayscale sheet -> replicate to 3 channels (brodatz, pertex)
%     IS_GAMMA      gamma-compressed sheet -> linearize (fabric, mcgill, vistex)
%     RESIZE_PERTEX pertex source PNGs are 1024x1024 -> resize to 640 (Bill's sheet)
%   Optics/scale:
%     PPD           pixels per degree for the OTF (60 for texture sheets)
%     PD, W         pupil diameter (mm), wavelength (nm)
%     DOWN_LEVEL    resolution scale-down (power of 2); 1 = full resolution

    raw = double(imread(file));

    if resize_pertex                       % reproduce Bill's 1024->640 sheet (round, uint8)
        raw = double(uint8(round(imresize(raw, 640/1024))));
    end

    if is_gray                             % grayscale sheet -> 3 equal channels
        cimg = repmat(raw(:,:,1), 1, 1, 3);
    else
        cimg = raw;
    end

    if is_gamma                            % linearize gamma-compressed sheets
        cimg = vislab.lib.gamma_expand(cimg);
    end

    % eye optics on RGB (linear, so it commutes with the RGB->LMS->ABR transforms below)
    cimg = vislab.lib.otf_filter(cimg, ppd, pd, w);

    % RGB -> LMS -> ABR, keep the achromatic (A) channel (same as nat_image_to_A)
    abr = vislab.nat_stat_bayes.apply_color_rotation(vislab.lib.rgb2lms(cimg));
    A = abr(:,:,1);

    if down_level > 1                      % eccentricity model: coarsen, then restore size
        A = vislab.lib.downsample(A, down_level);
        A = imresize(A, down_level, 'nearest');
    end

    A = A*255/max(A(:));                    % scale to 0-255 for 8-bit storage
    A = uint8(A);
end
