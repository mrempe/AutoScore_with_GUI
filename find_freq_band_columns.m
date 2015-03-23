function [delta_columns,theta_columns,low_beta_columns,high_beta_columns,beta_columns,EMG_column]=find_freq_band_columns(filename,keyword)
%
% USAGE: [delta_columns,theta_columns,low_beta_columns,high_beta_columns,beta_columns,EMG_column]=find_freq_band_columns(filename)
%
% This function reads in the file "filename" and finds the columns of data that correspond to delta, theta, lowa-beta, high-beta, and EMG
% using either EEG1 or EEG2
% 
% INPUTS:
% filename: the name of a .txt file that is tab-delimited that has timestamp in the first column, and has header columns containing the 
% keyword EEG 1 or EEG 2 in addition to a frequency range (ie 1-2 Hz)
%
% keyword:  either EEG1 or EEG2.  This function looks for this keyword in the header
%
% OUTPUT: the column numbers (of the matrix "data") where the delta data are, the theta data, the low_beta data, and the high_beta data
% where delta = 1-4 Hz
% 		theta = 5-9 Hz
%		low beta = 10-20 Hz
%		high beta = 30-40 Hz
%       beta = 15-30 Hz 


% Find the columns with EEG1 1-2 Hz and EEG2 1-2 Hz  
  fid = fopen(filename);
  tLine1 = fgetl(fid);
  tLine2 = fgetl(fid);
  ColumnsHeads = textscan(tLine1,'%s','delimiter', sprintf('\t'));
  HeadChars=char(ColumnsHeads{1,1});
  for i=1:length(HeadChars)
    EEG1(i)=~isempty(strfind(HeadChars(i,:),'EEG 1'));
    EEG2(i)=~isempty(strfind(HeadChars(i,:),'EEG 2'));
    onetotwo(i)=~isempty(strfind(HeadChars(i,:),'1-2'));
    threetofour(i)=~isempty(strfind(HeadChars(i,:),'3-4'));
    fivetosix(i)=~isempty(strfind(HeadChars(i,:),'5-6'));
    eighttonine(i)=~isempty(strfind(HeadChars(i,:),'8-9'));
    tentoeleven(i)=~isempty(strfind(HeadChars(i,:),'10-11'));
    fifteentosixteen(i)=~isempty(strfind(HeadChars(i,:),'15-16'));
    nineteentotwenty(i)=~isempty(strfind(HeadChars(i,:),'19-20'));
    twentyninetothirty(i)=~isempty(strfind(HeadChars(i,:),'29-30'));
    thirtytothirtyone(i)=~isempty(strfind(HeadChars(i,:),'30-31'));
    thirtyninetoforty(i)=~isempty(strfind(HeadChars(i,:),'39-40'));
    EMG(i)=~isempty(strfind(HeadChars(i,:),'EMG'));
    PeakToPeak(i)=~isempty(strfind(HeadChars(i,:),'Peak to Peak'));
  end
  
% handle the case where EEG1 and EEG2 are used instead of EEG 1 and EEG 2
if isempty(find(EEG1))
	for i=1:length(HeadChars)
		 EEG1(i)=~isempty(strfind(HeadChars(i,:),'EEG1'));
	end
end

if isempty(find(EEG2))
	for i=1:length(HeadChars)
		 EEG2(i)=~isempty(strfind(HeadChars(i,:),'EEG2'));
	end
end
  
% Handle the case where only 1 channel exists. (no EEG1 or EEG2, just EEG)
if isempty(find(EEG1)) & isempty(find(EEG2))
disp('Warning: This file only has one channel. So EEG1 and EEG2 will contain the same data')
for i=1:length(HeadChars)
      EEG1(i)=~isempty(strfind(HeadChars(i,:),'EEG'));
      EEG2(i)=~isempty(strfind(HeadChars(i,:),'EEG'));
  end
