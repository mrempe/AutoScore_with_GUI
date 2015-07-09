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
% files = 'BA1214_Training.txt';
% files = {files};
% directory = 'D:\mrempe\';

prompt = {'Which Automated Scoring method do you want to use, NaiveBayes or RandomForest?', 'Do you want to use EEG1 or EEG2?', ...
'Do you want to restrict the dataset to only 8640 epochs? (1 for yes, 0 for no)','Do you want to write an auto-scored .txt file? (1 for yes, 0 for no)', ...
'Use all scored epochs as training data? (1 for yes, 0 for no)', 'Would you like to perform repeated trials using random subsets of the training data? (1 for yes, 0 for no)'};
defaults = {'NaiveBayes','EEG2','0','1','1','1'}; 
dlg_title = 'Input';
inputs = inputdlg(prompt,dlg_title,1,defaults,'on');

method = inputs{1};
signal = inputs{2};
restrict = str2double(inputs{3});
writefile = str2double(inputs{4});
use_all_as_training = str2double(inputs{5});
repeated_trials = str2double(inputs{6});

if repeated_trials & strcmp(method,'NaiveBayes')  % if you are doing NaiveBayes and you want to do repeated trials
	prompt2 = {'How many repeated trials would you like to perform for each file?', ...
	'When performing repeated trials, what fraction of the training data would you like to use?'};
	defaults2 = {'10','0.05'};
	dlg_title2 = 'Repeated Trials';
	inputs2=inputdlg(prompt2,dlg_title2,1,defaults2,'on');
	trials.number = str2double(inputs2{1});
	trials.fraction_training_data = str2double(inputs2{2});
else
	trials.number = 1;
	trials.fraction_training_data = 1;  %use 100% of training data
end


% trials.number = 10;
% trials.fraction_training_data = 0.05;

% signal='EEG2';
% restrict = 0;
% writefile = 0;
% use_all_as_training = 1;

% Handle the case where you don't use all the scored epochs as training data (ask for times of beginning and end of training data)
if use_all_as_training == 0
	prompt2 = {'Start of the training session (in hours from the start of the recording','End of the training session (in hours from the start of the recording'};
	defaults2 = {'26','30'};
	dlg_title2 = 'Training Data';
	training_times = inputdlg(prompt2,dlg_title2,1,defaults2,'on');
	training_start_time = str2double(training_times{1});
	training_end_time = str2double(training_times{2});
else 
	training_start_time = [];
	training_end_time = [];
end




% Run classify_usingPCA.m on each file
for i=1:length(files)
	files{i}
	[predicted_score,dynamic_range(i),kappa(i),global_agreement(i),wake_agreement(i),SWS_agreement(i),REM_agreement(i)]=classify_usingPCA([directory files{i}],method,signal,restrict,training_start_time,training_end_time,trials,writefile);
	
clear predicted_score 
end




if length(files)==1 && ~isnan(kappa)    % Case where only one file has been autoscored, and there is a kappa to plot (it has been fully scored by a human)
	figure
	xplot=1:5;
	yplot=[wake_agreement SWS_agreement REM_agreement global_agreement kappa];
	plot(xplot,yplot,'.','MarkerSize',15)
	axis([0.5 5.5 min(yplot)-0.1 1])
	ax=gca;
	ax.XTick = [1,2,3,4,5];
	ax.XTickLabel = {'Wake','SWS','REM','Overall','Kappa'};
	set(ax,'YGrid','on')	
	dir_in_title=regexprep(directory,'\\','\\\\');
	title(dir_in_title)
elseif length(files) > 1
	figure
	boxplot([wake_agreement',SWS_agreement',REM_agreement',global_agreement',kappa'],'labels',{'Wake', 'SWS', 'REM', 'Overall', 'Kappa'}, ...
	'plotstyle','compact','boxstyle','filled','colors','rb');
	ax=gca();
	set(ax,'YGrid','on')
	dir_in_title=regexprep(directory,'\\','\\\\');
	title(dir_in_title)
end
	

agreement_stats.wake   = wake_agreement;
agreement_stats.SWS    = SWS_agreement;
agreement_stats.REM    = REM_agreement;
agreement_stats.global = global_agreement;
agreement_stats.kappa  = kappa;

