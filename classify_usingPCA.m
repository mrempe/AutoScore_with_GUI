function [predicted_score,dynamic_range,kappa,global_agreement,wake_agreement,SWS_agreement,REM_agreement]=classify_usingPCA(filename,method,signal,restrict,training_start,training_end,trials,writefile,output_directory)
	% Usage: [predicted_score,kappa,global_agreement,wake_agreement,SWS_agreement,REM_agreement]=classify_usingPCA(filename,method,signal,restrict,training_start,training_end,trials,writefile)
	%
	%
	% This function uses a Principal Component Analysis approach to classify the sleep state of each epoch of the file filename. 
	% The approach is based on Gilmour et al 2010, but instead of having the user visually draw lines separating states, this function 
	% calls classify.m to draw curves around the respective regions. 
	% 
	% NOTE: this function requires data that contains frequencies up to 40 Hz since one of the features is the power in 
	% the "high beta" band (30-40 Hz)
	%
	% NOTE: if only a subset of the original file has been scored by a human, agreement stats (including kappa) are not computed. They are set to NaN.  
	%
	% Inputs:
	%        filename:      name of the .txt file. This can either be partially-scored or fully scored. 
	%
	%		 method:        either 'NaiveBayes' or 'RandomForest'.  Which classification method to use (after doing PCA)
	%        signal:        'EEG1' or 'EEG2'.  Which signal to use.
	%
	%
	%        restrict:                1 if you want to restrict the dataset to only 8640 epochs starting at 10:00 AM, 0 if you don't. I needed this 
	%                                 to compare 8640 epochs of 2sec epoch data to 8640 epochs of 10sec epoch data in comparePCAscoreepochlength.m
	%
	%        training_start:   The beginning of the training period, measured in hours from the beginning of the file.
	%
	%		 training_end:     The end of the training period, measured in hours from the beginning of the file.   
	%
	%		 trials:       a struct containing two fields: number and fraction_training_data.  Run "number" different trials, each time choosing a random "fraction
	%						_training_data" of the training data as training.  The idea is that by choosing different random subsets of the training data, 
	%						we may be able to improve performance.  0<fraction_training_data<1  0.05 is usually a good choice.  
	%
	%        writefile:     1 if you want to generate a new .txt file, 0 if you don't
	%
	%		 




rescore_REM_in_wake =1;  % FLAG.  If =1, then each epoch scored as REM preceeded by 30 seconds of wake will be rescored as wake. 
                         % Set this to 0 if you have data from narcolepsy, sleep apnea or some other condition where REM 
                         % episodes can happen in the middle of a wake bout.


if nargin==3
	training_start=[];training_end=[]; writefile=0; 
end
if nargin==4
	training_end=[]; writefile=0; 
end
if nargin==5
	writefile=0; 
end


	addpath 'C:\Users\wisorlab\Documents\MATLAB\Brennecke\matlab-pipeline\Matlab\etc\matlab-utils\';  %where importdatafile.m XL.m and create_TimeStampMatrix_from_textdata.m live
	

% -- First import the .txt file
% data has columns: lactate, EEG1_0.5-1Hz, EEG1_1-2Hz etc.
[data,textdata]=importdatafile(filename);
TimeStampMatrix = create_TimeStampMatrix_from_textdata(textdata);
	
% Compute the length of an epoch
f=find(textdata{1,1}==':');   % Find all locations of the colon in the first time stamp
first_colon_loc = f(1);   
last_colon_loc = f(2);
hour_first_time_stamp    = str2num(textdata{1,1}(first_colon_loc-2))*10+str2num(textdata{1,1}(first_colon_loc-1));  
hour_second_time_stamp   = str2num(textdata{2,1}(first_colon_loc-2))*10+str2num(textdata{2,1}(first_colon_loc-1));  
minute_first_time_stamp  = str2num(textdata{1,1}(first_colon_loc+1))*10+str2num(textdata{1,1}(first_colon_loc+2));
minute_second_time_stamp = str2num(textdata{2,1}(first_colon_loc+1))*10+str2num(textdata{2,1}(first_colon_loc+2));
second_first_time_stamp  = str2num(textdata{1,1}(last_colon_loc+1))*10+str2num(textdata{1,1}(last_colon_loc+2));
second_second_time_stamp = str2num(textdata{2,1}(last_colon_loc+1))*10+str2num(textdata{2,1}(last_colon_loc+2));
epoch_length_in_seconds=etime([2014 2 28 hour_second_time_stamp minute_second_time_stamp second_second_time_stamp],[2014 2 28 hour_first_time_stamp minute_first_time_stamp second_first_time_stamp]);