end

  fclose('all');   %close all the files


  EEG1_1to2Hzcolumn = intersect(find(EEG1),find(onetotwo))-2; % subtract 2 to account for the fact that the first two columns are timestamp and lactate
  EEG1_3to4Hzcolumn = intersect(find(EEG1),find(threetofour))-2;
  EEG1_5to6Hzcolumn = intersect(find(EEG1),find(fivetosix))-2;
  EEG1_8to9Hzcolumn = intersect(find(EEG1),find(eighttonine))-2;
  EEG1_10to11Hzcolumn = intersect(find(EEG1),find(tentoeleven))-2;
  EEG1_15to16Hzcolumn = intersect(find(EEG1),find(fifteentosixteen))-2;
  EEG1_19to20Hzcolumn = intersect(find(EEG1),find(nineteentotwenty))-2;
  EEG1_29to30Hzcolumn = intersect(find(EEG1),find(twentyninetothirty))-2;
  EEG1_30to31Hzcolumn = intersect(find(EEG1),find(thirtytothirtyone))-2;
  EEG1_39to40Hzcolumn = intersect(find(EEG1),find(thirtyninetoforty))-2;


  EEG2_1to2Hzcolumn = intersect(find(EEG2),find(onetotwo))-2;
  EEG2_3to4Hzcolumn = intersect(find(EEG2),find(threetofour))-2;
  EEG2_5to6Hzcolumn = intersect(find(EEG2),find(fivetosix))-2;
  EEG2_8to9Hzcolumn = intersect(find(EEG2),find(eighttonine))-2;
  EEG2_10to11Hzcolumn = intersect(find(EEG2),find(tentoeleven))-2;
  EEG2_15to16Hzcolumn = intersect(find(EEG2),find(fifteentosixteen))-2;
  EEG2_19to20Hzcolumn = intersect(find(EEG2),find(nineteentotwenty))-2;
  EEG2_29to30Hzcolumn = intersect(find(EEG2),find(twentyninetothirty))-2;
  EEG2_30to31Hzcolumn = intersect(find(EEG2),find(thirtytothirtyone))-2;
  EEG2_39to40Hzcolumn = intersect(find(EEG2),find(thirtyninetoforty))-2;

% error checking
names={'EEG1_1to2Hzcolumn' 'EEG1_3to4Hzcolumn' 'EEG1_5to6Hzcolumn' 'EEG1_8to9Hzcolumn' 'EEG1_10to11Hzcolumn' 'EEG1_15to16Hzcolumn' 'EEG1_19to20Hzcolumn' ...
'EEG1_29to30Hzcolumn' 'EEG1_30to31Hzcolumn' 'EEG1_39to40Hzcolumn' 'EEG2_1to2Hzcolumn' 'EEG2_3to4Hzcolumn' 'EEG2_5to6Hzcolumn' 'EEG2_8to9Hzcolumn' ...
'EEG2_10to11Hzcolumn' 'EEG2_15to16Hzcolumn' 'EEG2_19to20Hzcolumn' 'EEG2_29to30Hzcolumn' 'EEG2_30to31Hzcolumn' ...
 'EEG2_39to40Hzcolumn' };
values={EEG1_1to2Hzcolumn EEG1_3to4Hzcolumn EEG1_5to6Hzcolumn EEG1_8to9Hzcolumn EEG1_10to11Hzcolumn EEG1_15to16Hzcolumn EEG1_19to20Hzcolumn ...
EEG1_29to30Hzcolumn EEG1_30to31Hzcolumn EEG1_39to40Hzcolumn EEG2_1to2Hzcolumn EEG2_3to4Hzcolumn EEG2_5to6Hzcolumn EEG2_8to9Hzcolumn ... 
EEG2_10to11Hzcolumn EEG2_15to16Hzcolumn EEG2_19to20Hzcolumn EEG2_29to30Hzcolumn EEG2_30to31Hzcolumn ...
 EEG2_39to40Hzcolumn};

for i=1:length(names)
	if isempty(values{i})
		error(['No value found for ' names{i}])
	end
end


% set up output vectors
if strcmp(keyword,'EEG1')
delta_columns = [EEG1_1to2Hzcolumn:EEG1_3to4Hzcolumn]; % 1-4 Hz
theta_columns = [EEG1_5to6Hzcolumn:EEG1_8to9Hzcolumn]; % 5-9 Hz
low_beta_columns = [EEG1_10to11Hzcolumn:EEG1_19to20Hzcolumn]; % 10-20 Hz
high_beta_columns = [EEG1_30to31Hzcolumn:EEG1_39to40Hzcolumn]; % 30-40 Hz
beta_columns = [EEG1_15to16Hzcolumn:EEG1_29to30Hzcolumn]; %15-30 Hz
end

if strcmp(keyword,'EEG2')
delta_columns = [EEG2_1to2Hzcolumn:EEG2_3to4Hzcolumn]; % 1-4 Hz
theta_columns = [EEG2_5to6Hzcolumn:EEG2_8to9Hzcolumn]; % 5-9 Hz
low_beta_columns = [EEG2_10to11Hzcolumn:EEG2_19to20Hzcolumn]; % 10-20 Hz
high_beta_columns = [EEG2_30to31Hzcolumn:EEG2_39to40Hzcolumn]; % 30-40 Hz
beta_columns = [EEG2_15to16Hzcolumn:EEG2_29to30Hzcolumn]; %15-30 Hz
end

if length(find(EMG)) > 1
  EMG_column = intersect(find(EMG),find(PeakToPeak))-2;
else
  EMG_column = find(EMG)-2;
end


