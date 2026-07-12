function A = nat_image_to_A(name, ppd, pd, w, down_level)
% NAT_IMAGE_TO_A  Process one natural image into its achromatic (A) channel.
%   A = nat_image_to_A(NAME, PPD, PD, W, DOWN_LEVEL) reads the 16-bit linear RGB
%   image at path NAME and returns its achromatic (A) channel as a uint8 image
%   scaled to 0-255.
%
%   This is the expensive, once-per-image step shared by two callers:
%     * general.nat_near_far_patches_cnn  (offline: pre-generates a fixed set of
%       near/far patch pairs and saves them to a .mat file)
%     * getTwinBatch_nat_live             (on-the-fly: cuts fresh patches from the
%       pool of A images during training, so pairs never repeat)
%   Keeping the processing in one place stops the two callers from drifting apart.
%
%   Inputs:
%     NAME       full path to a Set*_16_*.png source image
%     PPD        pixels per degree (optics)
%     PD         pupil diameter, mm (optics)
%     W          wavelength, nm (optics)
%     DOWN_LEVEL resolution scale-down (power of 2: 1,2,4,8); 1 = full resolution
%
%   Steps (identical to the inline code this replaced in nat_near_far_patches_cnn):
%     1. read, and scale so the max over the 3 channels is 255 (per-image)
%     2. RGB -> LMS cone space (vislab.lib.rgb2lms)
%     3. LMS -> ABR opponent space (vislab.nat_stat_bayes.apply_color_rotation),
%        keep channel 1 = achromatic (A), per Bill
%     4. human optics OTF filter (vislab.lib.otf_filter) on the full image; the OTF
%        is linear and commutes with the linear colour transform, so filtering A
%        once equals filtering each channel then converting (the Bayesian order)
%     5. optional eccentricity model: blur+shrink then upscale back so patches stay
%        the same pixel size
%     6. scale to 0-255 and cast to uint8

    % load rgb image and normalize so the max over the 3 channels is 255
    % (16-bit linear values have no fixed ceiling, so scale by the image max)
    img = double(imread(name));
    img = img*255/max(img(:));

    % achromatic (A) channel via the shared vislab colour transforms
    img_abr = vislab.nat_stat_bayes.apply_color_rotation(vislab.lib.rgb2lms(img)); % H x W x 3 ABR
    A = img_abr(:,:,1);                                       % achromatic channel

    % human optics, applied to the full image
    A = vislab.lib.otf_filter(A,ppd,pd,w);

    if down_level>1                     % eccentricity model: coarsen resolution
        A = vislab.lib.downsample(A,down_level);  % blur + shrink the whole image
        A = imresize(A,down_level,'nearest');     % upscale back so patches stay 64x64
    end

    A = A*255/max(A(:));                % scale to 0-255 (A>=0: LMS clipped >=0, A-axis weights >0)
    A = uint8(A);
end
