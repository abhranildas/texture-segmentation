function [num_edges, edge_dens, edge_length_dv, edge_or, edge_curv, edge_power1, ...
    edge_power2, edge_power4] = edge_dv(patch_a, patch_b)
    %EDGE_DV  Edge-contour decision variables and raw per-contour properties for two patches.
    %   [num_edges, edge_dens, edge_length_dv, edge_or, edge_curv, edge_power1,
    %    edge_power2, edge_power4] = edge_dv(patch_a, patch_b)
    %
    %   Calls LIB.EDGE_CONTOUR_PROPS on each patch to get per-contour edge
    %   properties, then reports the contour count and mean pixel density
    %   directly, a length-based decision variable assuming exponentially
    %   distributed contour lengths, and the raw per-contour orientation,
    %   curvature and power values (not reduced to a single decision
    %   variable).
    %
    %   Inputs
    %     patch_a - first image patch.
    %     patch_b - second image patch, same size as patch_a.
    %
    %   Outputs
    %     num_edges      - [n_contours_a; n_contours_b], number of contours
    %                      found in each patch.
    %     edge_dens      - [mean_dens_a; mean_dens_b], mean edge pixel density
    %                      per contour, one value per patch.
    %     edge_length_dv - decision variable for contour length, assuming
    %                      exponentially distributed lengths; larger means
    %                      more evidence the two patches' contours differ in
    %                      length.
    %     edge_or        - per-contour orientations, patch_a's contours then
    %                      patch_b's, concatenated as a column.
    %     edge_curv      - per-contour curvatures, same concatenation as
    %                      edge_or.
    %     edge_power1    - per-contour power at scale 1, same concatenation.
    %     edge_power2    - per-contour power at scale 2, same concatenation.
    %     edge_power4    - per-contour power at scale 4, same concatenation.
    %
    %   See also LIB.HIST_DV, LIB.POWER_DV.

    [contour_props_a, mean_contour_props_a] = lib.edge_contour_props(patch_a);
    [contour_props_b, mean_contour_props_b] = lib.edge_contour_props(patch_b);

    %% # of contours
    n_contours_a = length(contour_props_a); n_contours_b = length(contour_props_b);
    num_edges = [n_contours_a; n_contours_b];

    %% edge pixel density
    edge_dens = [mean_contour_props_a.dens; mean_contour_props_b.dens];
    edge_dens_dv_diff = mean_contour_props_a.dens-mean_contour_props_b.dens;

    %% edge lengths
    mean_length_a = mean([contour_props_a.length]); mean_length_b = mean([contour_props_b.length]);
    mean_length_ab = mean([contour_props_a.length contour_props_b.length]);
    % edge_lengths=[contour_props_a.length contour_props_b.length];
    % edge_length_dv_diff=mean_contour_props_a.length-mean_contour_props_b.length;
    % edge_length_dv_norm=na*log(sab/sa)+nb*log(sab/sb)+(sum(([contour_props_a.length contour_props_b.length]-mab).^2)/sab^2 ...
    %                                              -sum(([contour_props_a.length]-ma).^2)/sa^2 ...
    %                                              -sum(([contour_props_b.length]-mb).^2)/sb^2)/2;
    % edge_length_dv_norm=log(prod(normpdf([contour_props_a.length],ma,sa))*prod(normpdf([contour_props_b.length],mb,sb))/ ...
    % prod(normpdf([contour_props_a.length contour_props_b.length],mab,sab)));

    % decision variable assuming exponentially distributed contour lengths
    % (which we empirically saw was true):
    edge_length_dv = (n_contours_a+n_contours_b)*log(mean_length_ab) ...
        - n_contours_a*log(mean_length_a) - n_contours_b*log(mean_length_b);

    %% edge orientation
    edge_or = [[contour_props_a.orientation]'; [contour_props_b.orientation]'];

    % edge_or_dv=mean_contour_props_a.or-mean_contour_props_b.or;

    %% edge curvature
    edge_curv = [[contour_props_a.curv]'; [contour_props_b.curv]'];

    % edge_curv_dv=mean_contour_props_a.curv-mean_contour_props_b.curv;

    %% edge power
    edge_power1 = [[contour_props_a.ep1]'; [contour_props_b.ep1]'];
    % edge_ep1_dv=mean_contour_props_a.ep1-mean_contour_props_b.ep1;

    edge_power2 = [[contour_props_a.ep2]'; [contour_props_b.ep2]'];
    % edge_ep2_dv=mean_contour_props_a.ep2-mean_contour_props_b.ep2;

    edge_power4 = [[contour_props_a.ep4]'; [contour_props_b.ep4]'];
    % edge_ep4_dv=mean_contour_props_a.ep4-mean_contour_props_b.ep4;
end
