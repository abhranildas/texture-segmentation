% nat_near_far_patches_cnn.m
% sample texture image patch pairs from 16-bit linear rgb natural images and save
% near/far A-channel (achromatic) pairs to a single .mat file (loaded whole at train time)
%
psz = 64;
n_samp = 100;
same_max_dist = 1;
imgdir = '../vislab_data/CPS natural images/'; % 16-bit linear source images
ppd = 60; pd = 4; w = 550; % optics: pixels/deg, pupil diameter mm, wavelength nm
down_level = 1; % resolution scale-down (power of 2: 1,2,4,8) -- eccentricity model

% color transforms (shared calibration data in vislab_data): RGB -> LMS cone
% space (CPS camera calibration) then LMS -> ABR opponent space. We keep the
% A (achromatic) channel = LMS*coeff(:,1) -- the first ABR channel (per Bill).
% coeff is the LMS->ABR rotation from PCA on OTF-filtered natural images.
S = load('../vislab_data/cps_rgb2lms.mat','lms');       lms   = S.lms;    % 3x3 RGB->LMS
S = load('../vislab_data/cps_lms2abr_otf.mat','coeff'); coeff = S.coeff;  % 3x3 LMS->ABR

%% ===== TEMPORARY CHECK: grayscale mean vs A (achromatic) channel =====
% For one image, build both representations and show a few patches side by side
% (grayscale | A) so the color-transform difference is visible. Only needs the
% params + matrices above. Remove when done.
chk = double(imread([imgdir 'Set9_16_1.png']));
chk = chk*255/max(chk(:));
[hh,ww,~] = size(chk);
chk_gray = mean(chk,3);                                    % old grayscale mean
chk_A    = reshape(coeff(:,1)' * (lms * reshape(chk,[],3)'), hh, ww); % A channel
chk_gray = vislab.lib.otf_filter(chk_gray,ppd,pd,w);           % same optics as the pipeline
chk_A    = vislab.lib.otf_filter(chk_A,ppd,pd,w);
% normalize both to 0-255 so a shared display scale shows real tonal differences
chk_gray = chk_gray*255/max(chk_gray(:));
chk_A    = chk_A*255/max(chk_A(:));

n_chk = 6;
figure('Name','grayscale vs A channel');
tiledlayout(1,n_chk,'TileSpacing','compact','Padding','compact');
sep = 128*ones(psz,2);                                     % divider column
for j = 1:n_chk
    x = randi(hh-psz+1); y = randi(ww-psz+1);
    gp = chk_gray(x:x+psz-1, y:y+psz-1);
    ap = chk_A(x:x+psz-1, y:y+psz-1);
    nexttile; imshow([gp sep ap],[0 255]); title('grayscale | A');
end
% ===== end temporary check =====

set_nums=[9 10 12];
n_imgs=[104 90 197];

% flatten (set, image) into a single list so the per-image work can run in
% parfor (each image is independent and yields exactly n_samp near/far pairs)
set_list = repelem(set_nums,n_imgs);
img_list = [];
for i_set=1:3, img_list = [img_list 1:n_imgs(i_set)]; end %#ok<AGROW>
n_img = numel(set_list);

% per-image results collected in cells (parfor-sliced), concatenated after.
% each patch pair is [psz psz 2]: dim 3 holds the two patches (1 = reference,
% 2 = partner), kept separate rather than stitched. stored 8-bit (A/achromatic
% channel of the ABR transform).
nearC = cell(1,n_img);
farC  = cell(1,n_img);

parfor k = 1:n_img
    rng(k); % per-image seed: reproducible regardless of parfor execution order
    set_num = set_list(k); i_img = img_list(k);
    fprintf('Set%d img %d\n',set_num,i_img);

    % load rgb image and normalize so the max over the 3 channels is 255
    % (per-image, matching the Bayesian ingestion in the code docs). the
    % 16-bit linear values have no fixed ceiling, so scale by the image max
    name = [imgdir 'Set' num2str(set_num) '_16_' num2str(i_img) '.png'];
    img = double(imread(name));
    img = img*255/max(img(:));

    % achromatic (A) channel, matching the Bayesian model: RGB -> LMS cone
    % space -> A = LMS*coeff(:,1) (first ABR channel, per Bill). LMS = lms*RGB
    % per pixel (matrix rows are the L,M,S cone responses).
    [h,wd,~] = size(img);
    rgb = reshape(img,[],3)';           % 3 x N (pixels as columns)
    A = coeff(:,1)' * (lms * rgb);      % 1 x N : A = LMS*coeff(:,1), LMS = lms*RGB
    A = reshape(A,h,wd);                % H x W achromatic image
    % OTF is linear and commutes with the (linear) color transform, so filtering
    % A once == OTF each channel then converting (the Bayesian order)
    A = vislab.lib.otf_filter(A,ppd,pd,w);  % human optics, applied to the full image
    if down_level>1                     % eccentricity model: coarsen resolution
        A = vislab.lib.downsample(A,down_level);      % blur + shrink the whole image
        A = imresize(A,down_level,'nearest');     % upscale back so patches stay 64x64
    end
    A = A*255/max(A(:));                % scale to 0-255 for 8-bit (A>=0: coeff(:,1)>0, LMS>0)

    near_k = zeros(psz,psz,2,n_samp,'uint8');
    far_k  = zeros(psz,psz,2,n_samp,'uint8');
    for i = 1:n_samp
        % find near and far patch coords (always returns a valid set)
        coords = lib.find_nat_patch(A,psz,same_max_dist);

        % near pair -> separated along dim 3
        x_a = coords(1,1); y_a = coords(1,2);
        x_b = coords(2,1); y_b = coords(2,2);
        near_k(:,:,1,i)=uint8(A(x_a:x_a+psz-1,y_a:y_a+psz-1));
        near_k(:,:,2,i)=uint8(A(x_b:x_b+psz-1,y_b:y_b+psz-1));

        % far pair -> separated along dim 3
        x_a = coords(3,1); y_a = coords(3,2);
        x_b = coords(4,1); y_b = coords(4,2);
        far_k(:,:,1,i)=uint8(A(x_a:x_a+psz-1,y_a:y_a+psz-1));
        far_k(:,:,2,i)=uint8(A(x_b:x_b+psz-1,y_b:y_b+psz-1));
    end
    nearC{k} = near_k;
    farC{k}  = far_k;
end

near = cat(4,nearC{:});
far  = cat(4,farC{:});

% save all pairs to a single file. -v7.3 (HDF5) supports large arrays and
% allows lazy slicing via matfile() later if the set outgrows RAM
if ~exist('img_data/nat/','dir'); mkdir('img_data/nat/'); end
if down_level>1
    outfile = ['img_data/nat/patch_pairs_dsmpl_' num2str(down_level) '.mat'];
else
    outfile = 'img_data/nat/patch_pairs.mat';
end
save(outfile,'near','far','-v7.3')

%% show a few example near/far pairs (reference | partner)
n_show = 5;
i_near = randi(size(near,4),1,n_show);
i_far  = randi(size(far,4),1,n_show);
figure;
tiledlayout(2,n_show,'TileSpacing','compact','Padding','compact');
for j = 1:n_show
    nexttile; imshow([near(:,:,1,i_near(j)) near(:,:,2,i_near(j))],[]);
    title(sprintf('near #%d',i_near(j)));
end
for j = 1:n_show
    nexttile; imshow([far(:,:,1,i_far(j)) far(:,:,2,i_far(j))],[]);
    title(sprintf('far #%d',i_far(j)));
end
