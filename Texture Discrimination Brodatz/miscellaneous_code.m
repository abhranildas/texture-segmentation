%
% miscellaneous code
%
clearvars
close all;
%
% 11/13/23
% plot predicted and observed pc and dp for same-diff texture experiment 
xa = [0 1.7 5.1 11.8];
xa = (xa.^2 + 0.6^2).^0.5; 
pca = [0.93 0.91 0.86 0.76];
dpa = 2*norminv(pca);
xb = [0 1.7 5.1 11.8 25.3];
pcb = [0.89 0.885 0.85 0.81 0.75];
dpb = 2*norminv(pcb);
figure; hold on;
plot(xa,dpa,"-o"); plot(xb,dpb,"-o"); ylim([0 3]);
figure; hold on;
plot(xa,pca,"-o"); plot(xb,pcb,"-o"); ylim([0.5 1]);
