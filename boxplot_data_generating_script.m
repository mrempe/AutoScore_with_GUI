% this script runs PCASCOREBATCHMODE.m on all the BA and BL files 
% for the autoscoring paper. 

% set up strings for each data directory
BA2secdir = 'D:\mrempe\autoscore_and_epoch_length_study_data\2-Second_epochs\BA\';
BA10secdir = 'D:\mrempe\autoscore_and_epoch_length_study_data\10-Second_epochs\BA\';
BL2secdir = 'D:\mrempe\autoscore_and_epoch_length_study_data\2-Second_epochs\BL\';
BL10secdir = 'D:\mrempe\autoscore_and_epoch_length_study_data\10-Second_epochs\BL\';


% BA 2 second epochs 
[wakeagreeBA2sec,SWSagreeBA2sec,REMagreeBA2sec,globalagreeBA2sec,kappaBA2sec]=PCASCOREBATCHMODE('EEG2',BA2secdir);

% BA 10 second epochs 
%[wakeagreeBA10sec,SWSagreeBA10sec,REMagreeBA10sec,globalagreeBA10sec,kappaBA10sec]=PCASCOREBATCHMODE('EEG2',BA10secdir);

% BL 2 second epochs 
[wakeagreeBL2sec,SWSagreeBL2sec,REMagreeBL2sec,globalagreeBL2sec,kappaBL2sec]=PCASCOREBATCHMODE('EEG2',BL2secdir);

% BL 10 second epochs 
%[wakeagreeBL10sec,SWSagreeBL10sec,REMagreeBL10sec,globalagreeBL10sec,kappaBL10sec]=PCASCOREBATCHMODE('EEG2',BL10secdir);


% save the workspace
save BABL2sec10secagreement.mat