% if restrict=1, throw away all the data except for 8640 epochs starting at 10:00 AM if restrict is set to 1
if restrict
	tenAMlocs = find([TimeStampMatrix(:).Hour]==10 & [TimeStampMatrix(:).Minute]==0 & [TimeStampMatrix(:).Second]==0); %10:00, 10:00AM
	data = data(tenAMlocs(1):tenAMlocs(1)+8640,:);
	textdata = textdata(tenAMlocs(1):tenAMlocs(1)+8640,:);
end




    % Set up the sleep state as a variable
	SleepState=zeros(size(data,1),1);
	unscored_epochs=0;

	for i = 1:size(data,1)  
     if isempty(textdata{i,2})==1        % label unscored epochs with an 8
     	unscored_epochs=unscored_epochs+1;
     	SleepState(i)=8;                 
     elseif textdata{i,2}=='W'           % 0=Wake,1=SWS,2=REM, 5=artefact,
     	SleepState(i)=0;
     elseif textdata{i,2}=='S'
     	SleepState(i)=1;
     elseif textdata{i,2}=='P'
     	SleepState(i)=2;
     elseif textdata{i,2}=='R'
     	SleepState(i)=2;
     elseif sum(textdata{i,2}=='Tr')==2
        SleepState(i)=0;                  % call transitions wake
     elseif textdata{i,2}=='X'            % artefact
     	SleepState(i)=5; 
     else   
     	error('I found a sleep state that wasn''t W,S,P,R,Tr, or X');
     end
    end
	disp(['There were ',num2str(unscored_epochs), ' epochs, (' num2str(unscored_epochs/(length(SleepState))*100) '% of the total dataset), that were not scored.'])


% if already_scored_by_human
% 	SleepState(find(SleepState==8))=0; %set unscored epochs to wake if the file has already been scored by a human
% end
	  





	% Set up the feature matrix, a la Gilmour etal 2010.
	% rows are data points, columns are delta	theta	low beta	high beta	EMG		Theta/delta		Beta/delta 
	% where delta = 1-4 Hz
	% 		theta = 5-9 Hz
	%		low beta = 10-20 Hz
	%		high beta = 30-40 Hz
	%		Theta/delta is the ratio of theta to delta
	%		Beta/delta is the ratio of beta to delta (here beta is defined as 15-30Hz)


[delta_columns,theta_columns,low_beta_columns,high_beta_columns,beta_columns,EMG_column]=find_freq_band_columns(filename,signal);


	   Feature(:,1) = sum(data(:,delta_columns),2);	%delta
	   Feature(:,2) = sum(data(:,theta_columns),2);	%theta
	   Feature(:,3) = sum(data(:,low_beta_columns),2);	%low beta
	   Feature(:,4) = sum(data(:,high_beta_columns),2);	%high beta
	   Feature(:,5) = data(:,EMG_column);				%EMG
	   Feature(:,6) = Feature(:,2)./Feature(:,1);
	   Feature(:,7) = sum(data(:,beta_columns),2)./Feature(:,1);
	
if sum(sum(isnan(Feature))) ~=0
	disp('WARNING: Feature vector contains NaNs.  Missing EEG or EMG data.  Ignoring these epochs.')
	pause(3)  %pause for a few seconds, so the user sees this message
end

 % Feature will contain NaNs if there is missing EEG or EMG data.  
 % Find and exclude these epochs. They may occur in the training data or not.
 % Find each row that contains missing EEG or EMG data and mark it as artefact. Then ignore all artefact rows in autoscoring. 
