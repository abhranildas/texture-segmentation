function [patch_img, seed, tex_num, coords] = texture_patch(varargin)
% TEXTURE_PATCH  Sample a patch at a random location from a Brodatz texture.
%   [patch_img, seed, tex_num, coords] = lib.texture_patch(...)
%
%   Reads one of the 60 Brodatz texture images shipped in the sibling
%   vislab-common repo, cuts a patch from a random location in it, and rescales
%   it to the requested mean luminance and contrast. The seed and texture
%   number actually used are returned, so the same patch can be redrawn.
%
%   Name-value inputs
%     'tex_num'  - Brodatz texture number, 1 to 60, or 'rand' to draw one
%                  (default 'rand').
%     'patch_sz' - patch size in pixels, [rows cols] (default [64 64]).
%     'seed'     - RNG seed, or 'rand' to draw one (default 'rand').
%     'lum'      - mean luminance of the returned patch, in normalized units
%                  where 0 is black and 1 is white (default 0.5).
%     'cont'     - RMS contrast, as a fraction of the mean luminance
%                  (default 0.2).
%
%   Outputs
%     patch_img - the sampled patch, patch_sz pixels, in normalized luminance
%                 units. May fall outside [0, 1]; the fraction that does is
%                 warned about.
%     seed      - the RNG seed used, so the draw can be repeated.
%     tex_num   - the Brodatz texture number used, 1 to 60.
%     coords    - [row col] of the patch's top-left corner in the source
%                 image, in pixels.
%
%   See also LIB.COMPUTE_P_CLIPPED.

    parser = inputParser;
    parser.KeepUnmatched = true;
    addParameter(parser, 'tex_num', 'rand', @(x) isscalar(x) || strcmp(x, 'rand'));
    addParameter(parser, 'patch_sz', [64 64]);
    addParameter(parser, 'seed', 'rand', @(x) isscalar(x) || strcmp(x, 'rand'));
    addParameter(parser, 'lum', 0.5, @isscalar);
    addParameter(parser, 'cont', 0.2, @isscalar);
    parse(parser, varargin{:});

    % set rng seed
    seed = parser.Results.seed;
    if strcmp(seed, 'rand')
        seed = randi(intmax);
    end
    rng('default')
    rng(seed)

    tex_num = parser.Results.tex_num;
    if strcmp(tex_num, 'rand')
        tex_num = randi(60);
    end

    patch_sz = parser.Results.patch_sz;
    lum = parser.Results.lum;
    cont = parser.Results.cont;

    % sample the patch
    img = imread(['vislab-common/data/textures/brodatz/B' num2str(tex_num) '.gif']);
    img_size = size(img, 1);
    x = randi(img_size - patch_sz(1));
    y = randi(img_size - patch_sz(2));
    patch_img = double(img(x:x+patch_sz(1)-1, y:y+patch_sz(2)-1));
    coords = [x, y];

    % adjust lum and cont
    patch_img = (patch_img - mean(patch_img(:)))*lum*cont/std(patch_img(:)) + lum;

    % compute fraction clipped
    p_clipped = lib.compute_p_clipped(patch_img);

    if p_clipped
        warning('Texture %d, %.1f%% clipped!', tex_num, 100*p_clipped)
    end
end
