function [ptch,seed,tex_num,coords]=texture_patch(varargin)
% sample a patch from a Brodatz texture image

parser=inputParser;
parser.KeepUnmatched=true;
addParameter(parser,'tex_num','rand', @(x) isscalar(x) || strcmp(x,'rand'));
addParameter(parser,'patch_sz', [64 64]);
addParameter(parser,'seed','rand', @(x) isscalar(x) || strcmp(x,'rand'));
addParameter(parser,'lum', 0.5, @isscalar);
addParameter(parser,'cont', 0.2, @isscalar);
parse(parser,varargin{:});

% set rng seed
seed=parser.Results.seed;
if strcmp(seed,'rand')
    seed=randi(intmax);
end
rng('default')
rng(seed)

tex_num=parser.Results.tex_num;
if strcmp(tex_num,'rand')
    tex_num=randi(60);
end

patch_sz=parser.Results.patch_sz;
lum=parser.Results.lum;
cont=parser.Results.cont;

% sample the patch
img=imread(['global_data/textures/brodatz/B' num2str(tex_num) '.gif']);
img_sz=size(img,1);
x=randi(img_sz-patch_sz(1)); y=randi(img_sz-patch_sz(2));
ptch=double(img(x:x+patch_sz(1)-1,y:y+patch_sz(2)-1));
coords=[x,y];

% adjust lum and cont
ptch=(ptch-mean(ptch(:)))*lum*cont/std(ptch(:))+lum;

% compute percentage clipped
pClipped=lib.compute_pClipped(ptch);

if pClipped
    warning('Texture %d, %.1f%% clipped!',tex_num,100*pClipped)
end

