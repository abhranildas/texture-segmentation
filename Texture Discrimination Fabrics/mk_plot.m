%
% make plots
close all
clearvars
%
% Brodatz data and predictions (accuracy) 1
x = [0;1.65;4.95;11.55];
y1 = [93;90.7;86;76.5]; % ad means
err = [0.0119799214738043;0.0122851913263867;0.0475608771684989;...
    0.0492442890089805]*100;
y2 = [93.40336;91.36975;88.0364;83.042]; % a no norm
y3 = [93.0056;90.14846;85.9412;78.6471]; % a norm
figure; hold on;
plot(x,y2,'-o','color',"#7E2F8E",'LineWidth',1.5);
plot(x,y3,'-o','color',"#77AC30",'LineWidth',1.5);
errorbar(x,y1,err,'-o','color','k','MarkerEdgeColor','k',...
    'MarkerFaceColor','k','linewidth',1.5);
axis([0 12 50 100]);
xlabel('Eccentricity (deg)','fontsize',14)
ylabel('Percent Correct','fontsize',14)
%
% Fabric predictions L and RGB (accuracy) 2
x = [0;1.65;4.95;11.55];
y1 = [0.889664;0.872521;0.840476;0.767423];   % a norm
y2 = [0.9615686;0.9541737;0.9336695;0.8796363];   % abr norm
figure; hold on;
plot(x,100*y2,'-o','color',"#7E2F8E",'LineWidth',1.5);
plot(x,100*y1,'-o','color',"#77AC30",'LineWidth',1.5);
axis([0 12 50 100]);
xlabel('Eccentricity (deg)','fontsize',14)
ylabel('Percent Correct','fontsize',14)
%
% Brodatz data and predictions (dprime) 3
x = [0;1.65;4.95;11.55];
y1 = [93;90.7;86;76.5];  % ad
y2 = [93.40336;91.36975;88.0364;83.042]; % a no norm
y3 = [93.0056;90.14846;85.9412;78.6471]; % a norm
dy1 = 2*norminv(y1/100);
dy2 = 2*norminv(y2/100);
dy3 = 2*norminv(y3/100);
figure; hold on;
plot(x,dy1,'-o','color','k','MarkerEdgeColor','k',...
    'MarkerFaceColor','k','linewidth',1);
