function new_textdata = expand_txt_timestamps_to_match_edf(edfstarttime,edfendtime,textdata,epoch_length)
%
% USAGE:  new_textdata = expand_txt_timestamps_to_match_edf(edfstarttime,edfendtime,textdata,epoch_length)
%
%
% This function checks to see if the edf file starts before the txt file with the training data 
% and/or ends after the txt file.  If either of these are true, this function expands
% the textdata cell array to include all the epochs from the beginning to the end of the edf data,
% leaving the state variable blank for all the new epochs.
%
%
%
% INPUTS: 
%	edfstarttime: 		start time of the edf in datevec format
%   edfendtime:			end time of the edf in datevec format
%   textdata:			a cell array with two columns containing the sleep state in one column and timestamp in the other
%   epoch_length:		epoch length in seconds
%
%


txtstarttime = datevec(regexprep(char(textdata(1,1)),'(\w+)M',''));
txtendtime   = datevec(regexprep(char(textdata(end,1)),'(\w+)M',''));

disp(['size of textdata at start of expand: ' num2str(size(textdata))])
txtstarttime
edfstarttime
epoch_length

% First, compare start times of the text file and edf file
if etime(txtstarttime,edfstarttime) > epoch_length
	disp('in loop changing start of txt data')
	num_timestamps_to_add = floor(etime(txtstarttime,edfstarttime)/epoch_length);
	
	new_time{1} = datevec(addtodate(datenum(txtstarttime),-epoch_length*num_timestamps_to_add,'second'));
	new_timestamps_formated{1,1} = sprintf('%.2d/%.2d/%d %.2d:%.2d:%.2d',new_time{1}(2),new_time{1}(3), ... 
											new_time{1}(1),new_time{1}(4),new_time{1}(5),new_time{1}(6));
	new_timestamps_formated{1,2} = '';  % fill in an empty sleep state 
	for i=1:num_timestamps_to_add-1
		new_time{i+1}=datevec(addtodate(datenum(new_time{i}),epoch_length,'second'));
		new_timestamps_formated{i+1,1} = sprintf('%.2d/%.2d/%d %.2d:%.2d:%.2d',new_time{i+1}(2),new_time{i+1}(3), ... 
											 new_time{i+1}(1),new_time{i+1}(4),new_time{i+1}(5),new_time{i+1}(6));
		new_timestamps_formated{i+1,2} = '';  % empty sleep state
	end 

	textdata = [new_timestamps_formated; textdata];
end 


% Second, compare end times of the text file and edf file
if etime(edfendtime,txtendtime)> epoch_length
	disp('in loop changing end of txt data')
	num_timestamps_to_add = fix(etime(edfendtime,txtendtime)/epoch_length);
	new_time{1} = datevec(addtodate(datenum(txtendtime),epoch_length,'second'));;
	new_timestamps_end_formated{1,1} = sprintf('%.2d/%.2d/%d %.2d:%.2d:%.2d',new_time{1}(2),new_time{1}(3), ... 
											new_time{1}(1),new_time{1}(4),new_time{1}(5),new_time{1}(6));

	new_timestamps_end_formated{1,2}='';
	for i=1:num_timestamps_to_add-1
		new_time{i+1} = datevec(addtodate(datenum(new_time{i}),epoch_length,'second'));;
		new_timestamps_end_formated{i+1,1}=sprintf('%.2d/%.2d/%d %.2d:%.2d:%.2d',new_time{i+1}(2),new_time{i+1}(3), ... 
											 new_time{i+1}(1),new_time{i+1}(4),new_time{i+1}(5),new_time{i+1}(6));
		new_timestamps_end_formated{i+1,2} = '';  % empty sleep state
	end 
	size(textdata)
	size(new_timestamps_end_formated)
	textdata = [textdata; new_timestamps_end_formated];
end 

new_textdata = textdata;
disp(['size of textdata at end of expand: ' num2str(size(textdata))])





