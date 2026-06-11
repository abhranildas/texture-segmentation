function [num_edges,edge_dens,edge_length_dv,edge_or,edge_curv,edge_power1,edge_power2,edge_power4]=edge_dv(patch_a,patch_b)
[contour_props_a,mean_contour_props_a]=lib.edge_contour_props(patch_a);
[contour_props_b,mean_contour_props_b]=lib.edge_contour_props(patch_b);

%% # of contours
na=length(contour_props_a); nb=length(contour_props_b);
num_edges=[na;nb];

%% edge pixel density
edge_dens=[mean_contour_props_a.dens; mean_contour_props_b.dens];
edge_dens_dv_diff=mean_contour_props_a.dens-mean_contour_props_b.dens;

%% edge lengths
ma=mean([contour_props_a.length]); mb=mean([contour_props_b.length]);
mab=mean([contour_props_a.length contour_props_b.length]);
% edge_lengths=[contour_props_a.length contour_props_b.length];
% edge_length_dv_diff=mean_contour_props_a.length-mean_contour_props_b.length;
% edge_length_dv_norm=na*log(sab/sa)+nb*log(sab/sb)+(sum(([contour_props_a.length contour_props_b.length]-mab).^2)/sab^2 ...
%                                              -sum(([contour_props_a.length]-ma).^2)/sa^2 ...
%                                              -sum(([contour_props_b.length]-mb).^2)/sb^2)/2;
% edge_length_dv_norm=log(prod(normpdf([contour_props_a.length],ma,sa))*prod(normpdf([contour_props_b.length],mb,sb))/ ...
% prod(normpdf([contour_props_a.length contour_props_b.length],mab,sab)));

% decision variable assuming exponentially distributed contour lengths
% (which we empirically saw was true):
edge_length_dv=(na+nb)*log(mab)-na*log(ma)-nb*log(mb);

%% edge orientation
edge_or=[[contour_props_a.orientation]'; [contour_props_b.orientation]'];

% edge_or_dv=mean_contour_props_a.or-mean_contour_props_b.or;

%% edge curvature
edge_curv=[[contour_props_a.curv]'; [contour_props_b.curv]'];

% edge_curv_dv=mean_contour_props_a.curv-mean_contour_props_b.curv;

%% edge power
edge_power1=[[contour_props_a.ep1]'; [contour_props_b.ep1]'];
% edge_ep1_dv=mean_contour_props_a.ep1-mean_contour_props_b.ep1;

edge_power2=[[contour_props_a.ep2]'; [contour_props_b.ep2]'];
% edge_ep2_dv=mean_contour_props_a.ep2-mean_contour_props_b.ep2;

edge_power4=[[contour_props_a.ep4]'; [contour_props_b.ep4]'];
% edge_ep4_dv=mean_contour_props_a.ep4-mean_contour_props_b.ep4;