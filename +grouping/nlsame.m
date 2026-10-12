function n_common = nlsame(links_a, n_links_a, links_b, n_links_b)
    %NLSAME  Count the links two patches have in common.
    %   n_common = nlsame(links_a, n_links_a, links_b, n_links_b)
    %
    %   Inputs
    %     links_a   - list of patch indices linked to patch a.
    %     n_links_a - number of valid entries in links_a.
    %     links_b   - list of patch indices linked to patch b.
    %     n_links_b - number of valid entries in links_b.
    %
    %   Output
    %     n_common - number of links that appear in both links_a and links_b.
    %
    %   See also THRESH.

    n_common = 0;
    for i_a = 1:n_links_a
        for i_b = 1:n_links_b
            if links_a(i_a) == links_b(i_b)
                n_common = n_common+1;
            end
        end
    end
end