[rows,cols]=find(isnan(Feature));
Nan_rows = unique(rows);
%non_artefact_non_missing_epochs = setdiff(1:size(Feature,1),Nan_rows);  %non_artefact_non_missing_epochs has numel= length(Feature)-Nan_rows    
SleepState(Nan_rows)=5;  % Designate epochs with missing data as artefact 

% Also handle the case where all the EEG values are artificially set to 1.  This is clearly an artefact even if it wasn't scored as such
for i=1:length(data)
	if data(i,1) ==1 & data(i,2)==1 & data(i,3)==1 & data(i,4)==1 & data(i,5)==1
		SleepState(i)=5;
	end
end



% Are there epochs marked as artefacts (either scored as artefact or missing EEG or EMG data)?   
  if length(find(SleepState(:)==5)) > 0
    disp(['I found ', num2str(length(find(SleepState(:)==5))) ' epochs marked as artefact'])
    %SleepState = handle_artefacts(SleepState);     % After this step there are no more epochs scored as 5
  end 
  non_artefact_indices = find(SleepState(:)~=5);  % indices of epochs that are not marked as artefact. Run autoscoring only on these indices. 



% compute dynamic range
dynamic_range = max(Feature(non_artefact_indices,7))-min(Feature(non_artefact_indices,7));


% Smoothing
for i=1:7
	Feature(non_artefact_indices,i)=medianfiltervectorized(Feature(non_artefact_indices,i),2);
end

% Compute the Principal Components
scalefactor = max(max(Feature(non_artefact_indices)))-min(min(Feature(non_artefact_indices)));
[Coeff,PCAvectors,latent,tsquared,explained] = pca((2*(Feature)-max(max(Feature)))./scalefactor+1);
explained
% PCAvectors is indexed just on the non_artefact_non_missing epochs.  Size should be length(Feature)-Nan_rows


% Determine if the file has been fully scored or not.
% If it has been fully scored keep only a portion of the scored .txt file
% and re-score the whole thing using PCA.
% set up a boolean, fully_scored=1 if the entire recording has been scored by a human, 0 if only a subset has been scored.  

fully_scored = ~isempty(training_start) && ~isempty(training_end);
if fully_scored == 0   %using all scored epochs as training data
	original_scored_rows = find(SleepState ~=8 & SleepState ~=5 );               % file has not been fully scored. Exclude artefact epochs. 
																				 % original scored rows are those that have been scored by a human.
																				 % I use 5% of these rows as training data and call them scored_rows
	
else  % it has been fully scored
	ind_start = round(training_start*60*60/epoch_length_in_seconds);
	if(ind_start==0) ind_start=1; end
	ind_end   = round(training_end*60*60/epoch_length_in_seconds);
	original_scored_rows = ind_start:ind_end;
	original_scored_rows = original_scored_rows(find(SleepState(original_scored_rows)~=5));  % Only use the training data that doesn't have artefacts. 
	
	if sum(SleepState(original_scored_rows)==8)>0
		error('Some of the Epochs you told me to use as training don''t have any scoring in them.  Please run PCASCOREBATCHMODE again and either choose another range or use all scored epochs as training')
	end
end

unique_states = unique(SleepState(original_scored_rows));
if length(unique_states) < 3
	warning('WARNING: Fewer than three states are present in the training data.')
end

% MULTIPLE TRIALS
% Run it once using all of the scored epochs as training data, 
% then run it trials.number times using a random percentage 
% of the scored epochs as training data each time. 
if trials.number > 1
	scored_rows{1} = original_scored_rows;
	for i=2:trials.number+1
		scored_rows{i} = datasample(original_scored_rows,round(trials.fraction_training_data*length(original_scored_rows)),'Replace',false); % replace set to false means I won't get a row repeated
		tstart = tic;
		num_REMS_episodes_desired = 10;
		while length(find(SleepState(scored_rows{i})==2))<num_REMS_episodes_desired
 			scored_rows{i} = datasample(original_scored_rows,round(trials.fraction_training_data*length(original_scored_rows)),'Replace',false); 
	 		time_spent_sampling =toc(tstart);
	 		if time_spent_sampling > 2   % if it requires more than 4 seconds, relax the requirement for REMS episodes
				num_REMS_episodes_desired = num_REMS_episodes_desired -1;
			tstart = tic;
			end
	 	end
	end	
