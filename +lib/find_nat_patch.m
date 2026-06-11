function coords = find_nat_patch(imglab,psz,same_max_dist,same_max_col,diff_min_dist,diff_min_col)
%
% find same and different texture patches
%
% imglab = input lab image
% psz = patch size
% same_max_dist = max postion difference between same patches
% same_max_col = max color difference between same patches
% diff_min_dist = min position difference between different patches
% diff_min_col = min color difference between different patches
%
% fpout: (1,1) = xcoor, (1,2) = ycoor for ref patch
% fpout: (2,1) = xcoor, (2,2) = ycoor for same patch
% fpout: (3,1) = xcoor, (3,2) = ycoor for dif patch
% fpout: (4,1) = delLAB same patch, (4,2) = delLAB diff patch
%
coords = nan(4,2);
sz = size(imglab);

% find same patch
found = false;
i_search=0;
while (~found)&&(i_search<2e3)

    % randomly select patch a
    x_a = randi(sz(1)-4*same_max_dist*psz)+2*same_max_dist*psz;
    y_a = randi(sz(2)-4*same_max_dist*psz)+2*same_max_dist*psz;
    coords(1,:) = [x_a y_a];
    patch_a = imglab(x_a:x_a+psz-1,y_a:y_a+psz-1,1:3);

    % compute mean lab values for the reference patch
    lab_a=squeeze(mean(patch_a,[1 2]));

    % check neighboring patches to find one with smallest lab difference
    % x = -same_max_dist*psz; y = -same_max_dist*psz;
    % ptch = imglab(x0+x:x0+x+psz-1,y0+y:y0+y+psz-1,1:3);
    % lab=squeeze(mean(ptch,[1 2]));
    % dlab = norm(lab0(2:end)-lab(2:end)); % first lab difference
    dlabmin = inf;
    % xs = x + x0; ys = y + y0;
    for i = -same_max_dist:same_max_dist
        for j = -same_max_dist:same_max_dist
            x = i*psz; y = j*psz;
            if y_a+y+psz-1 > sz(2)
                break;
            end
            if x_a+x+psz-1 > sz(1)
                break;
            end
            ptch = imglab(x_a+x:x_a+x+psz-1,y_a+y:y_a+y+psz-1,1:3);
            lab_b=squeeze(mean(ptch,[1 2]));
            dlab = norm(lab_a(2:end)-lab_b(2:end)); % first lab difference
            i_search=i_search+1;
            if (dlab < dlabmin) && ~(i==0 && j==0) % not the same as patch a
                dlabmin = dlab;
                x_b = x + x_a; y_b = y + y_a;
            end
        end
    end
    if dlabmin < same_max_col
        coords(2,:) = [x_b y_b];
        % coords(4,1) = dlabmin;
        found = true;
        % i_search
    end
end


% find different patch
found = false;
i_search=0;
while (~found)&&(i_search<1e3)

    % randomly select patch a
    x_a = randi(sz(1)-4*same_max_dist*psz)+2*same_max_dist*psz;
    y_a = randi(sz(2)-4*same_max_dist*psz)+2*same_max_dist*psz;
    coords(3,:) = [x_a y_a];
    patch_a = imglab(x_a:x_a+psz-1,y_a:y_a+psz-1,1:3);

    % compute mean lab values for the reference patch
    lab_a=squeeze(mean(patch_a,[1 2]));

    % randomly select a distant patch
    x_b = randi(sz(1)-4*same_max_dist*psz)+2*same_max_dist*psz;
    y_b = randi(sz(2)-4*same_max_dist*psz)+2*same_max_dist*psz;
    dp = sqrt((x_b-x_a)^2 + (y_b-y_a)^2);
    i_search=i_search+1;
    if dp > diff_min_dist
        patch_b = imglab(x_b:x_b+psz-1,y_b:y_b+psz-1,1:3);
        % compute mean lab values for the distant patch
        lab_b=squeeze(mean(patch_b,[1 2]));
        dlab = norm(lab_a(2:end)-lab_b(2:end)); % lab difference
        if dlab > diff_min_col
            found = true;
            % i_search
            coords(4,:) = [x_b y_b];
            % coords(4,2) = dlab;
        end
    end
end


