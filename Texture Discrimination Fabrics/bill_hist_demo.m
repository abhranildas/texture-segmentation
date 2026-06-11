% read a matlab native image
img=double(imread('peppers.png'));

% reshape it into a table of rgb values
rgb=reshape(img,[],3);

% define histogram bin edges
bin_edges=linspace(0,255,6);
bin_edges(end)=256; % to prevent a quirk with histcn

% create joint histogram of rgb values with the same
% bin edges for r, g and b (these can be made different)
counts=histcn(rgb,bin_edges,bin_edges,bin_edges);