elseif trials.number == 1
	scored_rows{1} = original_scored_rows;
else
	error('The number of trials must be greater than or equal to one')
end


% if already_scored_by_human
% 	% --- use the data from 10AM to 2PM as training data
% 	% Find the first instance of 10AM in the data
% 	tenAMlocs = find([TimeStampMatrix(:).Hour]==10 & [TimeStampMatrix(:).Minute]==0 & [TimeStampMatrix(:).Second]==0); %10:00, 10:00AM
% 	ind_start = tenAMlocs(1);

% 	% Find first instance of 2PM that comes after the first instance of 10AM
% 	twoPMlocs = find([TimeStampMatrix(:).Hour]==14 & [TimeStampMatrix(:).Minute]==0 & [TimeStampMatrix(:).Second]==0); %14:00, 2:00PM
% 	a=find(twoPMlocs>ind_start);    % only keep those that occur after ind_start
% 	ind_end = twoPMlocs(a(1));
% 	scored_rows = ind_start:ind_end;

% 	% choose a random 5 percent as training data
% 	%percent_scored = 5;             % this is case where file has been scored.  we're just re-scoring it using a random 5% for training.
% 	%scored_rows = datasample(1:length(PCAvectors),round((percent_scored/100)*length(PCAvectors)),'Replace',false);
% else
% 	scored_rows = find(SleepState<=2);    % 0-2=wake/SWS/REM, 8=not scored
% 	length(scored_rows)
% 	scored_rows = datasample(scored_rows,round(percent_training*length(scored_rows)),'Replace',false); 
% 	% while length(find(SleepState(scored_rows)==2))==0
% 	% 	scored_rows = datasample(scored_rows,round(percent_training*length(scored_rows)),'Replace',false); 
% 	% end
% end

% 
% % If it has only been partially scored (less than 90%) the rows marked with 8 are unscored.
% percent_of_rows_not_scored = length(find(SleepState==8))/length(SleepState);

% if percent_of_rows_not_scored>.10   % has not been fully scored 
% 	scored_rows=(SleepState<=2);    % 0-2=wake/SWS/REM, 8=not scored
% else 
% 	disp('in the rescoring case')
% 	percent_scored = 5;             % this is case where file has been scored.  we're just re-scoring it using a random 5% for training.
% 	scored_rows = datasample(1:length(PCAvectors),round((percent_scored/100)*length(PCAvectors)),'Replace',false);
% end

% Do quadratic discriminant analysis to classify each epoch into wake, SWS, or REM using the PCA vectors
	if trials.number >1 
		M = trials.number +1;
	else
		M = trials.number;
	end

