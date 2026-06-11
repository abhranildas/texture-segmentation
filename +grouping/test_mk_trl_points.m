%
% test_mk_trl_points
% demonstrates one call to mk_trial_points during a session
%
% experiment set up:
% (1) make and save the session with mk_texseg_session_points
% (2) make each trial in a session with a call to mk_trial_points
%
session=grouping.mk_texseg_session();
trl = 10;
t = session.tperm(trl);
c0 = session.cntrst(trl);
[cond,cimg,timg,fimg] = ...
    grouping.mk_trl_points(t,session.sz,session.pw,session.m0,session.texset,c0,session.cuelocs,session.texs,session.maps);

figure;
imshow(cast(cimg,"uint8"));
figure;
imshow(cast(timg,"uint8"));
figure;
imshow(cast(fimg,"uint8"));
