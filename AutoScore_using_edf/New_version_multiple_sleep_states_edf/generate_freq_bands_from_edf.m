function [epoch,state_cell,textdata] = generate_freq_bands_from_edf(inputFile,channel) 
%
% usage:  epoch = generate_freq_bands_from_edf(inputFile)
% this function reads an .edf file and generates the power in various frequency bands of the EEG 
% and outputs EMG peak-to-peak  
%
% INPUT:
% inputFile:		an .edf file with a corresponding .txt file in the same directory
% signal:			EEG1, EEG2
%
% OUTPUT:
% epoch  a struct with the following fields:
%				delta
%				theta
%				low beta
%				high beta
%				beta
%				EMG
%
% -----------------------------------------------------------------------------------------------------

%inputFile = '\\FS1\WisorData\Rempe\Data\test_data\E2697Base.edf'

[fileHeader,channelHeader,data,state_cell,fs,textdata,epoch_length]=LoadAndMergeEdfAndTxt_MJR(inputFile);


% Now generate power in frequency bands 0.5-1, 1-2, 2-3, etc. just for testing
% change this to just 1-4, etc.  Only what I need for the autoscoring

%NOTE:  the txt files I'm working with generally don't have any filtering at all (no 60 Hz filter, no band pass)

channel = 'EEG1';   % read this in from the user, (with some robustness:  EEG1 vs. EEG 1)
channel = 'EEGfrontalx';   %for Frank lab kitten data
channel = 'CH4';
Overlap = 0.5;      % percentage overlap to use for the Hamming window

% eeg
try
	EEG_channel_index = find(~cellfun('isempty',strfind({channelHeader.signal_labels},'EEG')))
	EMG_channel_index = find(~cellfun('isempty',strfind({channelHeader.signal_labels},'EMG')))
	EEG_channel_index = EEG_channel_index(1);  % in case there are more than 1
	EMG_channel_index = EMG_channel_index(1);

catch
	[truefalse,EEG_channel_index]=ismember('EEG',{channelHeader(:).signal_labels});

	if truefalse == 0
		[truefalse,EEG_channel_index]=ismember('EEG1',{channelHeader(:).signal_labels});
	end
	if truefalse == 0
		[truefalse,EEG_channel_index]=ismember('EEGfrontalx',{channelHeader(:).signal_labels});
	end 
	if truefalse == 0
		[truefalse,EEG_channel_index]=ismember('CH1',{channelHeader(:).signal_labels});
	end 
	if truefalse == 0
		[truefalse,EEG_channel_index]=ismember('CH4',{channelHeader(:).signal_labels});
	end 
	if truefalse == 0
		[truefalse,EEG_channel_index]=ismember('EEG3',{channelHeader(:).signal_labels});
	end 
	if truefalse == 0
		[truefalse,EEG_channel_index]=ismember('12CH',{channelHeader(:).signal_labels});
	end
	% emg
	[truefalseEMG,EMG_channel_index]=ismember('EMG',{channelHeader(:).signal_labels});  %UNCOMMENT THIS LINE
	if truefalseEMG == 0
		[truefalseEMG,EMG_channel_index]=ismember('CH7',{channelHeader(:).signal_labels});
	end 
	if truefalseEMG == 0
		[truefalseEMG,EMG_channel_index]=ismember('CH2',{channelHeader(:).signal_labels});
	end 
	if truefalseEMG == 0
		[truefalseEMG,EMG_channel_index]=ismember('15CH',{channelHeader(:).signal_labels});
	end 
end % end of try catch statement

N = fix(fs(EEG_channel_index)*epoch_length)  % number of data points in epoch
NOVERLAP = Overlap*N;						  % Number of points in overlap

raw_EEG = data{EEG_channel_index}(:);			%
raw_EMG = data{EMG_channel_index}(:);

sampling_rate = fs(EEG_channel_index);

epoch=struct;  

numel(raw_EEG)/N 

disp('starting to loop through epochs')
for j=0:(numel(raw_EEG)/N)-1
	%[spectra,freqs] = pwelch(raw_EEG(j*N+1:j*N+N),[],NOVERLAP,sampling_rate);
	[spectra,freqs] = pwelch(raw_EEG(j*N+1:j*N+N),hamming(floor(N/2)),[],[],sampling_rate);
	
	 %[pxx,freqs] = periodogram(raw_EEG(j*N+1:j*N+N),[],[],sampling_rate);
	 
	deltaIdx    = find(freqs>=1 & freqs<=4);		%find the indices first
	thetaIdx    = find(freqs>=5 & freqs<=9);
	lowBetaIdx  = find(freqs>=10 & freqs<=20);
	highBetaIdx = find(freqs>=30 & freqs<=40);
	betaIdx     = find(freqs>=15 & freqs<=30);

	% pow = (abs(fft(detrend(raw_EEG(j*sampling_rate*10+1:(j+1)*sampling_rate*10)))).^2)/((sampling_rate*10)^2)/(1/10);
 %    pow = pow(2:floor(sampling_rate*10/2)+1)*2; 

	epoch(j+1).delta    = sum(spectra(deltaIdx));  % units?  
	epoch(j+1).theta    = sum(spectra(thetaIdx));
	epoch(j+1).lowBeta  = sum(spectra(lowBetaIdx));
	epoch(j+1).highBeta = sum(spectra(highBetaIdx));
	epoch(j+1).beta     = sum(spectra(betaIdx));
	epoch(j+1).EMG 		= max(raw_EMG(j*N+1:j*N+N)) - min(raw_EMG(j*N+1:j*N+N)); % peak-to-peak is max-min?

end 


% Make the epoch vector have the same number of elements as the number of time stamps in the txt file
% This is a bit of a hack, but I think it has to do with the way NeuroScore or SleepSign generates the 
% text file.  i.e. is the time stamp at the beginning of the epoch, the middle or the end? 
last_epoch = epoch(end);
epoch = [epoch last_epoch];













