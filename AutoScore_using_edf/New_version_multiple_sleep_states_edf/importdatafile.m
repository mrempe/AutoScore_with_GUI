function [data,textdata]=importdatafile(FileToRead,directory,starting_epoch,ending_epoch)
% usage: [data,textdata]=importdatafile(FileToRead,directory)
%
% this function uses textscan to read in a .txt data file
% and convert it to two matrices, one for numeric data and 
% one for text
% textscan is more robust than importdata.m as textscan 
% will not quit like importdata does if there is missing data
%
% Also, I'm adding some code to check for negative lactate values 
% at the end of the file, and to cut off the file before the 
% negative values if they exist.  
%
% INPUTS:
%      FileToRead       The tab-delimited .txt file containing timestamps, sleep state, and EEG power, and EMG
%
%      directory        location of the .txt file that is being read in
%
%      starting_epoch   (optional) The starting epoch if you are restricting the dataset
%
%      ending_epoch     (optional) The ending epoch if you are restricting the dataset

%OUTPUTS:
%      data     This is a matrix containing 2 fewer rows than
%               the original .txt file with only the numeric
%               data.  

%      textdata This is a cell array containing the strings in 
%               columns 1 and 2 of the data file (timestamp and sleep state)
%               NOTE1: use curly brackets to access elements in 
%               textdata. i.e. textdata{3,2} for the sleep state 
%               on line 3.  
%               NOTE2: textdata has already had the first two
%               rows removed.  It is just strings on lines 
%               containing EEG data. 
%               NOTE3: this file handles swapping of the columns to ensure that the time stamps are in the
%               first column and the sleep state is in the second column, no matter what.  

if nargin == 1 
	directory = '';
    starting_epoch = 1;
    ending_epoch   = Inf;
end

if nargin == 2
    starting_epoch = 1;
    ending_epoch   = Inf;
end

if nargin == 3
    ending_epoch   = Inf;
end





DELIMITER = sprintf('\t','');     % tab delimited
%HEADERLINES = 2-1;               % there are 2 header lines, but one gets read in the call to fgetl before textscan is called
HEADERLINES = 0;               


filename=strcat(directory,FileToRead);

fid=fopen(filename);                          % compute number of columns present
tLines = fgetl(fid);
NUM_COLUMNS = numel(strfind(tLines,DELIMITER)) + 1;    


format=['%s%s' repmat('%f', [1 NUM_COLUMNS-2])];    % minus 2 for the 2 columns of text
%format=['%s',repmat('%f',1,NUM_COLUMNS)];
% Handle the cases of a variable number of header lines. Keep scanning until you get a 
% row with a : in it.  Then keep that row and concatenate it onto c since once lines 
% are read with fgetl they disappear
while isempty(strfind(tLines,':'))
    tLines = fgetl(fid);
end 


c=textscan(fid,format,'Headerlines',HEADERLINES,'Delimiter',DELIMITER,'CollectOutput',1,'ReturnOnError',0);

% Now concatenate the one line that was absorbed by fgetl above
tab_loc = strfind(tLines,sprintf('\t'));
first_line = cell(1,2);
first_line{1} = tLines(1:tab_loc(1)-1);
if length(tab_loc)==1
    first_line{2} = tLines(tab_loc(1)+1:end);
else 
    first_line{2} = tLines(tab_loc(1)+1:tab_loc(2)-1);
end 


textdata=c{1};
textdata=[first_line; textdata];
data = [];
if numel(c) >1  %If physiological data are included, not just time stamps and sleep states
    data=c{2};
    has_physio_data = 1;
end  

fclose(fid);

if ~isempty(strfind(textdata{1,1},':')) % determine if the timestamps are in the first column or second.
    statechars=char(textdata(:,2));
else 
    statechars = char(textdata(:,1));
    textdata   = textdata(:,[2 1]);  % swap the columns in textdata if the state is in first column and timestamp in second
end 
if length(find(statechars=='P')) > 0
    charseq=(['File ' filename ' has P as a state.  May we convert to R?']);
    prompt = { charseq };
    %PtoR = inputdlg(prompt,'Input',1,{'Y'});
    PtoR= timeoutdlg(@inputdlg, 30, prompt,'Input',1,{'Y'});
                               
    PtoRScore=char(PtoR);
    if PtoRScore=='Y'
        statechars(statechars=='P')='R';
        cellchars=cellstr(statechars);
        textdata(:,2)=cellchars;
    end
end


if ~isempty(data)
    % finally, remove epochs not wanted (if starting epoch and/or ending epoch were specified)
    if starting_epoch ~= 1 & ending_epoch == Inf
        data = data(starting_epoch:end,:);
        textdata = textdata(starting_epoch:end,:);
    end

    if ending_epoch ~= Inf
        if ending_epoch > length(data)
            data = data(starting_epoch:end,:);
            textdata = textdata(starting_epoch:end,:);
        else 
            data = data(starting_epoch:ending_epoch,:);
            textdata = textdata(starting_epoch:ending_epoch,:);
        end 
    end 
end 
% check for negative values in the lactate signal (first
% column of data) at the beginning or the end of 
% the file.  If so, cut off that data

% first find all locations where lactate < 0 and
% remove them from data and textdata
%locations=find(data(:,1)<0);
%data(locations,:)=[];
%textdata(locations,:)=[];

