function write_scored_file_fast(FileToRead,output_directory,predicted_score)
%

% First, read in the entire file so we can re-write it with new scoring

 a = find(FileToRead=='.');
 d = find(FileToRead=='\');
 newfilename = strcat(output_directory,'\',FileToRead(d(end)+1:a(end)-1), 'AUTOSCORED', FileToRead(a(end):end));


%directory = FileToRead(1:d(end));
%filename=strcat(directory,FileToRead);
filename = FileToRead;

% read in the header info
fid=fopen(filename);                          
FirstLine = fgetl(fid);
SecondLine = fgetl(fid);

%header = {FirstLine; SecondLine};
DELIMITER = sprintf('\t','');     % tab delimited
NUM_COLUMNS = numel(strfind(FirstLine,DELIMITER)) + 1;    

% Read in the header info and store it in cell arrays of strings
tab_locs_line1 = strfind(FirstLine,DELIMITER);
tab_locs_line2 = strfind(SecondLine,DELIMITER);

header_line1{1} = FirstLine(1:tab_locs_line1(1)-1);
for i=1:length(tab_locs_line1)-1
	header_line1{i+1} = FirstLine(tab_locs_line1(i)+1:tab_locs_line1(i+1)-1);
end
header_line1{length(tab_locs_line1)+1} = FirstLine(tab_locs_line1(end)+1:end-1);

header_line2{1} = SecondLine(1:tab_locs_line2(1)-1);
for i=1:length(tab_locs_line2)-1
	header_line2{i+1} = SecondLine(tab_locs_line2(i)+1:tab_locs_line2(i+1)-1);
end
header_line2{length(tab_locs_line2)+1} = SecondLine(tab_locs_line2(end)+1:end-1);




format=['%s%s' repmat('%f', [1 NUM_COLUMNS-2])];    % minus 2 for the 2 columns of text
c=textscan(fid,format,'Delimiter',DELIMITER,'CollectOutput',1,'ReturnOnError',0);
textdata=c{1};
data=c{2};
fclose(fid);

% remove quotes from timestamp in textdata
for i=1:size(textdata,1)
	textdata{i,1} = strrep(textdata{i,1},'"','');
end

% Now change the second column of textdata to be the new scoring
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

textdata(:,2) = sleepstate_vec';


% Now put the header, data and textdata into one big cell array
data_cell = num2cell(data);   % convert the matrix data into a cell
text_and_num_data = [textdata data_cell];   % concatenate the text and numeric data
C=[header_line1; header_line2; text_and_num_data];


% write to an excel file using XL.m

xl=XL;
sheet = xl.Sheets.Item(1);
[numcols,numrows] = xl.sheetSize(sheet);
xl.setCells(sheet,[1,1],C);

a=find(newfilename=='\');
xl.saveAs(newfilename(a+1:end),newfilename(1:a));
fclose('all');  %so Excel doesn't think MATLAB still has the file open

% Finally, write the cell array to a tab-delimited .txt file using dlmcell.m

%a=find(newfilename=='\');
%xl.saveAs(newfilename(a+1:end),newfilename(1:a));
%dlmcell(newfilename,C);   % this worked, but it was way too slow.   
