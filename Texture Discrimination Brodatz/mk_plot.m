%
% make plots
close all
clearvars
%
% Brodatz data and predictions (accuracy)
x = [0;1.65;4.95;11.55];
y1 = [93;90.7;86;76.5];
y2 = [93.5;90.3;86.8;82];
y3 = [91.1;89.2;84.6;76.3];
figure; hold on;
plot(x,y1,'-o','color','k','MarkerEdgeColor','k',...
    'MarkerFaceColor','k','linewidth',1);
plot(x,y2,'-o','color',"#7E2F8E",'LineWidth',1);
plot(x,y3,'-o','color',"#77AC30",'LineWidth',1);
axis([0 12 50 100]);
xlabel('Eccentricity (deg)','fontsize',14)
ylabel('Percent Correct','fontsize',14)
%
% Fabric predictions L and RGB (accuracy)
x = [0;1.65;4.95;11.55];
y1 = [86.7;86.3;82.8;74.8]; % lum
y2 = [93.4;92.4;89.5;80.9]; % rgb
figure; hold on;
plot(x,y2,'-o','color',"#7E2F8E",'LineWidth',1);
plot(x,y1,'-o','color',"#77AC30",'LineWidth',1);
axis([0 12 50 100]);
xlabel('Eccentricity (deg)','fontsize',14)
ylabel('Percent Correct','fontsize',14)
%
% Brodatz data and predictions (dprime)
x = [0;1.65;4.95;11.55];
y1 = [93;90.7;86;76.5];
y2 = [93.5;90.3;86.8;82];
y3 = [90.7;88.9;84.4;74.9];
dy1 = 2*norminv(y1/100);
dy2 = 2*norminv(y2/100);
dy3 = 2*norminv(y3/100);
figure; hold on;
plot(x,dy1,'-o','color','k','MarkerEdgeColor','k',...
    'MarkerFaceColor','k','linewidth',1);
plot(x,dy2,'-o','color',"#7E2F8E",'LineWidth',1);
plot(x,dy3,'-o','color',"#77AC30",'LineWidth',1);
axis([0 12 0 4]);
xlabel('Eccentricity (deg)','fontsize',14)
ylabel('D-prime','fontsize',14)
%
% Fabric predictions L and RGB (dprime)
x = [0;1.65;4.95;11.55];
y1 = [85.9;85.2;81.8;70.5];   % lum
y2 = [93.4;92.4;89.5;80.9]; % rgb
dy1 = 2*norminv(y1/100);
dy2 = 2*norminv(y2/100);
figure; hold on;
plot(x,dy2,'-o','color',"#7E2F8E",'LineWidth',1);
plot(x,dy1,'-o','color',"#77AC30",'LineWidth',1);
axis([0 12 0 4]);
xlabel('Eccentricity (deg)','fontsize',14)
ylabel('D-prime','fontsize',14)
