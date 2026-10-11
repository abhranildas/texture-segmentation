function [contour_pts, links, n_contour_pts] = mk_contour(n_pixels, row, col)
    %MK_CONTOUR  Order a list of edge pixels into a single connected contour walk.
    %   [contour_pts, links, n_contour_pts] = mk_contour(n_pixels, row, col)
    %
    %   Builds an adjacency ("links") map between every pair of pixels that
    %   are 8-connected, then starts from a pixel with at most one link (an
    %   endpoint) and walks the chain, consuming each link as it is traversed.
    %   A closed loop has no endpoint, so the walk starts at its first
    %   least-linked pixel, goes round, and ends back on that pixel: the start
    %   pixel appears both first and last, so the closing step is part of the
    %   walk.
    %
    %   Inputs
    %     n_pixels - number of pixels in the list.
    %     row      - vertical coordinates of the pixels (1-by-n_pixels).
    %     col      - horizontal coordinates of the pixels (1-by-n_pixels).
    %
    %   Output
    %     contour_pts   - pixel indices (into row/col) in walk order (a column,
    %                     at least n_pixels long; entries beyond n_contour_pts
    %                     are unused).
    %     links         - the adjacency map, left with every traversed link
    %                     zeroed out (n_pixels-by-n_pixels; all zero once the
    %                     chain has been fully traversed).
    %     n_contour_pts - number of entries in the walk, counting a pixel each
    %                     time it is visited (n_pixels + 1 for a simple loop).
    %                     The walk always takes the lowest-numbered unused
    %                     link, so at a junction it can dead-end before
    %                     visiting every pixel.
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

    % start at the first pixel with at most one link (an endpoint). A closed
    % contour has none, so start at its first least-linked pixel instead; the
    % walk then goes round the loop and ends back on that pixel.
    n_links = sum(links, 2);
    i_point = find(n_links <= 1, 1);
    if isempty(i_point)
        [~, i_point] = min(n_links);
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
