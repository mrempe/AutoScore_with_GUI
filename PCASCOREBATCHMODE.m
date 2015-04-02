function agreement_stats=PCASCOREBATCHMODE

% usage: a GUI pops up and prompts the user to choose the file(s) that he/she wants to 
% have autoscored.  The files must be .txt files containing timestamp in the first column and sleep state in the 
% next column.  After that there is an optional lactate column and then EEG data columns (EEG 1 and EEG 2).
%
% This function calls classify_usingPCA.m on each .txt file in the directory given as the 
% second argument.  It uses principal component analysis (following Gilmour et al Neurosci Letters 2010) to 
% distinguish sleep states and computes the kappa statistic, global agreement, and percentage agreement 
% of each sleep state.  A boxplot is made summarizing these statistics for all files in this directory.
%
% OUTPUTS:
% agreement_stats, a data structure with the following fields:
% agreement_stats.wake    
% agreement_stats.SWS
% agreement_stats.REM
% agreement_stats.global
% agreement_stats.kappa
%
% where each of these statistics is defined (and computed) in compute_agreement.m    


% Pop up a window 
[files,directory] = uigetfile('Multiselect','on','D:\*.txt','Please Select .txt file(s) to autoscore');  %last parameter sent to uigetfile ('*.edf*) specifies that only edf files will be displayed in the user interface.
if ~iscell(files), files = {files}; end

prompt1 = {'Do you want to use EEG1 or EEG2?'};
ReturnString1 = inputdlg(prompt1,'Channel Selection',1,{'EEG2'});
signal = ReturnString1{1,1};

prompt2 = {'Has this file already been fully scored by a human? (1 for yes, 0 for no)'};
ReturnString2 = inputdlg(prompt2,'Already Scored?',1,{'0'});
already_scored_by_human = str2double(ReturnString2{1,1});

prompt3 = {'Do you want to restrict the dataset to only 8640 epochs? (1 for yes, 0 for no)'};
ReturnString3 = inputdlg(prompt3,'Restrict?',1,{'0'});
restrict = str2double(ReturnString3{1,1});

prompt4 = {'Do you want to write an auto-scored .txt file? (1 for yes, 0 for no)'};
ReturnString4 = inputdlg(prompt4,'Write File(s)?',1,{'1'});
writefile = str2double(ReturnString4{1,1});
% directory_plus_extension=strcat(directory,'*.txt');
% files=dir(directory_plus_extension);
% for i=length(files):-1:1                % don't autoscore files that have already been autoscored
% 	fname = files(i).name;
% 	if strfind(fname,'AUTOSCORED')
% 		files(i)=[];
% 	end
% end



for i=1:length(files)
	files{i}
	[predicted_score,dynamic_range(i),kappa(i),global_agreement(i),wake_agreement(i),SWS_agreement(i),REM_agreement(i)]=classify_usingPCA([directory files{i}],signal,already_scored_by_human,restrict,1,writefile);
	
clear predicted_score 
end


figure

if length(files)==1     % Case where only one file has been autoscored
	xplot=1:5;
	yplot=[wake_agreement SWS_agreement REM_agreement global_agreement kappa];
	plot(xplot,yplot,'.','MarkerSize',15)
	axis([0.5 5.5 min(yplot)-0.1 1])
	ax=gca;
	ax.XTick = [1,2,3,4,5];
	ax.XTickLabel = {'Wake','SWS','REM','Overall','Kappa'};
else
	boxplot([wake_agreement',SWS_agreement',REM_agreement',global_agreement',kappa'],'labels',{'Wake', 'SWS', 'REM', 'Overall', 'Kappa'}, ...
	'plotstyle','compact','boxstyle','filled','colors','rb');
	ax=gca();
end
	set(ax,'YGrid','on')
	title(directory)

agreement_stats.wake   = wake_agreement;
agreement_stats.SWS    = SWS_agreement;
agreement_stats.REM    = REM_agreement;
agreement_stats.global = global_agreement;
agreement_stats.kappa  = kappa;
