function A_pool = load_nat_A_pool(imgdir, set_nums, n_imgs, ppd, pd, w, down_level)
% LOAD_NAT_A_POOL  Build the pool of achromatic (A) images once.
%   A_POOL = load_nat_A_pool(IMGDIR, SET_NUMS, N_IMGS, PPD, PD, W, DOWN_LEVEL)
%   processes every source image listed by SET_NUMS/N_IMGS into its achromatic
%   (A) channel and returns them as a cell array of uint8 images, one per source
%   image.
%
%   This is the expensive, one-time step for on-the-fly training: it runs at the
%   start of training, after which getTwinBatch_nat_live cuts fresh patches out of
%   this pool cheaply (just random coordinates + indexing), so patch pairs never
%   repeat and there is nothing for the network to memorize.
%
%   Inputs mirror the settings at the top of general.nat_near_far_patches_cnn:
%     IMGDIR     folder holding the Set*_16_*.png source images (with trailing sep)
%     SET_NUMS   image-set numbers, e.g. [9 10 12]
%     N_IMGS     number of images in each set, e.g. [104 90 197]
%     PPD,PD,W   optics parameters passed through to general.nat_image_to_A
%     DOWN_LEVEL resolution scale-down passed through to general.nat_image_to_A
%
%   Output:
%     A_POOL     1 x n_img cell array; A_POOL{k} is a uint8 achromatic image

    % flatten (set, image) into a single list, exactly as the offline generator does
    set_list = repelem(set_nums, n_imgs);
    img_list = [];
    for i_set = 1:numel(set_nums)
        img_list = [img_list 1:n_imgs(i_set)]; %#ok<AGROW>
    end
    n_img = numel(set_list);

    A_pool = cell(1, n_img);
    parfor k = 1:n_img
        name = [imgdir 'Set' num2str(set_list(k)) '_16_' num2str(img_list(k)) '.png'];
        A_pool{k} = general.nat_image_to_A(name, ppd, pd, w, down_level);
    end
end
