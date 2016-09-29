function TimeStampMatrix=create_TimeStampMatrix_from_textdata(textdata)



% for some reason it seems that this only works if the options containing fewer charaters are tried first. 
% if the input had 10:00:00 only, (without a date) and I put sscanf(textdata{i,1},'%f:%f:%f') at the end, the second
% try statement would be executed and TimeStampMatrix would have only one row.  


% New try: set up TimeStampMatrix as a struct with fields Day, Month,Year,Hour,Minute and Second.  This will make it more
% robust to call it.  TimeStampMatrix(i).Hour rather than TimeStampMatrix(4,:) representing hour.  


slash_locs = strfind(textdata{1,1},'/');
colon_locs = strfind(textdata{1,1},':');

%if ~isempty(slash_locs) & length(slash_locs)==2 & slash_locs(2)-slash_locs(1) > 2  % case where there are 2 slashes and double-digit 
  month_loc = slash_locs(1)-2:slash_locs(1)-1;  % month info is found in 2 positions to the left of first slash
  day_loc = slash_locs(1)+1:slash_locs(1)+2;
  year_loc = slash_locs(2)+1:slash_locs(2)+4;
%end

%if slash_locs(2)-slash_locs(1) ==2 & slash_locs(1) ==2  % case where only one digit was used for day and month: m/d/yyyy
  month_loc = 1:slash_locs(1)-1;
  day_loc   = slash_locs(1)+1:slash_locs(2)-1;
  year_loc  = slash_locs(2)+1:slash_locs(2)+4;

hour_loc = colon_locs(1)-2:colon_locs(1)-1;  % hour info is found in 2 positions to the left of first colon
minute_loc = colon_locs(2)-2:colon_locs(2)-1; 
second_loc = colon_locs(2)+1:colon_locs(2)+2; 

 % Day, Month Year
if isempty(slash_locs)
  TimeStampMatrix(1).Day =[];
  TimeStampMatrix(1).Month=[];
  TimeStampMatrix(1).Year=[];
  else
    TimeStampMatrix(1).Day = str2num(textdata{1,1}(day_loc));
    TimeStampMatrix(1).Month = str2num(textdata{1,1}(month_loc));
    TimeStampMatrix(1).Year = str2num(textdata{1,1}(year_loc));
  end

% Hour, Minute, Seconds
TimeStampMatrix(1).Hour = str2num(textdata{1,1}(hour_loc));
TimeStampMatrix(1).Minute = str2num(textdata{1,1}(minute_loc));
TimeStampMatrix(1).Second = str2num(textdata{1,1}(second_loc));


% loop through all the rows of textdata
for i=2:length(textdata)
  if ~isempty(slash_locs)
    TimeStampMatrix(i).Day = str2num(textdata{i,1}(day_loc));
    TimeStampMatrix(i).Month = str2num(textdata{i,1}(month_loc));
    TimeStampMatrix(i).Year = str2num(textdata{i,1}(year_loc));
  end
  TimeStampMatrix(i).Hour = str2num(textdata{i,1}(hour_loc));
  TimeStampMatrix(i).Minute = str2num(textdata{i,1}(minute_loc));
  TimeStampMatrix(i).Second = str2num(textdata{i,1}(second_loc));
end





% % Try just one line first and use that to set the format for the rest of the lines
%   try
%     TimeStampMatrix(:,1) = sscanf(textdata{1,1},'%f:%f:%f');
%   catch exception1
%     if exist('exception1') ~= 1 format = '%f:%f:%f'; end
%       try
%         TimeS1ampMatrix(:,1) = sscanf(textdata{1,1},'"%f:%f:%f"');
%       catch exception2
%         if exist('exception2') ~= 1 format = '"%f:%f:%f"'; end
%           try
%             TimeStampMatrix(:,1) = sscanf(textdata{1,1},'"%f/%f/%f,%f:%f:%f"');
%           catch exception3
%             if exist('exception3') ~= 1 format = '"%f/%f/%f,%f:%f:%f"'; end
%               try 
%                 TimeStampMatrix(:,1) = sscanf(textdata{1,1},'%f/%f/%f,%f:%f:%f');
%               catch exception4 
%                 if exist('exception4') ~= 1 format ='%f/%f/%f,%f:%f:%f' ; end
%                   try   
%                     TimeStampMatrix(:,1) = sscanf(textdata{1,1},'%f/%f/%f %f:%f:%f');  
%                   catch exception5
%                     if exist('exception5') ~= 1 format = '%f/%f/%f %f:%f:%f' ; end
%                       try
%                         TimeStampMatrix(:,1) = sscanf(textdata{1,1},'"""%f/%f/%f,%f:%f:%f"""');
%                       catch exception6
%                         if exist('exception6') ~= 1 format = '"""%f/%f/%f,%f:%f:%f"""'  ; end
%                         end
%                       end
%                     end
%                   end  
%                 end
%               end




% for i=2:length(textdata)
%   TimeStampMatrix(:,i) = sscanf(textdata{i,1},format);
% end