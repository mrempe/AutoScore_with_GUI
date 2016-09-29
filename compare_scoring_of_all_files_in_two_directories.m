function agreement = compare_scoring_of_all_files_in_two_directories
%
% USAGE: agreement = compare_scoring_of_all_files_in_two_directories
%
% This function works like compare_scoring_in_two_files.m, except it works on several 
% files, not just two.  It finds all the .txt files in directory dir1 and all the .txt files in 
% directory dir2 and computes global agreement and kappa for each pair of files. 
% 
% GUI input to select the two directories:
% 
% OUTPUT:
% agreement is a struct that has two fields: global and kappa.  Each is a vector with as many elements as files 

 dir1 = uigetdir('D:\','Please Select the directory containing the first set of .txt files');  
 dir2 = uigetdir('D:\','Please Select the directory containing the second set of .txt files'); 

% or just set the directories here:
% directory1 = 
% directory2=

files1 = dir(strcat(dir1,'\*.txt'));
files2 = dir(strcat(dir2,'\*.txt'));

 % if ~iscell(files1), files1 = {files1}; 
 % end

 % if ~iscell(files2), files2 = {files2}; 
 % end



if length(files1) ~= length(files2) 
	error('You must have the same number of .txt files in each directory')
end

for i=1:length(files1)
	files1(i).name
	files2(i).name
	[data1,textdata1]=importdatafile([dir1 '\' files1(i).name]);
 	[data2,textdata2]=importdatafile([dir2 '\' files2(i).name]);
	
	[agreement.global(i),wake_percent_agreement,SWS_percent_agreement,REM_percent_agreement]=compute_agreement({textdata1{:,2}},{textdata2{:,2}});
	agreement.kappa(i) = compute_kappa({textdata1{:,2}},{textdata2{:,2}});
end


