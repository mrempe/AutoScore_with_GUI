i=2;

while i<correct_length
	while test(i)-test(i-1) ~=1
		test=[test(1:i-1) test(i-1)+1 test(i:end)]
		i=i+1
	pause
	end
	i=i+1
pause
end



% Now for use on textdata
textdata2=textdata;
i=2;
correct_num_epochs = etime(TxtEndTime,TxtStartTime)/epoch_length

while i<correct_num_epochs

	while etime(datevec(regexprep(char(textdata2(i,1)),'(\w+)M','')),datevec(regexprep(char(textdata2(i-1,1)),'(\w+)M',''))) ~= epoch_length  
		% insert element here
		textdata2(i+1:end+1,:) = textdata2(i:end,:);
		textdata2(i,:) = {};  % just try inserting blank element for now. 
		i=i+1;
	end 
	i=i+1;
end 
