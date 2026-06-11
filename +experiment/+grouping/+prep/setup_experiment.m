function setup_experiment
% Create all experimental stimuli and settings

exp_type='grouping';

tex_sets={'brodatz','fabric','pertex'}; % texture families
nTexs=[60 60 334]; % # of textures in each family
session_tex_ids=[1 1 2 2 3 3]; % texture family id for each session

stim_sz=1024;
patch_sz=64; % size of a texture patch square
nPatches=stim_sz/patch_sz; % # of texture patches along each side

monitor_bit = 8;
monitor_gamma = 2.059;

nTrials=96; % number of trials in each contrast level
nLevels=5; % number of contrast levels
nSessions=6; % number of texture sessions
nRegions=5; % number of texture regions in each stimulus

tex_ids=nan(nRegions,nTrials,nLevels,nSessions); % array containing texture numbers used for each stimulus
% seeds=nan(nTrials,nLevels,nSessions);
diff=false(nTrials,nLevels,nSessions); % condition of each trial. diff=1, same=0
cue_imgs=zeros(stim_sz,stim_sz,nTrials,nLevels,nSessions,'uint8');
stimuli=zeros(stim_sz,stim_sz,nTrials,nLevels,nSessions,'uint8');
feedback_imgs=zeros(stim_sz,stim_sz,nTrials,nLevels,nSessions,'uint8'); % stimuli + cue images
contrasts=repmat([.1 .075 .05 .03 .02],[nTrials 1 nSessions]); % contrast levels of each trial
cue_locs=nan(2,2,nTrials,nLevels,nSessions); % 2x2 matrix [x1 y1; x2 y2] of cue locations for each trial.

for iSession=1:nSessions
    tex_id=session_tex_ids(iSession);
    tex_set=tex_sets{tex_id};
    nTex=nTexs(tex_id);
    session=grouping.mk_texseg_session(tex_set,nTex); % call Bill's function to create session struct

    % store same/different condition
    same_temp=logical(session.cuelocs(:,1));
    diff(:,:,iSession)=reshape(same_temp,[nTrials nLevels]);

    % store cue locations
    cue_locs_temp=session.cuelocs(:,2:end);
    cue_locs(:,:,:,:,iSession)=reshape(cue_locs_temp(:,[2 4 1 3])', [2 2 nTrials nLevels]);

    % store region maps
    maps=reshape(session.maps,[nPatches nPatches nTrials nLevels]);

    % store texture id's in each stimulus
    tex_ids(:,:,:,iSession)=reshape(session.texs', [nRegions nTrials nLevels]);

    % generate and store stimuli
    stimuli_flat=zeros([stim_sz stim_sz nTrials*nLevels],'uint8');
    cue_imgs_flat=zeros([stim_sz stim_sz nTrials*nLevels],'uint8');
    feedback_imgs_flat=zeros([stim_sz stim_sz nTrials*nLevels],'uint8');
    for iTrial_flat=1:nTrials*nLevels
        [iSession iTrial_flat]
        c0=session.cntrst(iTrial_flat);
        [~,cue_img,stim,fimg]=grouping.mk_trl_points(iTrial_flat,session.sz,session.pw,session.m0,session.tex_set,c0,session.cuelocs,session.texs,session.maps);
        cue_imgs_flat(:,:,iTrial_flat)=uint8(lib.gammaCorrect(cue_img,monitor_gamma,monitor_bit));
        stimuli_flat(:,:,iTrial_flat)=uint8(lib.gammaCorrect(stim,monitor_gamma,monitor_bit));
        feedback_imgs_flat(:,:,iTrial_flat)=uint8(lib.gammaCorrect(fimg,monitor_gamma,monitor_bit));
    end    

    cue_imgs(:,:,:,:,iSession)=reshape(cue_imgs_flat,[stim_sz stim_sz nTrials nLevels]);
    stimuli(:,:,:,:,iSession)=reshape(stimuli_flat,[stim_sz stim_sz nTrials nLevels]);
    feedback_imgs(:,:,:,:,iSession)=reshape(feedback_imgs_flat,[stim_sz stim_sz nTrials nLevels]);

end

exp_settings = struct(...
    'exp_type', exp_type,...
    'tex_sets', {tex_sets},...
    'nTexs', nTexs,... % 'seeds', seeds,...
    'stim_sz', stim_sz,...
    'nRegions', nRegions,...
    'nTrials', nTrials,...
    'nLevels', nLevels,...
    'nSessions', nSessions, ...
    'tex_ids', tex_ids,...
    'cue_locs', cue_locs,...
    'diff',diff,...
    'maps',maps,...
    'stimuli', stimuli,...
    'cue_imgs',cue_imgs,...
    'feedback_imgs',feedback_imgs,...
    'contrasts',contrasts,...
    'loadSessionStimuli', @experiment.grouping.run.loadStimuli, ...
    'luminance', 0.5,...
    'ppd', 60,...
    'monitor_bit',monitor_bit,...
    'monitor_gamma',monitor_gamma,...
    'moniter_brightness', 50,...
    'monitor_contrast', 100,...
    'monitorMaxPix', 255, ...
    'bgPixVal', 0.5*255, ...
    'cueIntervalMs', 200,...
    'blankIntervalMs', 50, ...
    'stimulusIntervalMs', 200,...
    'responseIntervalMs', 500, ...
    'feedbackIntervalMs', 100);

folderOut= ['exp_files/' exp_type];
mkdir(folderOut);
save([folderOut '/exp_settings.mat'], 'exp_settings','-v7.3');

end
