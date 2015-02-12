function [global_agreement,wake_percent_agreement,SWS_percent_agreement,REM_percent_agreement]=compute_agreement(human_scored_state_vector,computer_scored_state_vector)

% usage: [global_agreement,wake_percent_agreement,SWS_percent_agreement,REM_percent_agreement]=compute_agreement(human_scored_state_vector,computer_scored_state_vector)
%
% both inputs are vectors containing 0,1,2 in each element.  Each element repesents an epoch of data and 0=wake, 1=SWS, 2=REM

vh = human_scored_state_vector;
vc = computer_scored_state_vector;     % easier names

	% to begin, compute "global agreement" like Rytkonen2011 does:
	global_agreement=1-(length(find(vh-vc))/length(vh));

	% Wake percent agreement 
	wake_percent_agreement = (length(find(vh==0 & vc==0)))/length(find(vh==0));

	% SWS percent agreement
	SWS_percent_agreement = (length(find(vh==1 & vc==1)))/length(find(vh==1));

	% REM percent agreement
	REM_percent_agreement = (length(find(vh==2 & vc==2)))/length(find(vh==2));
