function [wake_agreement2sec,SWS_agreement2sec,REM_agreement2sec,global_agreement2sec,kappa2sec, ...
	      wake_agreement10sec,SWS_agreement10sec,REM_agreement10sec,global_agreement10sec,kappa10sec] = comparePCAscoreepochlength(signal,twosecdirectory,tensecdirectory)

% usage: [wake_agreement2sec,SWS_agreement2sec,REM_agreement2sec,global_agreement2sec,kappa2sec, ...
%	      wake_agreement10sec,SWS_agreement10sec,REM_agreement10sec,global_agreement10sec,kappa10sec] = comparePCAscoreepochlength(signal,twosecdirectory,tensecdirectory)
%
%
% This function calls classify_usingPCA.m on each .txt file in the directory given as the 
% second argument.  It uses principal component analysis (following Gilmour et al Neurosci Letters 2010) to 
% distinguish sleep states and computes the kappa statistic, global agreement, and percentage agreement 
% of each sleep state.  
% The purpose of this function is to compare computer vs. human scoring in 10-second epochs 
% and 2-second epochs. To do a fair comparison between those two epoch lengths, we use
% only 8640 epochs of data.  This corresponds to 24 hours of data in a 10-second 
% epoch file and almost 5 hours of data in a 2-second epoch file. 
%
% This script first reads in the files then removes all of the data except 
% the 8640 epochs starting at the first instance of 10 AM.  
%
%
%A boxplot is made summarizing these statistics for all files in this directory.
%
% INPUTS:
% signal:  'EEG1' or 'EEG2'
% twosecdirectory:  where the txt files are kept that are scored in 2 sec epochs  (don't forget the final \)
% tensecdirectory: where the txt files are kept that are scored in 10 sec epochs (don't forget the final \)
%
% TO DO: 
% Make the return arguments cell arrays or structs so I don't have some many different things returned. 
% I could have one cell array for wake agreement. It would have a vector in each entry that contains
% the wake agreement percentage for each dataset, etc. 


% read in 2sec epoch files (being careful not to read in files that have already been scored)
two_sec_directory_plus_extension=strcat(twosecdirectory,'*.txt');
two_sec_files=dir(two_sec_directory_plus_extension);
for i=length(two_sec_files):-1:1                % don't autoscore files that have already been autoscored
	fname = two_sec_files(i).name;
	if strfind(fname,'AUTOSCORED')
		two_sec_files(i)=[];
	end
end

% read in 10sec epoch files (being careful not to read in files that have already been scored)
ten_sec_directory_plus_extension=strcat(tensecdirectory,'*.txt');
ten_sec_files=dir(ten_sec_directory_plus_extension);
for i=length(ten_sec_files):-1:1                % don't autoscore files that have already been autoscored
	fname = ten_sec_files(i).name;
	if strfind(fname,'AUTOSCORED')
		ten_sec_files(i)=[];
	end
end




% % call classify_usingPCA.m for each file (and restrict each file to only 8640 epochs starting at 10AM)
for i=1:length(two_sec_files)
	two_sec_files(i).name
	[predicted_score,kappa2sec(i),global_agreement2sec(i),wake_agreement2sec(i),SWS_agreement2sec(i),REM_agreement2sec(i)] ...
	     =classify_usingPCA(strcat(twosecdirectory,two_sec_files(i).name),signal,0,1,1,0);
	clear predicted_score 
end

for i=1:length(ten_sec_files)
	ten_sec_files(i).name
	[predicted_score,kappa10sec(i),global_agreement10sec(i),wake_agreement10sec(i),SWS_agreement10sec(i),REM_agreement10sec(i)] ...
	     =classify_usingPCA(strcat(tensecdirectory,ten_sec_files(i).name),signal,0,1,1,0);
	clear predicted_score 
end



figure
boxplot([wake_agreement2sec',SWS_agreement2sec',REM_agreement2sec',global_agreement2sec',kappa2sec', ...
	     wake_agreement10sec',SWS_agreement10sec',REM_agreement10sec',global_agreement10sec',kappa10sec'],'labels', ...
	     {'Wake_2sec', 'SWS_2sec', 'REM_2sec', 'Overall_2sec', 'Kappa_2sec','Wake_10sec', 'SWS_10sec', 'REM_10sec', 'Overall_10sec', 'Kappa_10sec' }, ...
	'plotstyle','compact','boxstyle','filled','colors','rb');
ax=gca();
set(ax,'YGrid','on')
title({twosecdirectory,tensecdirectory})


% Now make a second plot of kappa vs the percentage of training data used
training = [0.05 0.1 0.2 0.4 0.5 0.6 0.7 0.8 0.9 0.95 1]
for j=1:length(training)
	for i=1:length(two_sec_files)
		two_sec_files(i).name
		[predicted_score,kappa2sec(i,j),global_agreement2sec(i,j),wake_agreement2sec(i,j),SWS_agreement2sec(i,j),REM_agreement2sec(i,j)] ...
		=classify_usingPCA(strcat(twosecdirectory,two_sec_files(i).name),signal,0,1,training(j),0);
		clear predicted_score 
	end

	for i=1:length(ten_sec_files)
		ten_sec_files(i).name
		[predicted_score,kappa10sec(i,j),global_agreement10sec(i,j),wake_agreement10sec(i,j),SWS_agreement10sec(i,j),REM_agreement10sec(i,j)] ...
		=classify_usingPCA(strcat(tensecdirectory,ten_sec_files(i).name),signal,0,1,training(j),0);
		clear predicted_score 
	end
end


figure
errorbar(training,mean(kappa2sec,1),std(kappa2sec,1)./size(kappa2sec,1))
hold on
errorbar(training,mean(kappa10sec,1),std(kappa10sec,1)./size(kappa10sec,1),'--')
errorbar(training,mean(global_agreement2sec,1),std(global_agreement2sec,1)./size(global_agreement2sec,1),'r')
errorbar(training,mean(global_agreement10sec,1),std(global_agreement10sec,1)./size(global_agreement10sec,1),'r--')
errorbar(training,mean(wake_agreement2sec,1),std(wake_agreement2sec,1)./size(wake_agreement2sec,1),'g')
errorbar(training,mean(wake_agreement10sec,1),std(wake_agreement10sec,1)./size(wake_agreement10sec,1),'g--')
errorbar(training,mean(SWS_agreement2sec,1),std(SWS_agreement2sec,1)./size(SWS_agreement2sec,1),'r')
errorbar(training,mean(SWS_agreement10sec,1),std(SWS_agreement10sec,1)./size(SWS_agreement10sec,1),'r')
errorbar(training,mean(REM_agreement2sec,1),std(REM_agreement2sec,1)./size(REM_agreement2sec,1),'r')
errorbar(training,mean(REM_agreement10sec,1),std(REM_agreement10sec,1)./size(REM_agreement10sec,1),'r')
hold off
legend('kappa 2 seconds','kappa 10 seconds','Global agreement 2 seconds','Global agreement 10 seconds','Wake agreement 2 seconds', ...
	   'Wake agreement 10 seconds','SWS agreement 2 seconds','SWS agreement 10 seconds','REM agreement 2 seconds','REM agreement 10 seconds')
title('BA')
% Then call plotly something like this:
%resp = fig2plotly(gcf,'name','Accuracy of PCA approach','strip',1)
% resp.url gives the url to the plotted figure

