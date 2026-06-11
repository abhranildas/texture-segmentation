%% create a texture discrimination error matrix from subject data

% load exp_settings and subject_file

errmat_all=nan(exp_settings.nTex,exp_settings.nTex,exp_settings.nLevels);

for iLevel=1:4 % set eccentricity level

    errmat=nan(exp_settings.nTex);
    errmat(logical(eye(size(errmat))))=0;

    % concatenate all sessions:
    idx=reshape(permute(subject_file.idx, [2 1 3]),exp_settings.nLevels,exp_settings.nTrials*exp_settings.nSessions)';
    correct=reshape(permute(subject_file.correct, [2 1 3]),exp_settings.nLevels,exp_settings.nTrials*exp_settings.nSessions)';

    % textures presented in the experiment:
    texnums=exp_settings.tex(idx(:,iLevel));

    for iTrial=1:numel(texnums)
        tex=sort(texnums{iTrial});
        if numel(tex)==1 % if same pair
            errmat(tex,tex)=errmat(tex,tex)+correct(iTrial,iLevel);
        else % if different pair
            errmat(tex(1),tex(2))=correct(iTrial,iLevel);
        end
    end

    % change diagonals from counts to percentage
    errmat(logical(eye(size(errmat))))=diag(errmat)/(exp_settings.nTrials*exp_settings.nSessions/(2*exp_settings.nTex));

    % symmetrize the matrix:
    errmat=triu(errmat)+triu(errmat,1)';

    errmat_all(:,:,iLevel)=errmat;
end

% sort by diagonal errors of the last eccentricity level, and plot
[~,sortedIndices]=sort(diag(errmat_all(:,:,exp_settings.nLevels)),'descend');

for iLevel=1:4
    errmat=errmat_all(:,:,iLevel);
    errmat=errmat(sortedIndices,sortedIndices);
    errmat_all(:,:,iLevel)=errmat;

    figure;
    h=pcolor(errmat_all(:,:,iLevel)); set(h,'edgecolor','none');
    axis image
    colormap winter; colorbar
    set(gca,'YDir','reverse')
    set(gca,'xtick',[1 60])
    set(gca,'ytick',[1 60])
    set(gca,'fontsize',13)
    xlabel 'texture #'
    ylabel 'texture #'
    title(sprintf('eccentricity: %.1f',exp_settings.ecc(iLevel)))
end

%% plot accuracy vs eccentricity
acc_subj=squeeze(mean(subject_file.correct,1))';

figure; hold on
errorbar(exp_settings.ecc,mean(acc_subj),std(acc_subj),'-ok','markerfacecolor','k')
xlabel 'eccentricity (deg)'
ylabel 'accuracy'