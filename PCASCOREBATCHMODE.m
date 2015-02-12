function [wake_agreement,SWS_agreement,REM_agreement,global_agreement,kappa]=PCASCOREBATCHMODE(signal,directory)

% usage: [wake_agreement,SWS_agreement,REM_agreement,global_agreement,kappa]=PCASCOREBATCHMODE(signal,directory)
%
% This function calls classify_usingPCA.m on each .txt file in the directory given as the 
% second argument.  It uses principal component analysis (following Gilmour et al Neurosci Letters 2010) to 
% distinguish sleep states and computes the kappa statistic, global agreement, and percentage agreement 
% of each sleep state.  A boxplot is made summarizing these statistics for all files in this directory.
%
% INPUTS:
% signal:  'EEG1' or 'EEG2'
% directory:  where the txt files are kept  (don't forget the final \)
%

directory_plus_extension=strcat(directory,'*.txt');
files=dir(directory_plus_extension);
for i=length(files):-1:1                % don't autoscore files that have already been autoscored
	fname = files(i).name;
	if strfind(fname,'AUTOSCORED')
		files(i)=[];
	end
end




for i=1:length(files)
	files(i).name
	[predicted_score,dynamic_range(i),kappa(i),global_agreement(i),wake_agreement(i),SWS_agreement(i),REM_agreement(i)]=classify_usingPCA(strcat(directory,files(i).name),signal,0,0,1,1);
	
clear predicted_score 
end


figure
boxplot([wake_agreement',SWS_agreement',REM_agreement',global_agreement',kappa'],'labels',{'Wake', 'SWS', 'REM', 'Overall', 'Kappa'}, ...
	'plotstyle','compact','boxstyle','filled','colors','rb');
ax=gca();
set(ax,'YGrid','on')
title(directory)

% This is to test an idea about dynamic range
figure
plot(dynamic_range,kappa,'ko')
hold on
plot(dynamic_range,global_agreement,'ro')
hold off