for j=1:M
	predicted_sleep_state(:,j) = 11*ones(size(SleepState));
	predicted_sleep_state(find(SleepState==5),j)=5;

 if strcmp(method,'NaiveBayes')
	 [predicted_sleep_state(non_artefact_indices,j),err,posterior,logp,coeff] = classify(PCAvectors(non_artefact_indices,1:3),PCAvectors(scored_rows{j},1:3),SleepState(scored_rows{j}),'diaglinear','empirical');  % Naive Bayes
	 err 
 end  
	%predicted_sleep_state(Nan_rows)=5;  %set all epochs with artefact (or missing data) to 5, not just those in training data


 if strcmp(method,'RandomForest')
	
	B=TreeBagger(50,PCAvectors(scored_rows{j},1:3),SleepState(scored_rows{j}),'OOBVarImp','On');  %build 50 bagged decision trees
	figure
	plot(oobError(B));
	xlabel('Number of Grown Trees')
	ylabel('Out-of-Bag Classification Error')
	
	bag_predicted_sleep_state = predict(B,PCAvectors(:,1:3));
	predicted_sleep_state = cell2mat(bag_predicted_sleep_state);
	predicted_sleep_state = str2num(predicted_sleep_state);
 end 


	% if there are REM epochs preceeded by 30 seconds or more of contiguous wake 
	% re-score the REM epoch as wake
	REM_window_length = 30; %seconds.  If there are REM_window_length seconds of contiguous wake preceeding an epoch scored as REMS, change that REM epoch to wake
	epochs_in_REM_window = round(REM_window_length/epoch_length_in_seconds); 
	REM_locs = [];
	REM_rescore_counter=0;
	if rescore_REM_in_wake
		for i=1:epochs_in_REM_window %If REM occurs in first 30 seconds of recording, rescore it as wake
			if predicted_sleep_state(i,j)==2
				predicted_sleep_state(i,j)=0;
				REM_rescore_counter = REM_rescore_counter+1;
			end
		end
		REM_locs = find(predicted_sleep_state(:,j)==2);
		%REM_locs = REM_locs(find(REM_locs>epochs_in_REM_window));  % in case you get an epoch in the first three that is REM
		
		
		for i=1:length(REM_locs)
			if predicted_sleep_state(REM_locs(i)-epochs_in_REM_window:REM_locs(i)-1,j)==zeros(epochs_in_REM_window,1)
	       	predicted_sleep_state(REM_locs(i),j) = 0;  %set that epoch to wake
	       	REM_rescore_counter = REM_rescore_counter+1;
	   		end
		end
	end



	% Compute agreement stats to choose the best trial
	if fully_scored
	kappa(j) = compute_kappa(SleepState(non_artefact_indices),predicted_sleep_state(non_artefact_indices,j));
	[global_agreement(j),wake_agreement(j),SWS_agreement(j),REM_agreement(j)] = compute_agreement(SleepState(non_artefact_indices),predicted_sleep_state(non_artefact_indices,j));
	else
		% compute agreement stats on only those epochs that were scored by hand
		kappa(j) = compute_kappa(SleepState(scored_rows{j}),predicted_sleep_state(scored_rows{j},j));
		[global_agreement(j),wake_agreement(j),SWS_agreement(j),REM_agreement(j)] = compute_agreement(SleepState(scored_rows{j}),predicted_sleep_state(scored_rows{j},j));
		
	end
end % end of looping through trials

% Now choose the best trial and use that to write the file and compute agreement stats that get returned by this function.
overall_score = 0.7*kappa +0.3*global_agreement;
[~,ranking] = sort(overall_score);
[best_overall_score,best_trial] = max(overall_score);
%disp(['Trial ' num2str(best_trial) ' is the best'])
ranking = flip(ranking);  % If you want to see a ranking of the trials based on agreement stats, remove semicolon from this line
kappa = kappa(best_trial);
global_agreement = global_agreement(best_trial);
wake_agreement = wake_agreement(best_trial);
SWS_agreement = SWS_agreement(best_trial);
REM_agreement = REM_agreement(best_trial);
predicted_sleep_state = predicted_sleep_state(:,best_trial);
if ~fully_scored
	disp('WARNING: The agreement parameters refer only to the subset of data that was scored by a human, not the entire dataset')
end
if rescore_REM_in_wake
	disp(['I rescored ', num2str(REM_rescore_counter), ' REM epochs as wake.  This is ', num2str(100*(REM_rescore_counter/length(REM_locs))),'% of the epochs originally scored as REM'])
end

