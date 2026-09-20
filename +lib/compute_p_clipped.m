function p_clipped = compute_p_clipped(stim)
% COMPUTE_P_CLIPPED  Fraction of an image's pixels that fall outside [0, 1].
%   p_clipped = lib.compute_p_clipped(stim)
%
%   Inputs
%     stim - image or patch, in normalized luminance units where 0 is black
%            and 1 is white (any size).
%
%   Output
%     p_clipped - fraction of elements below 0 or above 1; dimensionless,
%                 in [0, 1]. (The original comment called this a percentage;
%                 the arithmetic returns a fraction.)
%
%   See also LIB.TEXTURE_PATCH.

    p_clipped = (sum(stim(:) < 0) + sum(stim(:) > 1)) / numel(stim);
end
