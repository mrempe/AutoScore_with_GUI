function[numArtifact,ArtifactEpochs]=DetectArtifact(FFTData,LactateYesOrNo,statearray,ThreshValue,ThreshText);
%FFTData is the matrix containing FFT data (typically this is called 'data'
%in SLEEPREPORT.m

%LactateYesOrNo is a digit: 1 indicates that there is no lactate data, hence 1 column for EEG artifact
%                           2 indicates that there are both lactate and EEG signals for artifact detection.

%this function was made to work with a 1-dimensional matrix (a vector called InputVector) that contains
%only the lactate data of interest.


%prompt = { ['This function will detect artifact in FFT values derived from physiological traces.' ...
%    '  It can do so by detecting those epochs in which FFTs exceed the mean by either a multiple of that mean'...
%    ' or by a number of standard deviations of that mean.  Type either "multiple" or "sd" to choose.  ']};
%ThreshText= char(inputdlg(prompt,'Input',1,{'multiple'}));

%prompt = { ['How many ', ThreshText 's above the mean is the threshold for artifact?']};
%ThreshValue= str2num(char(inputdlg(prompt,'Input',1,{'4'})));

ArtifactEpochs=zeros(length(FFTData),LactateYesOrNo+1);                  %Establish column 1 of matrix; this is the raw data.
AboveREMThresholdEeg1=zeros(length(FFTData));
AboveSWSThresholdEeg1=zeros(length(FFTData));
AboveWakeThresholdEeg1=zeros(length(FFTData));
AboveREMThresholdEeg2=zeros(length(FFTData));
AboveSWSThresholdEeg2=zeros(length(FFTData));
AboveWakeThresholdEeg2=zeros(length(FFTData));

if LactateYesOrNo==2
    
    REMMeanFftEeg1 = mean(FFTData((statearray=='R' | statearray=='P'),2:21));
    SWSMeanFftEeg1 =mean(FFTData((statearray=='S'),2:21));
    WakeMeanFftEeg1=mean(FFTData((statearray=='W' | statearray=='X'),2:21));
    REMMeanFftEeg2 = mean(FFTData((statearray=='R' | statearray=='P'),22:41));
    SWSMeanFftEeg2 =mean(FFTData((statearray=='S'),22:41));
    WakeMeanFftEeg2=mean(FFTData((statearray=='W' | statearray=='X'),22:41));
    
    if ~isempty(strfind(ThreshText,'multiple'))
        REMThresholdEeg1 = ThreshValue*REMMeanFftEeg1;   
        SWSThresholdEeg1 = ThreshValue*SWSMeanFftEeg1;       
        WakeThresholdEeg1= ThreshValue*WakeMeanFftEeg1;     
        REMThresholdEeg2 = ThreshValue*REMMeanFftEeg2;    
        SWSThresholdEeg2 = ThreshValue*SWSMeanFftEeg2;       
        WakeThresholdEeg2= ThreshValue*WakeMeanFftEeg2;      
    elseif ~isempty(strfind(ThreshText,'sd'))
        REMThresholdEeg1 = REMMeanFftEeg1+ThreshValue*std(FFTData((statearray=='R' | statearray=='P'),2:21));
        SWSThresholdEeg1 = SWSMeanFftEeg1+ThreshValue*std(FFTData((statearray=='S'),2:21));
        WakeThresholdEeg1= WakeMeanFftEeg1+ThreshValue*std(FFTData((statearray=='W' | statearray=='X'),2:21));
        REMThresholdEeg2 = REMMeanFftEeg1+ThreshValue*std(FFTData((statearray=='R' | statearray=='P'),22:41));
        SWSThresholdEeg2 = SWSMeanFftEeg1+ThreshValue*std(FFTData((statearray=='S'),22:41));
        WakeThresholdEeg2= WakeMeanFftEeg1+ThreshValue*std(FFTData((statearray=='W' | statearray=='X'),22:41));
    end
    
    AboveREMThresholdEeg1= max(bsxfun(@minus,FFTData(:,2:21),REMThresholdEeg1)')>0;
    AboveSWSThresholdEeg1= max(bsxfun(@minus,FFTData(:,2:21),SWSThresholdEeg1)')>0;
    AboveWakeThresholdEeg1= max(bsxfun(@minus,FFTData(:,2:21),WakeThresholdEeg1)')>0;
    AboveREMThresholdEeg2= max(bsxfun(@minus,FFTData(:,22:41),REMThresholdEeg2)')>0;
    AboveSWSThresholdEeg2= max(bsxfun(@minus,FFTData(:,22:41),SWSThresholdEeg2)')>0;
    AboveWakeThresholdEeg2= max(bsxfun(@minus,FFTData(:,22:41),WakeThresholdEeg2)')>0;
    
    REMWithArtifactEeg1=intersect(find(AboveREMThresholdEeg1>0),find((statearray=='R' | statearray=='P')));
    SWSWithArtifactEeg1 =intersect(find(AboveSWSThresholdEeg1>0),find((statearray=='S')));
    WakeWithArtifactEeg1=intersect(find(AboveWakeThresholdEeg1>0),find((statearray=='W')));
    REMWithArtifactEeg2 =intersect(find(AboveREMThresholdEeg2>0),find((statearray=='R' | statearray=='P')));
    SWSWithArtifactEeg2 =intersect(find(AboveSWSThresholdEeg2>0),find((statearray=='S')));
    WakeWithArtifactEeg2=intersect(find(AboveWakeThresholdEeg2>0),find((statearray=='W')));
    
    ArtifactEpochs(REMWithArtifactEeg1,2)=1;
    ArtifactEpochs(SWSWithArtifactEeg1,2)=1;
    ArtifactEpochs(WakeWithArtifactEeg1,2)=1;
    ArtifactEpochs(REMWithArtifactEeg2,3)=1;
    ArtifactEpochs(SWSWithArtifactEeg2,3)=1;
    ArtifactEpochs(WakeWithArtifactEeg2,3)=1;
    
    numArtifact(1)=length(WakeWithArtifactEeg1)/length(find(statearray=='W'))*100;
    numArtifact(2)=length(SWSWithArtifactEeg1)/length(find(statearray=='S'))*100;
    numArtifact(3)=length(REMWithArtifactEeg1)/length(find(statearray=='R' | statearray=='P'))*100;
    numArtifact(4)=length(WakeWithArtifactEeg2)/length(find(statearray=='W'))*100;
    numArtifact(5)=length(SWSWithArtifactEeg2)/length(find(statearray=='S'))*100;
    numArtifact(6)=length(REMWithArtifactEeg2)/length(find(statearray=='R' | statearray=='P'))*100;
        
else  %if LactateYesOrNo=1
    
    REMMeanFftEeg1 = mean(FFTData((statearray=='R' | statearray=='P'),1:20));
    SWSMeanFftEeg1 = mean(FFTData((statearray=='S'),1:20));
    WakeMeanFftEeg1= mean(FFTData((statearray=='W' | statearray=='X'),1:20));
    REMMeanFftEeg2 = mean(FFTData((statearray=='R' | statearray=='P'),21:40));
    SWSMeanFftEeg2 = mean(FFTData((statearray=='S'),21:40));
    WakeMeanFftEeg2= mean(FFTData((statearray=='W' | statearray=='X'),21:40));
    
    if ~isempty(strfind(ThreshText,'multiple'))
        REMThresholdEeg1 = ThreshValue*REMMeanFftEeg1;    
        SWSThresholdEeg1 = ThreshValue*SWSMeanFftEeg1;        
        WakeThresholdEeg1= ThreshValue*WakeMeanFftEeg1;       
        REMThresholdEeg2 = ThreshValue*REMMeanFftEeg2;   
        SWSThresholdEeg2 = ThreshValue*SWSMeanFftEeg2;      
        WakeThresholdEeg2= ThreshValue*WakeMeanFftEeg2;     
    elseif ~isempty(strfind(ThreshText,'sd'))
        REMThresholdEeg1 = REMMeanFftEeg1+ThreshValue*std(FFTData((statearray=='R' | statearray=='P'),1:20));
        SWSThresholdEeg1 = SWSMeanFftEeg1+ThreshValue*std(FFTData((statearray=='S'),1:20));
        WakeThresholdEeg1= WakeMeanFftEeg1+ThreshValue*std(FFTData((statearray=='W' | statearray=='X'),1:20));
        REMThresholdEeg2 = REMMeanFftEeg1+ThreshValue*std(FFTData((statearray=='R' | statearray=='P'),21:40));
        SWSThresholdEeg2 = SWSMeanFftEeg1+ThreshValue*std(FFTData((statearray=='S'),21:40));
        WakeThresholdEeg2= WakeMeanFftEeg1+ThreshValue*std(FFTData((statearray=='W' | statearray=='X'),21:40));
    end
    
    AboveREMThresholdEeg1= max(bsxfun(@minus,FFTData(:,2:21),REMThresholdEeg1)')>0;
    AboveSWSThresholdEeg1= max(bsxfun(@minus,FFTData(:,2:21),SWSThresholdEeg1)')>0;
    AboveWakeThresholdEeg1= max(bsxfun(@minus,FFTData(:,2:21),WakeThresholdEeg1)')>0;
    AboveREMThresholdEeg2= max(bsxfun(@minus,FFTData(:,22:41),REMThresholdEeg2)')>0;
    AboveSWSThresholdEeg2= max(bsxfun(@minus,FFTData(:,22:41),SWSThresholdEeg2)')>0;
    AboveWakeThresholdEeg2= max(bsxfun(@minus,FFTData(:,22:41),WakeThresholdEeg2)')>0;
    
    REMWithArtifactEeg1 =intersect(find(AboveREMThresholdEeg1>0),find((statearray=='R' | statearray=='P')));
    SWSWithArtifactEeg1 =intersect(find(AboveSWSThresholdEeg1>0),find((statearray=='S')));
    WakeWithArtifactEeg1=intersect(find(AboveWakeThresholdEeg1>0),find((statearray=='W')));
    REMWithArtifactEeg2 =intersect(find(AboveREMThresholdEeg2>0),find((statearray=='R' | statearray=='P')));
    SWSWithArtifactEeg2 =intersect(find(AboveSWSThresholdEeg2>0),find((statearray=='S')));
    WakeWithArtifactEeg2=intersect(find(AboveWakeThresholdEeg2>0),find((statearray=='W')));
    
    ArtifactEpochs(REMWithArtifactEeg1,2)=1;
    ArtifactEpochs(SWSWithArtifactEeg1,2)=1;
    ArtifactEpochs(WakeWithArtifactEeg1,2)=1;
    ArtifactEpochs(REMWithArtifactEeg2,3)=1;
    ArtifactEpochs(SWSWithArtifactEeg2,3)=1;
    ArtifactEpochs(WakeWithArtifactEeg2,3)=1;
    
    numArtifact(1)=length(find(ArtifactEpochs(:,2)>0));
    numArtifact(2)=length(find(ArtifactEpochs(:,3)>0));
    
    Disagree=length(find(ne (ArtifactEpochs(:,3),ArtifactEpochs(:,2))))
end

return