if strcmp(method,'NaiveBayes')
	figure
	gscatter(PCAvectors(scored_rows{best_trial},1),PCAvectors(scored_rows{best_trial},2),SleepState(scored_rows{best_trial}),[1 0 0; 0 0 1; 1 .5 0],'osd');

	if length(unique_states) >= 3  % if at least three states are present, draw lines on the scatterplot to indicate the states 
		xl = xlim;
		yl = ylim;
		hold on 
		K = coeff(2,3).const;
		L = coeff(2,3).linear;
		%Q = coeff(1,2).quadratic;
			% Function to compute K + L*v + v'*Q*v for multiple vectors
		% v=[x;y]. Accepts x and y as scalars or column vectors.
		f = @(x1,x2) K + L(1)*x1+L(2)*x2; %+ sum(([x y]*Q) .* [x y], 2);
		h2 = ezplot(f,[xl(1) xl(2) yl(1) yl(2)]);
		set(h2,'Color','r','LineWidth',2)

		K = coeff(1,2).const;
		L = coeff(1,2).linear;
		f = @(x1,x2) K + L(1)*x1+L(2)*x2; %+ sum(([x y]*Q) .* [x y], 2);
		h2 = ezplot(f,[xl(1) xl(2) yl(1) yl(2)]);
		set(h2,'Color','k','LineWidth',2)

		K = coeff(1,3).const;
		L = coeff(1,3).linear;
		f = @(x1,x2) K + L(1)*x1+L(2)*x2; %+ sum(([x y]*Q) .* [x y], 2);
		h2 = ezplot(f,[xl(1) xl(2) yl(1) yl(2)]);
		set(h2,'Color','b','LineWidth',2)
	end  % end of check for at least 3 unique states
