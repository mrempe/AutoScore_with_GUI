function write_agreement_file(txtfiles,directory,method,signal,restrict,writefile,use_all_as_training,repeated_trials,training_start_time,training_end_time,trials,kappa,global_agreement)
% USAGE: write_agreement_file(txtfiles,directory,method,signal,restrict,writefile,use_all_as_training,repeated_trials,kappa,global_agreement)
%
%
%
addpath 'C:\Users\wisorlab\Documents\MATLAB\Brennecke\matlab-pipeline\Matlab\etc\matlab-utils\'



% first find the most recent directory located in "directory"
files = dir(directory);
directories = files([files.isdir]);
isgood = ones(length(directories),1);
for i=1:length(directories)
	if strncmpi(directories(i).name,'.',1)  % if directory name starts with a period, disregard it
		isgood(i) = 0;
	end
end

directories = directories(find(isgood));
dates = [directories.datenum];
[~,newestIndex] = max(dates);
most_recent_directory = directories(newestIndex).name;

% now write an excel spreadsheet to most_recent_directory (this is just the name of the directory, not the entire path)
%xl=XL(strcat(directory,most_recent_directory,'\','agreement_stats.xls')); % this didn't work because the .xls file didn't exist yet. 
xl=XL;
%sheet = xl.Sheets.Item(1);
%[numcols,numrows] = xl.sheetSize(sheet);


sheet_agree = xl.addSheets({'Agreement'});
sheet_params = xl.addSheets({'Calling Parameters'});

%txt_file_names = dir(strcat(directory,'*.txt'));
%xl.setCells(sheet_agree{1},[1,2],{txt_file_names.name}','false','true');
xl.setCells(sheet_agree{1},[1,2],txtfiles','false','true');
xl.setCells(sheet_agree{1},[2,2],kappa');
xl.setCells(sheet_agree{1},[3,2],global_agreement');
xl.setCells(sheet_agree{1},[1,1],{'Files'},'669999');
xl.setCells(sheet_agree{1},[2,1],{'kappa'},'669999','true');
xl.setCells(sheet_agree{1},[3,1],{'Global Agreement'},'669999','true');

xl.setCells(sheet_params{1},[1,2],{'Method'});
xl.setCells(sheet_params{1},[1,3],{'Signal'});
xl.setCells(sheet_params{1},[1,4],{'Restricted to 8640 epochs?'});
xl.setCells(sheet_params{1},[1,5],{'Wrote an autoscored .txt file?'});
xl.setCells(sheet_params{1},[1,6],{'Used all scored epochs as training data?'});
xl.setCells(sheet_params{1},[1,7],{'Performed repeated trials using random subsets of training data?'},'false','true');
xl.setCells(sheet_params{1},[1,8],{'Start of training session (in hours from beginning of recording):'});
xl.setCells(sheet_params{1},[1,9],{'End of training session (in hours from beginning of recording):'});
xl.setCells(sheet_params{1},[1,10],{'Number of repeated trials performed per recording:'});
xl.setCells(sheet_params{1},[1,11],{'Fraction of training data used in repeated trials:'});

xl.setCells(sheet_params{1},[2,2],{method});
xl.setCells(sheet_params{1},[2,3],{signal});
xl.setCells(sheet_params{1},[2,4],restrict);
xl.setCells(sheet_params{1},[2,5],writefile);
xl.setCells(sheet_params{1},[2,6],use_all_as_training);
xl.setCells(sheet_params{1},[2,7],repeated_trials);
if isempty(training_start_time) 
	xl.setCells(sheet_params{1},[2,8],{'N/A'});
else
	xl.setCells(sheet_params{1},[2,8],training_start_time);
end
if isempty(training_end_time)
	xl.setCells(sheet_params{1},[2,9],{'N/A'});
else
	xl.setCells(sheet_params{1},[2,9],training_end_time);
end
xl.setCells(sheet_params{1},[2,10],trials.number);
xl.setCells(sheet_params{1},[2,11],trials.fraction_training_data);




xl.sourceInfo(mfilename('fullpath'));
xl.rmDefaultSheets();

xl.saveAs('agree_stats.xlsx',strcat(directory,most_recent_directory,'\'));
fclose('all');  %so Excel doesn't think MATLAB st