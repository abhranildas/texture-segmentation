%% custom boundary for Bill

% generate data from two normals
n=1e3;
x1=mvnrnd([0;0],eye(2),n);
x2=mvnrnd([1;1],2*eye(2),n);

% classify
results1=classify_normals(x1,x2,'input_type','samp');
% get the optimal boundary between the fitted normals
% (to get the sample-optimized boundary, use dom=results.samp_opt_bd)
dom=results1.norm_bd;
% get the plot axis limits
ax=axis; 

% generate data from two other normals
x3=mvnrnd([-1;-1],eye(2),n);
x4=mvnrnd([2;2],2*eye(2),n);

% classify using the previous boundary as the classification domain
results2=classify_normals(x3,x4,'input_type','samp','dom',dom,'samp_opt',false);
% set the same axis limits so you can see the same boundary was used
axis(ax)