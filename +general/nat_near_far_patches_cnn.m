% nat_near_far_patches_cnn.m
% sample texture image patch pairs from 16-bit linear rgb natural images and save
% near/far A-channel (achromatic) pairs to a single .mat file (loaded whole at train time)
%
% NOT used by cnn/train_cnn.m, which now samples near/far pairs on the fly (see
% getTwinBatch_nat_live.m + load_nat_A_pool.m) so pairs never repeat. This script is
% kept as a standalone tool for offline inspection/regeneration of a fixed pair set.
%
psz = 64;
n_samp = 100;
same_max_dist = 1;
imgdir = '../vislab-common/data/CPS natural images/'; % 16-bit linear source images
ppd = 60; pd = 4; w = 550; % optics: pixels/deg, pupil diameter mm, wavelength nm
down_level = 1; % resolution scale-down (power of 2: 1,2,4,8) -- eccentricity model

% color transforms (shared calibration data in vislab-common/data): RGB -> LMS cone
% space (CPS camera calibration) then LMS -> ABR opponent space. We keep the
% A (achromatic) channel = first ABR channel (per Bill). Both colour transforms
% (RGB->LMS and LMS->ABR) come from the shared vislab functions, which auto-load the
% lab-global calibration/rotation -- no matrices are loaded here.

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

    % process this image into its achromatic (A) channel (uint8, 0-255) via the
    % shared helper -- the same routine the on-the-fly training sampler uses, so
    % the two paths stay identical (see cnn_architecture_plan.md item 10)
    name = [imgdir 'Set' num2str(set_num) '_16_' num2str(i_img) '.png'];
    A = general.nat_image_to_A(name,ppd,pd,w,down_level);

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
if ~exist('data/stimuli/nat/','dir'); mkdir('data/stimuli/nat/'); end
if down_level>1
    outfile = ['data/stimuli/nat/patch_pairs_dsmpl_' num2str(down_level) '.mat'];
else
    outfile = 'data/stimuli/nat/patch_pairs.mat';
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
