function kappa=compute_kappa(v1,v2)
%Usage: kappa=compute_kappa(v1,v2)
%
	% this function computes the kappa statistic for two different 
	% vectors that contain the sleep scoring (0=wake,1=SWS,2=REM) for 
	% every epoch of a recording. Kappa gives a measure of how 
	% well the two scoring methods agree



	if length(v1) ~= length(v2)
		error('v1 and v2 must have the same length')
	end


	% Case where v1 and v2 contain letters
	if iscell(v1) & iscell(v2)
	
		% check to see if there are any empty cells
		emptycells1 = cellfun(@isempty,v1);
	 	emptycells2 = cellfun(@isempty,v2);
		if sum(emptycells1) > 0 | emptycells2 > 0
			error('One or both of the files contains unscored epochs')
		end


		v1 = cell2mat(v1);
		v2 = cell2mat(v2);

		% Set up the Interobserver Variation table
		both_wake = length(find(v1=='W' & v2=='W'));
		both_SWS  = length(find(v1=='S' & v2=='S'));
		both_REM  = length(find((v1=='R' | v1=='P') & (v2=='R' | v2=='P')));

		W1_S2 = length(find(v1=='W' & v2=='S'));
		W1_R2 = length(find(v1=='W' & (v2=='R'| v2=='P')));
		S1_W2 = length(find(v1=='S' & v2=='W'));
		S1_R2 = length(find(v1=='S' & v2=='R'));
		R1_W2 = length(find((v1=='R' | v1=='P') & v2=='W'));
		R1_S2 = length(find((v1=='R' | v1=='P') & v2=='S'));


	else % if v1 and v2 contain numbers, not letters

		% Set up the Interobserver Variation table
		both_wake = length(find(v1==0 & v2==0));
		both_SWS  = length(find(v1==1 & v2==1));
		both_REM  = length(find(v1==2 & v2==2));

		W1_S2 = length(find(v1==0 & v2==1));
		W1_R2 = length(find(v1==0 & v2==2));
		S1_W2 = length(find(v1==1 & v2==0));
		S1_R2 = length(find(v1==1 & v2==2));
		R1_W2 = length(find(v1==2 & v2==0));
		R1_S2 = length(find(v1==2 & v2==1));
	end

	% Compute lengths
	n  = length(v1);  %total number of epochs
	n2 = both_wake + W1_S2 + W1_R2;
	n1 = S1_W2 + both_SWS + S1_R2;
	n0 = R1_W2 + R1_S2 + both_REM;

	m2 = both_wake + S1_W2 + R1_W2;
	m1 = W1_S2 + both_SWS + R1_S2;
	m0 = W1_R2 + S1_R2 + both_REM;


	% Observed agreement
	po = (both_wake + both_SWS + both_REM)/n;

	% Expected agreement
	pe = ((n2/n)*(m2/n)) + ((n1/n)*(m1/n)) + ((n0/n)*(m0/n));

	% Kappa
	kappa = (po-pe)/(1-pe);


	% as an aside, compute "global agreement" like Rytkonen does:
	%global_agreement=1-(length(find(v1-v2))/length(v1))