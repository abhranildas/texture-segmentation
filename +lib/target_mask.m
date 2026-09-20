function [mask, mask_edge, target_normal, bd_strip, mask_center, ...
    target_radius] = target_mask(varargin)
% TARGET_MASK  Build a target region mask, its boundary, and its normals.
%   [mask, mask_edge, target_normal, bd_strip, mask_center, target_radius] = ...
%       lib.target_mask(...)
%
%   The target is either a circle or a closed blob whose radius varies with
%   angle as 1/f noise (LIB.CREATE_PINK_NOISE_LINE). Besides the mask itself,
%   this returns the one-pixel boundary, the outward normal at each pixel, and
%   a thicker boundary ribbon the width of a steerable kernel — the ribbon is
%   what LIB.EDGE_PROPS_STIM uses to separate boundary from texture.
%
%   Name-value inputs
%     'bg_size'            - side of the square background, in pixels; must be
%                            even, or the blob branch returns complex numbers
%                            (default 256).
%     'target_shape'       - 'circular', or a numeric 1/f exponent for the
%                            blob branch, where the number is passed to
%                            LIB.CREATE_PINK_NOISE_LINE as its exponent
%                            (default 'circular').
%     'target_radius'      - target radius in pixels (default 64).
%     'target_radius_cont' - for the blob branch, the standard deviation of
%                            the radius as a fraction of target_radius
%                            (default 0.15).
%     'target_loc'         - target center as [row col] in pixels, or 'center'
%                            (default 'center').
%     'kernel_size'        - [kernel_sd kernel_nsd] for LIB.STEERABLE_GRAD, in
%                            pixels and in counts of standard deviations,
%                            setting how wide the boundary ribbon comes out
%                            (default [1 3]).
%
%   Outputs
%     mask          - bg_size-by-bg_size logical, true inside the target.
%     mask_edge     - logical, true on the one-pixel boundary of the target
%                     (the image's own outer row/column are forced false).
%     target_normal - bg_size-by-bg_size-by-2 unit vectors normal to the
%                     boundary, dimensionless. For a circular target these are
%                     filled in at every interior pixel; for a blob they are
%                     nonzero only on mask_edge.
%     bd_strip      - logical boundary ribbon, one steerable-kernel width
%                     thick.
%     mask_center   - the target center actually used, [row col] in pixels.
%     target_radius - the target radius actually used, in pixels.
%
%   See also LIB.CREATE_PINK_NOISE_LINE, LIB.STEERABLE_GRAD,
%   LIB.EDGE_PROPS_STIM.

    parser = inputParser;
    parser.KeepUnmatched = true;
    % bg_size needs to be even, otherwise you get complex numbers.
    addParameter(parser, 'bg_size', 256, @(x) isscalar(x) && ~mod(x, 2));
    % addParameter(parser,'seed','rand', @(x) isscalar(x) || strcmp(x,'rand'));
    addParameter(parser, 'target_shape', 'circular', @(x) strcmp(x, 'circular') || isscalar(x));
    addParameter(parser, 'target_radius', 64, @isnumeric);
    addParameter(parser, 'target_radius_cont', .15, @isnumeric);
    addParameter(parser, 'target_loc', 'center', @(x) isvector(x) || strcmp(x, 'center'));
    addParameter(parser, 'kernel_size', [1 3], @isnumeric);

    parse(parser, varargin{:});
    bg_size = parser.Results.bg_size;
    % seed=parser.Results.seed;
    target_radius = parser.Results.target_radius;
    target_shape = parser.Results.target_shape;
    target_radius_cont = parser.Results.target_radius_cont;
    target_loc = parser.Results.target_loc;
    kernel_size = parser.Results.kernel_size;

    if strcmp(target_loc, 'center')
        mask_center = floor(bg_size/2)*[1 1];
    else
        mask_center = target_loc;
    end

    % compute mask
    mask = false(bg_size);

    if strcmp(target_shape, 'circular')
        for i_row = 1:bg_size
            for i_col = 1:bg_size
                mask(i_row, i_col) = (norm([i_row, i_col] - mask_center) < target_radius);
            end
        end
    else
        n_angles = 1e3;  % no. of angle points
        r_grid = lib.create_pink_noise_line(n_angles, target_shape);

        % set mean and std of target radius:
        r_grid = (r_grid - mean(r_grid(:)))*target_radius*target_radius_cont/std(r_grid(:)) + ...
            target_radius;

        % polar coords of each pixel in the image
        [x, y] = meshgrid(1:bg_size);
        [theta, radius] = cart2pol(x - mask_center(1), y - mask_center(2));
        theta_idx = round((theta + pi)/(2*pi)*n_angles) + 1;
        theta_idx(theta_idx == n_angles+1) = 1;
        mask = radius < r_grid(theta_idx);
    end

    %             %check if boundary point (old method):
    %             if mask(i,j)&&...
    %                     ~(mask(i-1,j-1)&&mask(i-1,j)&&mask(i-1,j+1)&&mask(i,j-1)...
    %                     &&mask(i,j+1)&&mask(i+1,j-1)&&mask(i+1,j)&&mask(i+1,j+1))
    %                 mask_edge_old(i,j)=true;
    %             end

    % check if boundary point (new method):
    % nbd=mask(i-1:i+1,j-1:j+1);
    % if length(unique(nbd))>1
    % mask_edge(i,j)=1;

    % compute mask edge: all pixels where at least one of its neighbours
    % is diff. from it
    mask_edge = bwperim(mask, 4) | bwperim(~mask, 4);
    mask_edge(:, [1 end]) = 0;
    mask_edge([1 end], :) = 0;

    % compute mask normal vectors
    target_normal = zeros(bg_size, bg_size, 2);

    if strcmp(target_shape, 'circular')
        for i_row = 2:bg_size-1
            for i_col = 2:bg_size-1
                % if mask_edge(i,j)
                vec = [i_col - mask_center(2), mask_center(1) - i_row];
                if norm(vec)
                    vec = vec/norm(vec);
                end
                target_normal(i_row, i_col, 1) = vec(1);
                target_normal(i_row, i_col, 2) = vec(2);
                % end
            end
        end
    else
        % [target_normal(:,:,1),target_normal(:,:,2)] = imgradientxy(mask);
        % target_normal(:,:,1)=-target_normal(:,:,1);
        [~, grad_dir] = imgradient(~mask);
        target_normal(:,:,1) = cosd(grad_dir);
        target_normal(:,:,2) = sind(grad_dir);

        % target_normal=lib.steerable_grad(~mask,[1 3]);
        %
        % target_normal=target_normal./vecnorm(target_normal,2,3);
        target_normal = target_normal.*mask_edge;
    end

    % make boundary ribbon of steerable kernel width
    mask_grad = lib.steerable_grad(mask, 'kernel_size', kernel_size, 'normalize', false);
    mask_grad_mag = mask_grad(:,:,1).^2 + mask_grad(:,:,2).^2;
    bd_strip = mask_grad_mag > 1e-20;
end
