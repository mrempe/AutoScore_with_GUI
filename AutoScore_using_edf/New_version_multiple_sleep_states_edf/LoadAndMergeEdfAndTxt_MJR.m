function [fileHeader,channelHeader,data,state,fs,textdata,epoch_length]=LoadAndMergeEdfAndTxt_MJR(inputFile,dataStartInSeconds,dataStopInSeconds);
% usage: [fileHeader,channelHeader,data,state,fs,textdata,epoch_length]=LoadAndMergeEdfAndTxt_MJR(inputFile,<dataStartInSeconds>,<dataStopInSeconds>);
%
%
% This file was modified from Jonathan Wisor's LoadAndMergeEdfAndTxt.m which also returned state transitions.
% It is used to merge EEG and EMG data from an .edf file with the partial scoring data located in a text file with .txt extension.
% Then both can be used in automated scoring.  
%
% 
% -- INPUTS --
%
% inputFile:        This is the name of an .edf file that you want to merge scoring with.  NOTE: there must be a .txt file with the same name 
%                   in the same directory. 
%
% dataStartInSeconds (optional)     If you don't want to return all of the data, you can start this many seconds from the beginning.
%
% dataStopInSeconds (optional)      If you don't want to return all of the data, you can stop this many seconds from the beginning.
%
%
% -- OUTPUTS --
% 
% fileHeader:       This is the standard edf header read from blockEdfLoad with the addition of the sleep state vector in char format.  Each letter 
%                   represents the state: (W for wake, R for REMS, S for SWS and Z added at the beginning and possibly the end if the .txt file 
%                   doesn't quite line up with the .edf)
% 
% channelHeader:    A struct array with as many elements as there are signals present in the .edf.  The struct has the following fields:
%                   signal_labels
%                   tranducer_type
%                   physical_dimension
%                   physical_min
%                   physical_max
%                   digital_min
%                   digital_max
%                   prefiltering
%                   samples_in_record
%                   reserve_2
%
%
% data:             A cell array with as many elements are signals in the .edf.  Each entry in the cell array is a vector of the raw data. 
%
% state:            A char array with the state after removing the parts of the .edf that are before or after the timestamps in the .txt file.  
%                   state has as many elements as each cell in "data".
% 
% fs:               A vector of the sampling frequencies (one for each channel present) (measured in Hz)
%
% textdata:         A cell array containing the timestamps and scoring, this is passed out of the function so I can construct the TimeStampMatrix
%
% epoch_length:     The epoch length (in seconds) as read from the .txt file
%                
%
%  NOTE:   A MAJOR DIFFERENCE BETWEEN THIS FUNCTION AND THE ONE JONATHAN WROTE IS THAT UNSCORED EPOCHS ARE LEFT EMPTY, NOT FILLED WITH 'W'.
%
%


addpath '\\FS1\WisorData\MATLAB\Brennecke\matlab-pipeline\Matlab\etc\matlab-utils';   % This is where importdatafile.m lives

if nargin == 2
    dataStopInSeconds = Inf;
end

if nargin == 1
    dataStartInSeconds = 0;
    dataStopInSeconds  = Inf;
end

% First read in the EDF
[fileHeader channelHeader allData] = blockEdfLoad(inputFile);

EdfStartTime = [(str2num(fileHeader.recording_startdate(7:8))+2000),str2num(fileHeader.recording_startdate(4:5)),str2num(fileHeader.recording_startdate(1:2)),...
    str2num(fileHeader.recording_starttime(1:2)),str2num(fileHeader.recording_starttime(4:5)),str2num(fileHeader.recording_starttime(7:8))]
EdfEndTime = datevec(addtodate(datenum(EdfStartTime),fileHeader.num_data_records*fileHeader.data_record_duration,'second'))

% EdfEndTime=[(str2num(fileHeader.recording_startdate(7:8))+2000),str2num(fileHeader.recording_startdate(4:5)),str2num(fileHeader.recording_startdate(1:2)),...
%     str2num(fileHeader.recording_starttime(1:2)),str2num(fileHeader.recording_starttime(4:5)),str2num(fileHeader.recording_starttime(7:8))];
     stateVectorLength = length(allData{1,1});

for ChannelCount=1:size(allData,2)
    stateVectorLength = max(stateVectorLength,length(allData{1,ChannelCount}));
    fs(ChannelCount)  = channelHeader(ChannelCount).samples_in_record/fileHeader.data_record_duration;
end

fileHeader.sleepState = cell(stateVectorLength,1);
%fileHeader.sleepState(1:stateVectorLength)={'Z'};
[fileHeader.sleepState{:}] = deal('Z');
%allStatesMerged=char(fileHeader.sleepState);
allStatesMerged = fileHeader.sleepState;
disp(['size of allStatesMerged at beginning: ' ,num2str(size(allStatesMerged))])

%allStatesMerged = cell(length(fileHeader.sleepState),1);
%[allStatesMerged{:}] = deal(char(fileHeader.sleepState)};


StateTransitionsMerged=char(fileHeader.sleepState);

txtName=strrep(inputFile,'.edf','.txt');
if exist(txtName)
    [junk,textdata]=importdatafile(txtName);  % We could make this faster by only reading in just the scoring rather than the whole file.  
    clear junk
   

    TxtStartTime = datevec(regexprep(char(textdata(1,1)),'(\w+)M',''))
    TxtEndTime   = datevec(regexprep(char(textdata(end,1)),'(\w+)M',''))
    TxtSecondEpochTime = datevec(regexprep(char(textdata(2,1)),'(\w+)M',''))
    
    % handle non-military time (since EDF is always in military time)
    if TxtStartTime(4) < 12 & strcmp(strtrim(textdata{1,1}(end-2:end)),'PM')
        TxtStartTime(4) = TxtStartTime(4) + 12;
    end
    if TxtEndTime(4) < 12 & strcmp(strtrim(textdata{end,1}(end-2:end)),'PM')
        TxtEndTime(4) = TxtEndTime(4) + 12;
    end
    if TxtSecondEpochTime(4) < 12 & strcmp(strtrim(textdata{2,1}(end-2:end)),'PM')
        TxtSecondEpochTime(4) = TxtSecondEpochTime(4) + 12;
    end 
% if hour is 
     if TxtStartTime(4) == 12 & strcmp(strtrim(textdata{1,1}(end-2:end)),'AM')
        TxtStartTime(4) = 0;
    end
    if TxtEndTime(4) == 12 & strcmp(strtrim(textdata{end,1}(end-2:end)),'AM')
        TxtEndTime(4) = 0;
    end
    if TxtSecondEpochTime(4) == 12 & strcmp(strtrim(textdata{2,1}(end-2:end)),'AM')
        TxtSecondEpochTime(4) = 0;
    end 

    StartDifference = etime(TxtStartTime,EdfStartTime);
    EndDifference   = etime(EdfEndTime,TxtEndTime);
     %etime(T1,T0) returns the time IN SECONDS that has elapsed between vectors T1 and T0.
    epoch_length = etime(TxtStartTime,TxtSecondEpochTime);
    if epoch_length < 0
        epoch_length = -epoch_length;
    end

   disp(['textdata(1) before filling in missing: ', textdata(1,:)])
   % Fill in any missing gaps in text file
   textdata = fill_in_missing_epochs(textdata,epoch_length,TxtStartTime,TxtEndTime);

    disp(['textdata(1) after filling in missing: ', textdata(1,:)])
   % Make sure the start times and end times match up between txt and edf files, if not, fill in timestamps in the txt file
   textdata = expand_txt_timestamps_to_match_edf(EdfStartTime,EdfEndTime,textdata,epoch_length);


    if dataStopInSeconds == Inf
        dataStopInSeconds = etime(TxtEndTime,TxtStartTime);  % If no ending time is given, go to end of .txt file 
    end
    

    %allStatesTxt(1:numel(textdata(:,2))*fileHeader.data_record_duration*max(fs))='Z';
   allStatesTxt = cell(1,numel(textdata(:,2))*fileHeader.data_record_duration*max(fs));
   [allStatesTxt{:}]=deal('Z');   % Set them all to Z to begin with



    for EpochCounter=1:numel(textdata(:,2))
        if isempty(char(textdata(EpochCounter,2))) | strcmp(textdata(EpochCounter,2),'Z')
            [allStatesTxt{(EpochCounter-1)*fileHeader.data_record_duration*max(fs)+1:EpochCounter*fileHeader.data_record_duration*max(fs)}]=deal('');
            else
            [allStatesTxt{(EpochCounter-1)*fileHeader.data_record_duration*max(fs)+1:EpochCounter*fileHeader.data_record_duration*max(fs)}]=deal(char(textdata(EpochCounter,2)));
        end
    end
   StartDifference*max(fs)+1
   StartDifference*max(fs)+numel(allStatesTxt)
   
% Handle differences in starting times
if StartDifference<epoch_length  % If the difference between the text file and the edf file is less than 1 epoch, don't expand 
    StartDifference = 0;
end 
   allStatesMerged(StartDifference*max(fs)+1:StartDifference*max(fs)+numel(allStatesTxt)) = allStatesTxt(1:end);
   
% Handle differences in ending times
   % USE EndDifference here to add these points to allStatesMerged  
    %allStatesMerged(StartDifference*max(fs)+1:StartDifference*max(fs)+numel(allStatesTxt)) = allStatesTxt(1:end);


end
size(allStatesMerged)
stateVectorLength

fileHeader.sleepState(1:stateVectorLength)=allStatesMerged;

%if StartDifference*max(fs)+dataStopInSeconds*max(fs) < length(allStatesMerged) 
    state=allStatesMerged(StartDifference*max(fs)+dataStartInSeconds*max(fs)+1:StartDifference*max(fs)+dataStopInSeconds*max(fs)+epoch_length*max(fs));
%else
    %state=allStatesMerged(StartDifference*max(fs)+dataStartInSeconds*max(fs)+1:end);
%end

for signalCount=1:size(channelHeader,2)
    %if StartDifference*fs(signalCount)+dataStopInSeconds*fs(signalCount) < length(allData{1,signalCount})
        %data{signalCount}=allData{1,signalCount}(StartDifference*fs(signalCount)+dataStartInSeconds*fs(signalCount)+1:StartDifference*fs(signalCount)+dataStopInSeconds*fs(signalCount)+epoch_length*fs(signalCount));
        data{signalCount}=allData{1,signalCount}(StartDifference*fs(signalCount)+dataStartInSeconds*fs(signalCount)+1:StartDifference*fs(signalCount)+dataStopInSeconds*fs(signalCount));

    % else
    %     data{signalCount}=allData{1,signalCount}(StartDifference*fs(signalCount)+dataStartInSeconds*fs(signalCount)+1:end);
    % end
end


