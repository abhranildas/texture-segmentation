% mk_patches.m
% sample texture image patches from 16-bit linear rgb natural images
%
rng(0)
% rng('shuffle');
% nimg = 391; % 391
n_samp = 100;
psz = 64;
same_max_dist = 1;
same_max_col = 1;
diff_min_dist = 500;
diff_min_col = 50;
% nptch = nimg*n_samp*3;
% patches = zeros(nptch,psz,psz,3);
dirname='img_data/nat/patches/';
files = dir(fullfile([dirname 'same/'], '*.png'));
i_patch = 1; %numel(files)+1;

set_nums=[9 10 12];
n_imgs=[104 90 197];
coords=nan;
for i_set=1:3
    set_num=set_nums(i_set);

    for i_img = 1:n_imgs(i_set)
        % load rgb image
        name = ['img_data/nat/imgs/Set' num2str(set_num) '_16_',num2str(i_img),'.png'];
        img=imread(name);
        imgrgb = double(img)*255/(2^16-1);
        imglab = rgb2lab(imgrgb,'colorspace','linear-rgb','WhitePoint','d65');
        for i = 1:n_samp
            [set_num i_img i]

            % find same and diff patch coords
            coords = lib.find_nat_patch(imglab,psz,same_max_dist,same_max_col,diff_min_dist,diff_min_col);
            if any(isnan(coords(:))) % if a same or different pair could not be found,
                'skip'
                continue    % skip this sample
            end

            % same pair
            x_a = coords(1,1); y_a = coords(1,2);
            patch_a=img(x_a:x_a+psz-1,y_a:y_a+psz-1,1:3);
%             patch_a=uint8(double(patch_a)/double(max(patch_a(:)))*255);

            x_b = coords(2,1); y_b = coords(2,2);
            patch_b=img(x_b:x_b+psz-1,y_b:y_b+psz-1,1:3);
%             patch_b=uint8(double(patch_b)/double(max(patch_b(:)))*255);

            patch_pair=cat(2,patch_a,patch_b);
            % save as image:
            imwrite(patch_pair,[dirname 'same/' num2str(i_patch) '.png'])

            % diff pair
            x_a = coords(3,1); y_a = coords(3,2);
            patch_a=img(x_a:x_a+psz-1,y_a:y_a+psz-1,1:3);
%             patch_a=uint8(double(patch_a)/double(max(patch_a(:)))*255);

            x_b = coords(4,1); y_b = coords(4,2);
            patch_b=img(x_b:x_b+psz-1,y_b:y_b+psz-1,1:3);
%             patch_b=uint8(double(patch_b)/double(max(patch_b(:)))*255);

            patch_pair=cat(2,patch_a,patch_b);
            % save as image:
            imwrite(patch_pair,[dirname 'diff/' num2str(i_patch) '.png'])

            i_patch = i_patch + 1;
        end
    end
end