function filled_in_textfile = fill_in_missing_epochs(textdata,epoch_length,TxtStartTime,TxtEndTime)
%
% USAGE: filled_in_textfile = fill_in_missing_epochs(textdata)
%
% This function reads in a cell array of text data that was output from importdatafile.m 
% and determines if there are any missing epochs.  If so, the timestamps are filled
% in. 
%
% This is needed when doing autoscoring with an .edf file because if chunks 
% of time have been left out of the text file, it will not match up with 
% the .edf, even if the starting and ending times are correct.  




textdata2=textdata;
i=2;

correct_num_epochs = etime(TxtEndTime,TxtStartTime)/epoch_length+1

while i<=correct_num_epochs

	while etime(datevec(regexprep(char(textdata2(i,1)),'(\w+)M','')),datevec(regexprep(char(textdata2(i-1,1)),'(\w+)M',''))) ~= epoch_length  
		% insert element here
		textdata2(i+1:end+1,:) = textdata2(i:end,:);
		current_time = datevec(regexprep(char(textdata2(i-1,1)),'(\w+)M',''));
		newtime=datevec(addtodate(datenum(current_time),epoch_length,'second'));
		new_time_string_formated = sprintf('%.2d/%.2d/%d %.2d:%.2d:%.2d',newtime(2),newtime(3), ... 
											newtime(1),newtime(4),newtime(5),newtime(6));
		textdata2(i,:) = {new_time_string_formated,''}; 
		
		i=i+1;
	end 
	i=i+1;
end 
% another way to set the last time to TxtEndtime?  explicitly? 
%textdata2(correct_num_epochs,1) = sprintf('%d/%d/%d %.2d:%.2d:%.2d',TxtendTime(2),TxtendTime(3), ... 
										%TxtendTime(1),TxtendTime(4),TxtendTime(5),TxtendTime(6));


filled_in_textfile = textdata2;  