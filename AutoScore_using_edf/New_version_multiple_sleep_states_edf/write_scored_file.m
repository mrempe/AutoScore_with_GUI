function write_scored_file(filename,directory,predicted_score,unique_sleep_states,textdata)
%
% Usage: write_scored_file(filename,predicted_score)
%
%
% This function simply replaces the sleep score column in 
% the file "filename" with the autoscore values generated from classify.m
% The result is written into a new file with the word AUTOSCORED in its name. 
%
% inputs:
% filename           .txt file from which we are overwriting the sleep state info, but keeping everything else
% directory:		 the directory where the autoscored file will be written.
% predicted_score    the output of classify.m generated in classify_usingPCA.m
%
% I need to read in textdata, and I can't just overwrite the scores, because they may have left out 
% some epochs.  textdata contains all the epochs in the corresponding edf, so I will 
% write that vector to the file 
%
%


% First copy the original file so we don't mess it up
 a = find(filename=='.');
 d = find(filename=='\' | filename=='/');
 newfilename = strcat(directory,'\',filename(d(end)+1:a(end)-1), 'AUTOSCORED', filename(a(end):end));
 copyfile(filename,newfilename,'f');

disp(['length of predicted_score in write_scored_file is:' num2str(length(predicted_score))])

% This is so I can use Jon's stuff 
%addpath ../../../../../../Brennecke/matlab-pipeline/Matlab/etc/matlab-utils/;
%addpath 'C:\Users\wisorlab\Documents\MATLAB\Brennecke\matlab-pipeline\Matlab\etc\matlab-utils\'
%xl=XL('D:\mrempe\BL-118140Copy.txt');

xl=XL(newfilename);

sheet = xl.Sheets.Item(1);
[numcols,numrows] = xl.sheetSize(sheet);


% should I convert the numerical scores back into W,S and P/R?  
sleepstate_vec=cell(size(predicted_score));
% for i=1:length(predicted_score)
% 	if predicted_score(i)==0
% 		sleepstate_vec{i}='W';
% 	elseif predicted_score(i)==1
% 		sleepstate_vec{i}='S';
% 	elseif predicted_score(i)==2
% 		sleepstate_vec{i}='R';
% 	elseif predicted_score(i)==3
% 		sleepstate_vec{i}='Tr';
% 	elseif predicted_score(i)==5
% 		sleepstate_vec{i}='X';
% 	end
% end

if isempty(unique_sleep_states{1}) 
	has_unscored = 1;
else 
	has_unscored = 0;
end


for i=1:length(predicted_score)
	sleepstate_vec{i}=unique_sleep_states{predicted_score(i)+has_unscored};
end

% determine which column the scoring should go in, and determine how many rows were in the 
% the header information
% how many header rows? Find a the first row with a colon
fid=fopen(filename);                         
tLines = fgetl(fid);
start_row = 1;
while isempty(strfind(tLines,':'))
    tLines = fgetl(fid);
	start_row = start_row + 1;
end 

% which column are the timestamps in? Find the column with a colon
c=textscan(fid,'%s%s',1,'headerlines',0);
first_data_row = c{1};  %first data row is a cell array now.
if ~isempty(strfind(first_data_row{1,1},':')) %If the first column has a colon, it has the timestamps and the  
	state_column = 2;
	timestamp_column =1;
else
	state_column = 1;
	timestamp_column = 2;
end 


xl.setCells(sheet,[state_column,start_row],sleepstate_vec,'FFEE00');
xl.setCells(sheet,[timestamp_column,start_row],textdata(:,1));
%xl.setCells(sheet,[2,3],sleepstate_vec,'FFEE00');


a=find(newfilename=='\');
xl.saveAs(newfilename(a+1:end),newfilename(1:a));
fclose('all');  %so Excel doesn't think MATLAB still has the file open

