function write_scored_file(filename,predicted_score)
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
% predicted_score    the output of classify.m generated in classify_usingPCA.m

% First copy the original file so we don't mess it up
 a = find(filename=='.');
 newfilename = strcat(filename(1:a-1), 'AUTOSCORED', filename(a:end));
 copyfile(filename,newfilename,'f');




% This is so I can use Jon's stuff 
%addpath ../../../../../../Brennecke/matlab-pipeline/Matlab/etc/matlab-utils/;
addpath 'C:\Users\wisorlab\Documents\MATLAB\Brennecke\matlab-pipeline\Matlab\etc\matlab-utils\'
%xl=XL('D:\mrempe\BL-118140Copy.txt');
xl=XL(newfilename);

sheet = xl.Sheets.Item(1);
[numcols,numrows] = xl.sheetSize(sheet);


% should I convert the numerical scores back into W,S and P/R?  
sleepstate_vec=cell(size(predicted_score));
for i=1:length(predicted_score)
	if predicted_score(i)==0
		sleepstate_vec{i}='W';
	elseif predicted_score(i)==1
		sleepstate_vec{i}='S';
	elseif predicted_score(i)==2
		sleepstate_vec{i}='R';
	elseif predicted_score(i)==5
		sleepstate_vec{i}='X';
	end
end


xl.setCells(sheet,[2,3],sleepstate_vec,'FFEE00');


a=find(newfilename=='\');
xl.saveAs(newfilename(a+1:end),newfilename(1:a));

fclose('all')  %so Excel doesn't think MATLAB still has the file open

