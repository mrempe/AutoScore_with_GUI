function [global_agreement,wake_percent_agreement,SWS_percent_agreement,REM_percent_agreement]=compute_agreement(human_scored_state_vector,computer_scored_state_vector,num_value_wake,num_value_SWS,num_value_REM)

% usage: [global_agreement,wake_percent_agreement,SWS_percent_agreement,REM_percent_agreement]=compute_agreement(human_scored_state_vector,computer_scored_state_vector,unique_sleep_states)
%
% both inputs are vectors containing 0,1,2 in each element.  Each element repesents an epoch of data and 0=wake, 1=SWS, 2=REM
% the vectors contain integers from 1 up to the number of different states that were present in the vector.



% handle the case where the two vectors contain letters fo 
if iscell(human_scored_state_vector) & iscell(computer_scored_state_vector)
	
	% check to see if there are any empty cells in the human-scored data and re-score them as W
	emptycells = cellfun(@isempty,human_scored_state_vector);
	 if sum(emptycells) > 0
		empty_locs = find(emptycells); 
	 	for i=1:length(empty_locs)
	 	human_scored_state_vector{empty_locs(i)} = 'W';
	 	end
	 end


	vh = cell2mat(human_scored_state_vector);
	vc = cell2mat(computer_scored_state_vector);
	
	global_agreement = sum(vh==vc)/length(vh);
	wake_percent_agreement = (length(find(vh=='W' & vc=='W')))/length(find(vh=='W'));
	SWS_percent_agreement = (length(find(vh=='S' & vc=='S')))/length(find(vh=='S'));
	REM_percent_agreement = (length(find((vh=='R' | vh=='P') & (vc=='R' | vc=='P'))))/length(find(vh=='R' | vh=='P'));

else
  % this is the case where the two input vectors consist entirely of numbers (this was what was here originally)

	vh = human_scored_state_vector;
	vc = computer_scored_state_vector;     % easier names


		% to begin, compute "global agreement" like Rytkonen2011 does:
		global_agreement=1-(length(find(vh-vc))/length(vh));

		% Wake percent agreement 
		wake_percent_agreement = (length(find(vh==num_value_wake & vc==num_value_wake)))/length(find(vh==num_value_wake));

		% SWS percent agreement
		SWS_percent_agreement = (length(find(vh==num_value_SWS & vc==num_value_SWS)))/length(find(vh==num_value_SWS));

		% REM percent agreement
		REM_percent_agreement = (length(find(vh==num_value_REM & vc==num_value_REM)))/length(find(vh==num_value_REM));

end