end   % end of NaiveBayes if statement
% Compare human-scored vs computer scored
figure
subplot(1,2,1)
% grouping
wake_locs_human = find(SleepState==0);
SWS_locs_human  = find(SleepState==1);
REM_locs_human  = find(SleepState==2);
wake_scatter_human = transparentScatter(PCAvectors(wake_locs_human,1),PCAvectors(wake_locs_human,2),0.01,0.05);
set(wake_scatter_human,'FaceColor',[1,0,0]);
SWS_scatter_human = transparentScatter(PCAvectors(SWS_locs_human,1),PCAvectors(SWS_locs_human,2),0.01,0.05);
set(SWS_scatter_human,'FaceColor',[0,0,1]);
REM_scatter_human = transparentScatter(PCAvectors(REM_locs_human,1),PCAvectors(REM_locs_human,2),0.01,0.05);
set(REM_scatter_human,'FaceColor',[1,0.5,0]);
%gscatter(PCAvectors(:,1),PCAvectors(:,2),SleepState,[1 0 0; 0 0 1; 1 .5 0],'osd');
%scatterhist(PCAvectors(:,1),PCAvectors(:,2),'Group',SleepState,'Color','rbk')
xlabel('PC1')
ylabel('PC2')
a = find(filename=='\');
title(['Human-scored data for file ', filename(a(end)+1:end)])
legend('Wake','SWS','REMS')
legend boxoff
yl1 = ylim;  % ylimits
xl1 = xlim;  % xlimits

subplot(1,2,2)
wake_locs_machine = find(predicted_sleep_state==0);
SWS_locs_machine  = find(predicted_sleep_state==1);
REM_locs_machine  = find(predicted_sleep_state==2);
wake_scatter_machine = transparentScatter(PCAvectors(wake_locs_machine,1),PCAvectors(wake_locs_machine,2),0.01,0.05);
set(wake_scatter_machine,'FaceColor',[1,0,0]);
SWS_scatter_machine = transparentScatter(PCAvectors(SWS_locs_machine,1),PCAvectors(SWS_locs_machine,2),0.01,0.05);
set(SWS_scatter_machine,'FaceColor',[0,0,1]);
REM_scatter_machine = transparentScatter(PCAvectors(REM_locs_machine,1),PCAvectors(REM_locs_machine,2),0.01,0.05);
set(REM_scatter_machine,'FaceColor',[1,0.5,0]);
% gscatter(PCAvectors(:,1),PCAvectors(:,2),predicted_sleep_state,[1 0 0; 0 0 1; 1 .5 0],'osd');
xlabel('PC1')
ylabel('PC2')
% a = find(filename=='\');
 title(['Computer-scored data for file ', filename(a(end)+1:end)])
 legend('Wake','SWS','REMS')
 legend boxoff
yl2 = ylim;  % ylimits
xl2 = xlim;  % xlimits
if  ~isequal(xl1,xl2) || ~isequal(yl1,yl2)  % Make the axes equal between the two subplots (they may differ since one is only training data and one is all data)
	axis([xl1(1) xl1(2) yl1(1) yl1(2)])
end



% figure(71)
% hold on 
% for i=1:length(PCAvectors(:,1))
% 	if SleepState(i)==0
% 		plot3(PCAvectors(i,1),PCAvectors(i,2),PCAvectors(i,3),'r.')
% 	end
% 	if SleepState(i)==1
% 		plot3(PCAvectors(i,1),PCAvectors(i,2),PCAvectors(i,3),'b.')
% 	end
% 	if SleepState(i)==2
% 		plot3(PCAvectors(i,1),PCAvectors(i,2),PCAvectors(i,3),'.','Color',[1 .5 0])
% 	end
% end
% hold off

% xlabel('PC1')
% ylabel('PC2')
% zlabel('PC3')
% view(20,82)
% a = find(filename=='\');
% title(['Human-scored data for file ', filename(a(end)+1:end)])
% legend('Wake','SWS','REMS')

% figure(72)
% hold on 
% for i=1:length(PCAvectors(:,1))
% 	if predicted_sleep_state(i)==0
% 		plot3(PCAvectors(i,1),PCAvectors(i,2),PCAvectors(i,3),'r.')
% 	end
% 	if predicted_sleep_state(i)==1
% 		plot3(PCAvectors(i,1),PCAvectors(i,2),PCAvectors(i,3),'b.')
% 	end
% 	if predicted_sleep_state(i)==2
% 		plot3(PCAvectors(i,1),PCAvectors(i,2),PCAvectors(i,3),'.','Color',[1 .5 0])
% 	end
% end
% hold off

% xlabel('PC1')
% ylabel('PC2')
% zlabel('PC3')
% view(20,82)
% a = find(filename=='\');
% title(['Computer-scored data for file ', filename(a(end)+1:end)])
% legend('Wake','SWS','REMS')


% compute agreement stats comparing not to entire file, but only the portion that has been scored by a human
% kappa = compute_kappa(SleepState(ind_start:ind_end),predicted_sleep_state(ind_start:ind_end));
% [global_agreement,wake_agreement,SWS_agreement,REM_agreement] = compute_agreement(SleepState(ind_start:ind_end),predicted_sleep_state(ind_start:ind_end));



% Compute statistics about agreement 
% if fully_scored
% kappa = compute_kappa(SleepState(non_artefact_indices),predicted_sleep_state(non_artefact_indices));
% [global_agreement,wake_agreement,SWS_agreement,REM_agreement] = compute_agreement(SleepState(non_artefact_indices),predicted_sleep_state(non_artefact_indices));
% else
% 	% compute agreement stats on only those epochs that were scored by hand
% 	kappa = compute_kappa(SleepState(scored_rows),predicted_sleep_state(scored_rows));
% 	[global_agreement,wake_agreement,SWS_agreement,REM_agreement] = compute_agreement(SleepState(scored_rows),predicted_sleep_state(scored_rows));
% 	disp('WARNING: The agreement parameters refer only to the subset of data that was scored by a human, not the entire dataset')
% 	% kappa = NaN;
% 	% global_agreement = NaN;         % if the original file hasn't been fully scored by a human, don't compute agreement statistics
% 	% wake_agreement = NaN;
% 	% SWS_agreement = NaN;
% 	% REM_agreement = NaN;
% end

predicted_score = predicted_sleep_state;

% export a new excel file where the column of sleep state has been overwritten with the computer-scored
% sleep states
if writefile
	% first make a directory based on the time stamp
	% a=find(filename=='\');
	% date_time = datestr(now,'mm.dd.yyyy.hh.MM');
	% output_directory = strcat(filename(1:a(end)),'Autoscore_output_',date_time);
	% mkdir(output_directory)
	%write_scored_file(filename,output_directory,predicted_score); % previous version
	write_scored_file_fast(filename,output_directory,predicted_score);  %new version, without needing to click on any windows
end



%save scatter_data_for_plotly.mat PCAvectors SleepState predicted_sleep_state Feature 