function agreement_between_two = compare_scoring_in_two_files
% 
%
% USAGE: agreement_between_two = compare_scoring_in_two_files
%
% This simple function computes agreement stats for two .txt files. 
% It opens a GUI where you select the two .txt files
% that you wish to compare and pulls out the scoring data and 
% calls compute_kappa.m and compute_agreement.m 
% 



% GUI to read in two files 
 [files{1},directory1] = uigetfile('D:\*.txt','Please Select the first txt file to compare');  %last parameter sent to uigetfile ('*.edf*) specifies that only edf files will be displayed in the user interface.
 [files{2},directory2] = uigetfile('D:\*.txt','Please Select the first txt file to compare');  %last parameter sent to uigetfile ('*.edf*) specifies that only edf files will be displayed in the user interface.

 if ~iscell(files), files = {files}; 
 end

 if length(files) ~= 2
 	error('You must select two and only two .txt files to compare')
 end

% Make sure both files are fully scored! (and give an error message if that's not true)


% extract the data from each file
 [data1,textdata1]=importdatafile([directory1 files{1}]);
 [data2,textdata2]=importdatafile([directory2 files{2}]);

% NOTE: these agreements stats may be off because a lot depends on which file is considered the standard. 
% compute_agreement.m was made to compare human scoring to machine scoring and it considers human scoring the standard.
% this doesn't really make sense when comparing two different human scorers, so just use kappa.  
[global_agreement,wake_percent_agreement,SWS_percent_agreement,REM_percent_agreement]=compute_agreement({textdata1{:,2}},{textdata2{:,2}});

agreement_between_two.global = global_agreement;


% Now compute kappa
agreement_between_two.kappa = compute_kappa({textdata1{:,2}},{textdata2{:,2}});

