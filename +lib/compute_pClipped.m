function pClipped=compute_pClipped(stim)
% calculate percentage of elements in the input that are outside 0 to 1
pClipped=(sum(stim(:)<0)+sum(stim(:)>1))/numel(stim);
