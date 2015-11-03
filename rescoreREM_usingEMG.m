function NewSleepState = rescoreREM_usingEMG(Feature,SleepState) 
	%
	% usage: NewSleepState =rescoreREM_usingEMG(Feature,SleepState) 
	%
	%
	% This function handles the case where a REMS episode isn't scored as such long enough.
	% It looks at each run of REMS that is followed by Wake and continues REMS until there is 
	% a significant change in the EMG (denoting wake).


	% Part 2: 
	% If any epoch is scored as R or S, but the EMG is large there, rescore that epoch as W




	EMG = Feature(:,5);
	REM_epochs = find(SleepState==2);

	average_EMG_during_REM = mean(EMG(REM_epochs));
	std_EMG_during_REM     = std(EMG(REM_epochs));

	
	%index = 1;
	% for i=[REM_epochs']   % loop over the REM epochs.  This is terrible MATLAB notation
	% 	%disp(['i= ',num2str(i)])

	% 	if SleepState(i+1)==0 | SleepState(i+1)==1
	% 		REM_epochs_followed_byW_or_SWS(index)=i;
	% 		index=index+1;
	% 	end 
	% end 

	% for i=[REM_epochs_followed_byW_or_SWS']   % loop over epochs that are at the end of a REM streak
	% 	j=i;
	% 	while EMG(j+1) < average_EMG_during_REM + 3*std_EMG_during_REM
	% 		SleepState(j+1)=2;  % set the next epoch to REMS, until the EMG changes substantially
	% 		disp('rescoreREM_usingEMG rescored an epoch to REM')
	% 		j=j+1;
	% 	end
	% end 


	% New approach using contiguous.m
	runs = contiguous(SleepState,2);    % find all runs of REMS
	runs = runs{1,2};

	for i=1:size(runs,1)
		EMG_avg_for_REM_run = mean(EMG(runs(i,1):runs(i,2)));
		std_for_REM_run = std(EMG(runs(i,1):runs(i,2)));
		if runs(i,1) ~= runs(i,2) & runs(i,2) < size(SleepState,1)  % if REMS episode is more than one epoch (and it's not at end of recording)
			if SleepState(runs(i,2)+1)==0  % if the REM streak ends with Wake
				j=1;  %was j=i;
				while (runs(i,2)+j < length(EMG) & SleepState(runs(i,2)+j) ~= 1 & (EMG(runs(i,2)+j) ) < EMG_avg_for_REM_run + 1*std_for_REM_run)
					disp('rescoreREM_usingEMG rescored an epoch to REM')
					SleepState(runs(i,2)+j) = 2;
					j=j+1;
				end
			end
		end
	
		% Now do the case where the REMS episode is only one epoch long.  
		if runs(i,1) == runs(i,2) & runs(i,2) < size(SleepState,1)   %runs of only 1 epoch, not last epoch
			if SleepState(runs(i,2)+1)==0   %if the next epoch is Wake 
				j=1;
				while runs(i,2)+j < length(EMG) & SleepState(runs(i,2)+j) ~= 1 & EMG(runs(i,2)+j) < 1.5*EMG(runs(i,2))  % while not at end of recording, 
																														% next epoch isn't SWS, and EMG
																														% hasn't risen much since its value
																														% in the one REMS epoch (this handles 
																														% the case where one REMS epoch is 
																														% followed immediately by a legitimate 
																														% Wake epoch)  
					
					SleepState(runs(i,2)+j) = 2;
					j=j+1;
				end
			end
		end





	end

NewSleepState = SleepState;



% NEW REM rescoring rule:
% Find all epochs marked as R or S. If the EMG is high in these epochs, re-score them as W
% meanEMG = mean(EMG)
% medianEMG = median(EMG)
% std(EMG)
% EMG(5883:5886)  %5884 should be .7786

% RorSepochs = find(SleepState==1 | SleepState==2);
% for i=1:length(RorSepochs)
% 	if EMG(RorSepochs(i)) > meanEMG
% 		SleepState(RorSepochs(i))=0;  % Set this epoch to W
% 		disp('new EMG rule: If EMG is high, rescore as W')
% 	end
% end

