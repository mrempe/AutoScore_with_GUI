function make_side_by_side_tau_fig(Tiauto,Tihuman,Tdauto,Tdhuman)
	% usage: make_side_by_side_tau_fig(Tiauto,Tihuman,Tdauto,Tdhuman)
	%
	%
	% This function makes plots of Ti autoscored vs Ti human-scored and 
	% plots of Td autoscored vs Td human-scored. 
	%
	%
	% INPUTS: 
	% Tiauto:  a matrix of Tau i values for autoscored data. each row is a different strain, each colum a recording
	%
	% Tihuman: 




	figure
	subplot(1,2,1)
	plot(Tiauto(1,:),Tihuman(1,:),'x',Tiauto(2,:),Tihuman(2,:),'ro')
	hold on 
	plot(0:.01:6,0:.01:6,'.')
	hold off
	xlabel('Ti Autoscored')
	ylabel('Ti Human-Scored')
	title('Ti')
	subplot(1,2,2)
	plot(Tdauto(1,:),Tdhuman(1,:),'x',Tdauto(2,:),Tdhuman(2,:),'ro')
	hold on 
	plot(0:.01:6,0:.01:6,'.')
	hold off
	xlabel('Td Autoscored')
	ylabel('Td Human-Scored')
	title('Td ')