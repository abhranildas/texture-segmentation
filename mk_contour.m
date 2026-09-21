function [contour_pts, links, n_contour_pts] = mk_contour(n_pixels, row, col)
    %MK_CONTOUR  Order a list of edge pixels into a single connected contour walk.
    %   [contour_pts, links, n_contour_pts] = mk_contour(n_pixels, row, col)
    %
    %   Builds an adjacency ("links") map between every pair of pixels that
    %   are 8-connected, then starts from a pixel with exactly one link (an
    %   endpoint) and walks the chain, consuming each link as it is traversed.
    %   Requires an open chain: a closed loop has no single-link starting
    %   pixel, and the search for one runs past the end of the pixel list.
    %
    %   Inputs
    %     n_pixels - number of pixels in the list.
    %     row      - vertical coordinates of the pixels (1-by-n_pixels).
    %     col      - horizontal coordinates of the pixels (1-by-n_pixels).
    %
    %   Output
    %     contour_pts   - pixel indices (into row/col) in walk order
    %                     (n_pixels-by-1; trailing entries beyond
    %                     n_contour_pts are unused).
    %     links         - the adjacency map, left with every traversed link
    %                     zeroed out (n_pixels-by-n_pixels; all zero once the
    %                     chain has been fully traversed).
    %     n_contour_pts - number of pixels actually included in the walk; less
    %                     than n_pixels if some pixels were unreachable from
    %                     the starting pixel.
    %
    %   See also RE.

    links = zeros(n_pixels, n_pixels); contour_pts = zeros(n_pixels, 1);

    % create link map
    for i_point = 1:n_pixels
        for j_point = i_point+1:n_pixels
            if (col(i_point)-col(j_point))^2 + (row(i_point)-row(j_point))^2 <= 2
                links(i_point, j_point) = 1; links(j_point, i_point) = 1;
            end
        end
    end

    % find first row with only one link
    i_point = 0;
    n_links = 2;
    while n_links > 1
        i_point = i_point+1;
        n_links = sum(links(i_point, :));
    end

    % make contour
    n_contour_pts = 1; contour_pts(n_contour_pts) = i_point;
    curr_point = i_point; prev_point = 0;
    while curr_point ~= prev_point
        j_point = 1; prev_point = curr_point;
        while (curr_point == prev_point) && (j_point <= n_pixels)
            if links(curr_point, j_point) == 1
                curr_point = j_point;
                links(prev_point, j_point) = 0;
                links(j_point, prev_point) = 0;
                n_contour_pts = n_contour_pts + 1;
                contour_pts(n_contour_pts) = j_point;
            end
            j_point = j_point+1;
        end
    end
end