plot(x,dy2,'-o','color',"#7E2F8E",'LineWidth',2);
plot(x,dy3,'-o','color',"#77AC30",'LineWidth',2);
axis([0 12 0 4]);
xlabel('Eccentricity (deg)','fontsize',14)
ylabel('D-prime','fontsize',14)
%
% Fabric predictions L and RGB (dprime) 4
x = [0;1.65;4.95;11.55];
% y1 = [85.9;85.2;81.8;70.5];   % lum norm
y1 = [0.889664;0.872521;0.840476;0.767423];   % a norm
% y2 = [93.4;92.4;89.5;80.9]; % rgb norm
y2 = [95.6;95.1;93.5;87.9];   % abr norm
dy1 = 2*norminv(y1/100);
dy2 = 2*norminv(y2/100);
figure; hold on;
plot(x,dy2,'-o','color',"#7E2F8E",'LineWidth',2);
plot(x,dy1,'-o','color',"#77AC30",'LineWidth',2);
axis([0 12 0 4]);
xlabel('Eccentricity (deg)','fontsize',14)
ylabel('D-prime','fontsize',14)
%
% Brodatz individual cues 5
x = [0;1.65;4.95;11.55];
y1 = [0.871148;0.861457;0.806162;0.720952];  % power cue
y2 = [0.764874;0.773277;0.759272;0.72619];   % histogram cue
y3 = [0.87423;0.817927;0.702213;0.56042];    % edge cue
y4 = [0.9164426;0.894762;0.848908;0.777787]; % power, histogram and edge
figure; hold on;
plot(x,100*y1,'-o','color',"#0072BD",'LineWidth',2);
plot(x,100*y2,'-o','color',"#D95319",'LineWidth',2);
plot(x,100*y3,'-o','color',"#EDB120",'LineWidth',2);
plot(x,100*y4,'-o','color',"#77AC30",'LineWidth',2);
axis([0 12 50 100]);
xlabel('Eccentricity (deg)','fontsize',14)
ylabel('Percent Correct','fontsize',14)
%
% Brodatz pairs of cues 6
x = [0;1.65;4.95;11.55];
y1 = [0.909972;0.87479;0.815154;0.717787];  % power & edge cues
y2 = [0.88112;0.841597;0.785182;0.726611];  % histogram & edge cues
y3 = [0.894286;0.886471;0.846975;0.777087]; % power & histogram cues
y4 = [0.9164426;0.894762;0.848908;0.777787]; % power, histogram and edge
figure; hold on;
plot(x,100*y1,'-o','color',[0.5 0.5 0.5],'LineWidth',2);
plot(x,100*y2,'-o','color',"#EDB120",'LineWidth',2);
plot(x,100*y3,'-o','color',"#7E2F8E",'LineWidth',2);
plot(x,100*y4,'-o','color',"#77AC30",'LineWidth',2);
axis([0 12 50 100]);
xlabel('Eccentricity (deg)','fontsize',14)
ylabel('Percent Correct','fontsize',14)
%
% Fabric (grey) individual cues 7
x = [0;1.65;4.95;11.55];
y1 = [0.715294;0.734706;0.701653;0.641541]; % power cue
y2 = [0.834118;0.826975;0.806863;0.743613]; % histogram cue
y3 = [0.815686;0.752157;0.635238;0.537787]; % edge cue
y4 = [0.889664;0.872521;0.840476;0.767423]; % power, histogram and edge
figure; hold on;
plot(x,100*y1,'-o','color',"#0072BD",'LineWidth',2);
plot(x,100*y2,'-o','color',"#D95319",'LineWidth',2);
plot(x,100*y3,'-o','color',"#EDB120",'LineWidth',2);
plot(x,100*y4,'-o','color',"#77AC30",'LineWidth',2);
axis([0 12 50 100]);
xlabel('Eccentricity (deg)','fontsize',14)
ylabel('Percent Correct','fontsize',14)
%
% Fabric (grey) pairs of cues 8
x = [0;1.65;4.95;11.55];
y1 = [0.824538;0.786303;0.711008;0.641204];  % power & edge cues
y2 = [0.881849;0.864202;0.820112;0.743277];  % histogram & edge cues
y3 = [0.864734;0.862549;0.838768;0.767535];  % power & histogram cues
y4 = [0.889664;0.872521;0.840476;0.767423];  % power, histogram and edge
figure; hold on;
plot(x,100*y1,'-o','color',[0.5 0.5 0.5],'LineWidth',2);
plot(x,100*y2,'-o','color',"#EDB120",'LineWidth',2);
plot(x,100*y3,'-o','color',"#7E2F8E",'LineWidth',2);
plot(x,100*y4,'-o','color',"#77AC30",'LineWidth',2);
axis([0 12 50 100]);
xlabel('Eccentricity (deg)','fontsize',14)
ylabel('Percent Correct','fontsize',14)
%
% Fabric (color) individual cues 9
x = [0;1.65;4.95;11.55];
y1 = [0.715294;0.734706;0.701653;0.641541]; % power cue
y2 = [0.9461625;0.9413445;0.9239776;0.874762]; % histogram cue
y3 = [0.815686;0.752157;0.635238;0.537787]; % edge cue
y4 = [0.9615686;0.9541737;0.9336695;0.8796363]; % power, histogram and edge
figure; hold on;
plot(x,100*y1,'-o','color',"#0072BD",'LineWidth',2);
plot(x,100*y2,'-o','color',"#D95319",'LineWidth',2);
plot(x,100*y3,'-o','color',"#EDB120",'LineWidth',2);
plot(x,100*y4,'-o','color',"#77AC30",'LineWidth',2);
axis([0 12 50 100]);
xlabel('Eccentricity (deg)','fontsize',14)
ylabel('Percent Correct','fontsize',14)
%
% Fabric (color) pairs of cues 10
x = [0;1.65;4.95;11.55];
y1 = [0.824538;0.786303;0.711008;0.641204];  % power & edge cues
y2 = [0.9545098;0.9486275;0.927395;0.87395]; % histogram & edge cues
y3 = [0.9573669;0.9513725;0.9328571;0.878095];  % power & histogram cues
y4 = [0.9615686;0.9541737;0.9336695;0.8796363]; % power, histogram and edge
figure; hold on;
plot(x,100*y1,'-o','color',[0.5 0.5 0.5],'LineWidth',2);
plot(x,100*y2,'-o','color',"#EDB120",'LineWidth',2);
plot(x,100*y3,'-o','color',"#7E2F8E",'LineWidth',2);
plot(x,100*y4,'-o','color',"#77AC30",'LineWidth',2);
axis([0 12 50 100]);
xlabel('Eccentricity (deg)','fontsize',14)
ylabel('Percent Correct','fontsize',14)
