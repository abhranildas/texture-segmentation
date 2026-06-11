function [stimuli, seeds, tex, coords]=generate_stimuli(exp_type)

nTex=60; % number of textures
nTrials=10; % number of trials for each texture pair

stimuli=nan(64,64,2,2*nTex*nTrials);
seeds=zeros(2*nTex*nTrials,2,'uint32');
tex=cell(2*nTex*nTrials,1);
coords=cell(2*nTex*nTrials,2);


% same-texture pairs
for iTex=1:nTex
    for iTrial=1:nTrials
        idx=(iTex-1)*nTrials+iTrial;
        tex{idx}=iTex;

        if strcmpi(exp_type,'norm')
            % patch 1
            [ptch1,seed,~,coord]=lib.texture_patch('tex_num',iTex);
            stimuli(:,:,1,idx)=ptch1;
            seeds(idx,1)=seed;
            coords{idx,1}=coord;

            % patch 2
            [ptch2,seed,~,coord]=lib.texture_patch('tex_num',iTex);
            stimuli(:,:,2,idx)=ptch2;
            seeds(idx,2)=seed;
            coords{idx,2}=coord;

        elseif strcmpi(exp_type,'joined')
            % total patch
            [ptch,seed,~,coord]=lib.texture_patch('tex_num',iTex,'patch_sz',[128 64]);
            
            ptch1=ptch(1:64,:);
            stimuli(:,:,1,idx)=ptch1;
            seeds(idx,1)=seed;
            coords{idx,1}=coord;

            ptch2=ptch(65:end,:);
            stimuli(:,:,2,idx)=ptch2;
            seeds(idx,2)=seed;
            coords{idx,2}=coord;
        end
    end
end

% different-texture pairs
for iTex=1:nTex
    % prevent sampling any pair twice:
    prev_tex=cell2mat(tex(nTex*nTrials+1:idx));
    if ~isempty(prev_tex)
        prev_tex=prev_tex(prev_tex(:,2)==iTex,1); % textures previously paired with this
    end
    tex2=datasample(setdiff(1:nTex,[iTex; prev_tex]),nTrials,'replace',false);
    for iTrial=1:nTrials
        iTex2=tex2(iTrial);
        idx=nTex*nTrials+(iTex-1)*nTrials+iTrial;
        tex{idx}=[iTex,iTex2];

        % patch 1
        [ptch1,seed,~,coord]=lib.texture_patch('tex_num',iTex);
        stimuli(:,:,1,idx)=ptch1;
        seeds(idx,1)=seed;
        coords{idx,1}=coord;

        % patch 2
        [ptch2,seed,~,coord]=lib.texture_patch('tex_num',iTex2);
        stimuli(:,:,2,idx)=ptch2;
        seeds(idx,2)=seed;
        coords{idx,2}=coord;
    end
end