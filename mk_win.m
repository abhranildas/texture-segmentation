function win = mk_win(patch_size, radius, shape)
    %MK_WIN  Make a raised-cosine-boundary window.
    %   win = mk_win(patch_size, radius, shape)
    %
    %   Builds a window that is 1 within radius of center and tapers to 0 by a
    %   raised cosine between radius and the window's edge.
    %
    %   Inputs
    %     patch_size - window side length, in pixels.
    %     radius     - flat (unwindowed) radius, in pixels.
    %     shape      - 1 for a radially symmetric window, 2 for a separable
    %                  window built from the outer product of a 1-D profile
    %                  with itself.
    %
    %   Output
    %     win - patch_size-by-patch_size window, values in [0, 1].
    %
    %   See also RP.

    win = zeros(patch_size, patch_size); win_1d = zeros(patch_size, 1);
    center = patch_size/2+0.5;
    if shape == 1
        for i_row = 1:patch_size
            for i_col = 1:patch_size
                dist = sqrt((i_row-center)^2 + (i_col-center)^2);
                if dist <= radius
                    win(i_row, i_col) = 1;
                elseif dist <= patch_size/2
                    win(i_row, i_col) = 0.5*(cos(pi*(dist-radius)/(patch_size/2-radius))+1);
                end
            end
        end
    elseif shape == 2
        for i_row = 1:patch_size
            dist = abs(i_row-center);
            if dist <= radius
                win_1d(i_row) = 1;
            else
                win_1d(i_row) = 0.5*(cos(pi*(dist-radius)/(patch_size/2-radius))+1);
            end
        end
        for i_col = 1:patch_size
            win(:, i_col) = win_1d;
        end
        for i_row = 1:patch_size
            win(i_row, :) = win(i_row, :).*win_1d.';
        end
    end
end
