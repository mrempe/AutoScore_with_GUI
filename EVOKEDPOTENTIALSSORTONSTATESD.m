%this program calls the function GetTtlIntensities.m to determine the intensities of laser stimuli triggered by TTL pulses.  The script first detects the start of real TTL pulses by assuming that those pulses are
%delivered at 1 Hz.  Thus in the event of a single spurious trigger (for instance when the pulse generator is powered up), that TTL pulse will be skipped and the first pulse in a string of pulses will be counted
%as the onset of stimuli.  From that pulse onward, it is assumed that the laser intensity changes once every 10 minutes... 10 min of 0 turns; 10 min of 2 turns; 4 turns 6 turns 8 turns 10 turns... 0 turns 2 turns etc.

clear

% look for 'matlab-utils' in the matlab folder
% addpath ../../../Matlab/etc/matlab-utils/;
%addpath ../../../../Matlab/etc/matlab-utils/
addpath C:/Users/wisorlab/Documents/MATLAB/Brennecke/matlab-pipeline/Matlab/etc/matlab-utils;
%addpath C:/Users/wisorlab/Documents/MATLAB/mrempe/Epoch-Based-Processing/Timed_Intervals/internal;
addpath (pwd)

[files,path] = uigetfile('Multiselect','on','*.edf');  %last parameter sent to uigetfile ('*.edf*) specifies that only edf files will be displayed in the user interface.
if ~iscell(files), files = {files}; end

prompt = { 'This program reports the intensity-response curve for evoked potential data. How many hours do you want to collapse into each analysis interval?' };
StartString = inputdlg(prompt,'Input',1,{'1'});
IntervalDuration = str2double( StartString{1,1} );    % starting epoch

prompt = { 'How many data points prior to and subsequent to each trigger point do you wish to extract.  Enter the two numbers separated by a space ' };
StartStopString = inputdlg(prompt,'Input',1,{'100 100'});
StartStop = regexp(StartStopString,'[,\s]+','split');
After = str2double( StartStop{1,1}{1,2} );    % stop epoch
Before = str2double( StartStop{1,1}{1,1} );    % start epoch
StartPoint=Before+1;

%NEED TO LOOK AT FILENAME AND DETERMINE WHETHER LEFT OR RIGHT STIM.
%IF RIGHT CHANNEL1=IPSIEEG AND CHANNEL2=CONTRAEEG.
%IF LEFTT CHANNEL2=IPSIEEG AND CHANNEL1=CONTRAEEG.

[ GroupingVariable,MatrixShift] = ExtractLeftRightVariablesFromFilename_Beta(files);

for animal=1:length(files)
    if ~isempty(strfind(lower(char(GroupingVariable(animal+1,2))),'left'))
        IpsiSide(animal)=2;
        ContraSide(animal)=1;
    elseif ~isempty(strfind(lower(char(GroupingVariable(animal+1,2))),'right'))
        IpsiSide(animal)=1;
        ContraSide(animal)=2;
    else
        warning ('NO EEG CHANNEL FOR STIMULUS FOUND IN FILENAME.  ASSUMING IT IS EEG1');
        IpsiSide(animal)=1;
        ContraSide(animal)=2;
    end
end %for loop that determines the number of columns of output data

IntensityCurvesIpsi=zeros(length(files),6,Before+After);
QWLoCurvesIpsi   =zeros(length(files),After+Before);
AWLoCurvesIpsi   =zeros(length(files),After+Before);
QWLoCurvesContra =zeros(length(files),After+Before);
AWLoCurvesContra =zeros(length(files),After+Before);
QWHiCurvesIpsi   =zeros(length(files),After+Before);
AWHiCurvesIpsi   =zeros(length(files),After+Before);
QWHiCurvesContra =zeros(length(files),After+Before);
AWHiCurvesContra =zeros(length(files),After+Before);
IpsiWakeAll=zeros(length(files),6,Before+After);
IpsiWakeLoBeta=zeros(length(files),6,Before+After);
IpsiWakeHiBeta=zeros(length(files),6,Before+After);
IpsiQWAll=zeros(length(files),6,Before+After);
IpsiQWLoBeta=zeros(length(files),6,Before+After);
IpsiQWHiBeta=zeros(length(files),6,Before+After);
IpsiAWAll=zeros(length(files),6,Before+After);
IpsiAWLoBeta=zeros(length(files),6,Before+After);
IpsiAWHiBeta=zeros(length(files),6,Before+After);

ContraWakeAll=zeros(length(files),6,Before+After);
ContraWakeLoBeta=zeros(length(files),6,Before+After);
ContraWakeHiBeta=zeros(length(files),6,Before+After);
ContraQWAll=zeros(length(files),6,Before+After);
ContraQWLoBeta=zeros(length(files),6,Before+After);
ContraQWHiBeta=zeros(length(files),6,Before+After);
ContraAWAll=zeros(length(files),6,Before+After);
ContraAWLoBeta=zeros(length(files),6,Before+After);
ContraAWHiBeta=zeros(length(files),6,Before+After);

for animal=1:length(files)
    
    edf = EdfHandle([path files{animal}]);
    [junk,textdata]=importdatafileTxt(strrep(files{animal},'.edf','.txt'),path);
    clear junk;
    
    tic
    
    [StartDifference] = TxtEdfTimeDiff(edf.starttime.datetime_struct,textdata,edf.fs(1));
    
    EmgStateRms=zeros(length(textdata),1);
    BetaState=zeros(length(textdata),2);
    for EmgCount=1:length(textdata)
        EmgStateRms(EmgCount)=rms(edf.data{3,1}((EmgCount-1)*10*edf.fs(3)+1+StartDifference:EmgCount*10*edf.fs(3)+StartDifference));
        [BetaIpsi(EmgCount,1),BetaIpsi(EmgCount,2)]=CalculateFftPowerTtl(edf.data{IpsiSide(animal),1}((EmgCount-1)*10*edf.fs(3)+1+StartDifference:EmgCount*10*edf.fs(3)+StartDifference),edf.fs(1),15,35,100);
        [GammaIpsi(EmgCount,1),GammaIpsi(EmgCount,2)]=CalculateFftPowerTtl(edf.data{IpsiSide(animal),1}((EmgCount-1)*10*edf.fs(3)+1+StartDifference:EmgCount*10*edf.fs(3)+StartDifference),edf.fs(1),80,90,100);
        [SwaIpsi(EmgCount,1),SwaIpsi(EmgCount,2)]=CalculateFftPowerTtl(edf.data{IpsiSide(animal),1}((EmgCount-1)*10*edf.fs(3)+1+StartDifference:EmgCount*10*edf.fs(3)+StartDifference),edf.fs(1),1,4,100);
        [BetaContra(EmgCount,1),BetaContra(EmgCount,2)]=CalculateFftPowerTtl(edf.data{ContraSide(animal),1}((EmgCount-1)*10*edf.fs(3)+1+StartDifference:EmgCount*10*edf.fs(3)+StartDifference),edf.fs(1),15,35,100);
        [GammaContra(EmgCount,1),GammaContra(EmgCount,2)]=CalculateFftPowerTtl(edf.data{ContraSide(animal),1}((EmgCount-1)*10*edf.fs(3)+1+StartDifference:EmgCount*10*edf.fs(3)+StartDifference),edf.fs(1),80,90,100);
        [SwaContra(EmgCount,1),SwaContra(EmgCount,2)]=CalculateFftPowerTtl(edf.data{IpsiSide(animal),1}((EmgCount-1)*10*edf.fs(3)+1+StartDifference:EmgCount*10*edf.fs(3)+StartDifference),edf.fs(1),1,4,100);
    end
    
    [AQWstate]=RescoreQuietVsActiveWake(char(textdata(:,2)),EmgStateRms,0.33,0.66,animal,files);
    
    for i=1:length(AQWstate)
        textdata{i,2}=cellstr(AQWstate(i));
    end
    
    [ Edf.state] = InsertEdfStateTrace(edf.starttime.datetime_struct,textdata(1,1),AQWstate,10,edf.fs(1),edf.samples(1));
    
    toc
    % sort by 10min intervals
    
    numIntervals(animal)=floor(length(edf.data{4,1})/edf.ttl.fs/(3600*IntervalDuration)); %calculate how many analysis intervals based on number of data point/fs samples per second/Seconds per hr * Hours per interval.
    
    [ttlOnsets,ttlIntensity,ttlHour]=GetTtlIntensities(edf.data{edf.ns},edf.ttl.fs);
    RealTtlOnsets=zeros(length(ttlOnsets)-1,2);
    RealTtlOnsets(:,1)=ttlOnsets(diff(ttlOnsets)>200);
    if ~isempty(strfind(lower(strjoin(GroupingVariable(animal+1,:))),'intens'));
        RealTtlOnsets(1:length(RealTtlOnsets),2)=rem(fix((1:length(RealTtlOnsets))/600),6);
%         RealTtlOnsets(RealTtlOnsets(:,2)==5,2)=10;
%         RealTtlOnsets(RealTtlOnsets(:,2)==4,2)=8;
%         RealTtlOnsets(RealTtlOnsets(:,2)==3,2)=6;
%         RealTtlOnsets(RealTtlOnsets(:,2)==2,2)=4;
%         RealTtlOnsets(RealTtlOnsets(:,2)==1,2)=2;
    else
        RealTtlOnsets(:,2)=10;
    end
       
    WakeTtlOnsets=RealTtlOnsets(find(Edf.state(RealTtlOnsets(:,1))=='W' | Edf.state(RealTtlOnsets(:,1))=='Q' | Edf.state(RealTtlOnsets(:,1))=='A'),1:2);  %array of sample numbers at which TTLs were delivered during W
    for i=1:length(WakeTtlOnsets)
        [WakeBetaValues(i,1),WakeBetaValues(i,1)]=CalculateFftPowerTtl(edf.data{IpsiSide(animal),1}(WakeTtlOnsets(i,1)-(edf.fs(IpsiSide(animal))/2):WakeTtlOnsets(i,1),:),edf.fs(IpsiSide(animal)),15,35,100);
    end
    WakeHiBetaTtl=WakeTtlOnsets(WakeBetaValues(:,1)>=quantile(WakeBetaValues(:,1),0.5),1:2);                     WakeLoBetaTtl=WakeTtlOnsets(WakeBetaValues(:,1)<quantile(WakeBetaValues(:,1),0.5),1:2);
    
    QWTtlOnsets=RealTtlOnsets  (find(Edf.state(RealTtlOnsets(:,1))=='Q'),1:2);  %array of sample numbers at which TTLs were delivered during W
    for i=1:length(QWTtlOnsets)
        [QWBetaValues(i,1),QWBetaValues(i,1)]=CalculateFftPowerTtl(edf.data{IpsiSide(animal),1}(QWTtlOnsets(i,1)-(edf.fs(IpsiSide(animal))/2):QWTtlOnsets(i,1),:),edf.fs(IpsiSide(animal)),15,35,100);
    end
    QWHiBetaTtl=QWTtlOnsets(QWBetaValues(:,1)>=quantile(QWBetaValues(:,1),0.5),1:2);                     QWLoBetaTtl=QWTtlOnsets(QWBetaValues(:,1)<quantile(QWBetaValues(:,1),0.5),1:2);
    
    AWTtlOnsets=RealTtlOnsets  (find(Edf.state(RealTtlOnsets(:,1))=='A'),1:2);  %array of sample numbers at which TTLs were delivered during W
    for i=1:length(AWTtlOnsets)
        [AWBetaValues(i,1),AWBetaValues(i,1)]=CalculateFftPowerTtl(edf.data{IpsiSide(animal),1}(AWTtlOnsets(i,1)-(edf.fs(IpsiSide(animal))/2):AWTtlOnsets(i,1),:),edf.fs(IpsiSide(animal)),15,35,100);
    end
    AWHiBetaTtl=AWTtlOnsets(AWBetaValues(:,1)>=quantile(AWBetaValues(:,1),0.5),1:2);                     AWLoBetaTtl=AWTtlOnsets(AWBetaValues(:,1)<quantile(AWBetaValues(:,1),0.5),1:2);
    
    SwsTtlOnsets=RealTtlOnsets (find(Edf.state(RealTtlOnsets(:,1))=='S'),1:2);   %array of sample numbers at which TTLs were delivered during S
    for i=1:length(SwsTtlOnsets)
        [SwsBetaValues(i,1),SwsBetaValues(i,1)]=CalculateFftPowerTtl(edf.data{IpsiSide(animal),1}(SwsTtlOnsets(i,1)-(edf.fs(IpsiSide(animal))/2):SwsTtlOnsets(i,1),:),edf.fs(IpsiSide(animal)),15,35,100);
    end
    SwsHiBetaTtl=SwsTtlOnsets(SwsBetaValues(:,1)>=quantile(SwsBetaValues(:,1),0.5),1:2);                     SwsLoBetaTtl=SwsTtlOnsets(SwsBetaValues(:,1)<quantile(SwsBetaValues(:,1),0.5),1:2);
    
    RemsTtlOnsets=RealTtlOnsets(find(Edf.state(RealTtlOnsets(:,1))=='R'),1:2);  %array of sample numbers at which TTLs were delivered during R    
    for i=1:length(RemsTtlOnsets)
        [RemsBetaValues(i,1),RemsBetaValues(i,1)]=CalculateFftPowerTtl(edf.data{IpsiSide(animal),1}(RemsTtlOnsets(i,1)-(edf.fs(IpsiSide(animal))/2):RemsTtlOnsets(i,1),:),edf.fs(IpsiSide(animal)),15,35,100);
    end
    RemsHiBetaTtl=RemsTtlOnsets(RemsBetaValues(:,1)>=quantile(RemsBetaValues(:,1),0.5),1:2);                     RemsLoBetaTtl=RemsTtlOnsets(RemsBetaValues(:,1)<quantile(RemsBetaValues(:,1),0.5),1:2);
    
    WAllCurvesIpsi    =zeros(length(WakeTtlOnsets),Before+After);
    WAllCurvesContra  =zeros(length(WakeTtlOnsets),Before+After);
    WLoCurvesIpsi    =zeros(length(WakeLoBetaTtl),Before+After);
    WLoCurvesContra  =zeros(length(WakeLoBetaTtl),Before+After);
    WHiCurvesIpsi    =zeros(length(WakeHiBetaTtl),Before+After);
    WHiCurvesContra  =zeros(length(WakeHiBetaTtl),Before+After);
    QAllCurvesIpsi    =zeros(length(QWTtlOnsets),Before+After);
    QAllCurvesContra  =zeros(length(QWTtlOnsets),Before+After);
    QLoCurvesIpsi    =zeros(length(QWLoBetaTtl),Before+After);
    QLoCurvesContra  =zeros(length(QWLoBetaTtl),Before+After);
    QHiCurvesIpsi    =zeros(length(QWHiBetaTtl),Before+After);
    QHiCurvesContra  =zeros(length(QWHiBetaTtl),Before+After);
    AAllCurvesIpsi    =zeros(length(AWTtlOnsets),Before+After);
    AAllCurvesContra  =zeros(length(AWTtlOnsets),Before+After);
    ALoCurvesIpsi    =zeros(length(AWLoBetaTtl),Before+After);
    ALoCurvesContra  =zeros(length(AWLoBetaTtl),Before+After);
    AHiCurvesIpsi    =zeros(length(AWHiBetaTtl),Before+After);
    AHiCurvesContra  =zeros(length(AWHiBetaTtl),Before+After);
    SAllCurvesIpsi    =zeros(length(SwsTtlOnsets),Before+After);
    SAllCurvesContra  =zeros(length(SwsTtlOnsets),Before+After);
    SLoCurvesIpsi    =zeros(length(SwsLoBetaTtl),Before+After);
    SLoCurvesContra  =zeros(length(SwsLoBetaTtl),Before+After);
    SHiCurvesIpsi    =zeros(length(SwsHiBetaTtl),Before+After);
    SHiCurvesContra  =zeros(length(SwsHiBetaTtl),Before+After);
    RAllCurvesIpsi    =zeros(length(RemsTtlOnsets),Before+After);
    RAllCurvesContra  =zeros(length(RemsTtlOnsets),Before+After);
    RLoCurvesIpsi    =zeros(length(RemsLoBetaTtl),Before+After);
    RLoCurvesContra  =zeros(length(RemsLoBetaTtl),Before+After);
    RHiCurvesIpsi    =zeros(length(RemsHiBetaTtl),Before+After);
    RHiCurvesContra  =zeros(length(RemsHiBetaTtl),Before+After);
    
    for i=1:length(WakeTtlOnsets)
        WAllCurvesIpsi(i,1:Before+After)=edf.data{IpsiSide(animal),1}(WakeTtlOnsets(i,1)-Before:WakeTtlOnsets(i,1)+After-1)';
        WAllCurvesContra(i,:)=edf.signals{1,ContraSide(animal)}.data(RealTtlOnsets(i)-Before:RealTtlOnsets(i)+After-1)';
    end;
    for i=1:length(WakeLoBetaTtl)
        WLoCurvesIpsi(i,1:Before+After)=edf.data{IpsiSide(animal),1}(WakeLoBetaTtl(i,1)-Before:WakeLoBetaTtl(i,1)+After-1)';
        WLoCurvesContra(i,:)=edf.signals{1,ContraSide(animal)}.data(WakeLoBetaTtl(i)-Before:WakeLoBetaTtl(i)+After-1)';
    end;
    for i=1:length(WakeHiBetaTtl)
        WHiCurvesIpsi(i,1:Before+After)=edf.data{IpsiSide(animal),1}(WakeHiBetaTtl(i,1)-Before:WakeHiBetaTtl(i,1)+After-1)';
        WHiCurvesContra(i,:)=edf.signals{1,ContraSide(animal)}.data(WakeHiBetaTtl(i)-Before:WakeHiBetaTtl(i)+After-1)';
    end;
    
    for i=1:length(QWTtlOnsets)
        QWAllCurvesIpsi(i,1:Before+After)=edf.data{IpsiSide(animal),1}(QWTtlOnsets(i,1)-Before:QWTtlOnsets(i,1)+After-1)';
        QWAllCurvesContra(i,:)=edf.signals{1,ContraSide(animal)}.data(RealTtlOnsets(i)-Before:RealTtlOnsets(i)+After-1)';
    end;
    for i=1:length(QWLoBetaTtl)
        QWLoCurvesIpsi(i,1:Before+After)=edf.data{IpsiSide(animal),1}(QWLoBetaTtl(i,1)-Before:QWLoBetaTtl(i,1)+After-1)';
        QWLoCurvesContra(i,:)=edf.signals{1,ContraSide(animal)}.data(QWLoBetaTtl(i)-Before:QWLoBetaTtl(i)+After-1)';
    end;
    for i=1:length(QWHiBetaTtl)
        QWHiCurvesIpsi(i,1:Before+After)=edf.data{IpsiSide(animal),1}(QWHiBetaTtl(i,1)-Before:QWHiBetaTtl(i,1)+After-1)';
        QWHiCurvesContra(i,:)=edf.signals{1,ContraSide(animal)}.data(QWHiBetaTtl(i)-Before:QWHiBetaTtl(i)+After-1)';
    end;
    
    for i=1:length(AWTtlOnsets)
        AWAllCurvesIpsi(i,1:Before+After)=edf.data{IpsiSide(animal),1}(AWTtlOnsets(i,1)-Before:AWTtlOnsets(i,1)+After-1)';
        AWAllCurvesContra(i,:)=edf.signals{1,ContraSide(animal)}.data(RealTtlOnsets(i)-Before:RealTtlOnsets(i)+After-1)';
    end;
    for i=1:length(AWLoBetaTtl)
        AWLoCurvesIpsi(i,1:Before+After)=edf.data{IpsiSide(animal),1}(AWLoBetaTtl(i,1)-Before:AWLoBetaTtl(i,1)+After-1)';
        AWLoCurvesContra(i,:)=edf.signals{1,ContraSide(animal)}.data(AWLoBetaTtl(i)-Before:AWLoBetaTtl(i)+After-1)';
    end;
    for i=1:length(AWHiBetaTtl)
        AWHiCurvesIpsi(i,1:Before+After)=edf.data{IpsiSide(animal),1}(AWHiBetaTtl(i,1)-Before:AWHiBetaTtl(i,1)+After-1)';
        AWHiCurvesContra(i,:)=edf.signals{1,ContraSide(animal)}.data(AWHiBetaTtl(i)-Before:AWHiBetaTtl(i)+After-1)';
    end;
    
    for i=1:length(SwsTtlOnsets)
        SAllCurvesIpsi(i,1:Before+After)=edf.data{IpsiSide(animal),1}(SwsTtlOnsets(i,1)-Before:SwsTtlOnsets(i,1)+After-1)';
        SAllCurvesContra(i,:)=edf.signals{1,ContraSide(animal)}.data(RealTtlOnsets(i)-Before:RealTtlOnsets(i)+After-1)';
    end;
    for i=1:length(SwsLoBetaTtl)
        SLoCurvesIpsi(i,1:Before+After)=edf.data{IpsiSide(animal),1}(SwsLoBetaTtl(i,1)-Before:SwsLoBetaTtl(i,1)+After-1)';
        SLoCurvesContra(i,:)=edf.signals{1,ContraSide(animal)}.data(SwsLoBetaTtl(i)-Before:SwsLoBetaTtl(i)+After-1)';
    end;
    for i=1:length(SwsHiBetaTtl)
        SHiCurvesIpsi(i,1:Before+After)=edf.data{IpsiSide(animal),1}(SwsHiBetaTtl(i,1)-Before:SwsHiBetaTtl(i,1)+After-1)';
        SHiCurvesContra(i,:)=edf.signals{1,ContraSide(animal)}.data(SwsHiBetaTtl(i)-Before:SwsHiBetaTtl(i)+After-1)';
    end;
    
    for i=1:length(RemsTtlOnsets)
        RAllCurvesIpsi(i,1:Before+After)=edf.data{IpsiSide(animal),1}(RemsTtlOnsets(i,1)-Before:RemsTtlOnsets(i,1)+After-1)';
        RAllCurvesContra(i,:)=edf.signals{1,ContraSide(animal)}.data(RemsTtlOnsets(i)-Before:RemsTtlOnsets(i)+After-1)';
    end;
    for i=1:length(RemsLoBetaTtl)
        RLoCurvesIpsi(i,1:Before+After)=edf.data{IpsiSide(animal),1}(RemsLoBetaTtl(i,1)-Before:RemsLoBetaTtl(i,1)+After-1)';
        RLoCurvesContra(i,:)=edf.signals{1,ContraSide(animal)}.data(RemsLoBetaTtl(i)-Before:RemsLoBetaTtl(i)+After-1);
    end;
    for i=1:length(RemsHiBetaTtl)
        RHiCurvesIpsi(i,1:Before+After)=edf.data{IpsiSide(animal),1}(RemsHiBetaTtl(i,1)-Before:RemsHiBetaTtl(i,1)+After-1)';
        RHiCurvesContra(i,:)=edf.signals{1,ContraSide(animal)}.data(RemsHiBetaTtl(i)-Before:RemsHiBetaTtl(i)+After-1)';
    end;

    for Intensity=0:5
        IpsiWakeAll   (animal,Intensity+1,:)   =mean(WAllCurvesIpsi(WakeTtlOnsets(:,2)==Intensity,:));
        IpsiWakeLoBeta(animal,Intensity+1,:)   =mean(WLoCurvesIpsi(WakeLoBetaTtl(:,2)==Intensity,:));
        IpsiWakeHiBeta(animal,Intensity+1,:)   =mean(WHiCurvesIpsi(WakeHiBetaTtl(:,2)==Intensity,:));
        IpsiQWAll   (animal,Intensity+1,:)   =mean(QWAllCurvesIpsi(QWTtlOnsets(:,2)==Intensity,:));
        IpsiQWLoBeta(animal,Intensity+1,:)   =mean(QWLoCurvesIpsi(QWLoBetaTtl(:,2)==Intensity,:));
        IpsiQWHiBeta(animal,Intensity+1,:)   =mean(QWHiCurvesIpsi(QWHiBetaTtl(:,2)==Intensity,:));
        IpsiAWAll   (animal,Intensity+1,:)   =mean(AWAllCurvesIpsi(AWTtlOnsets(:,2)==Intensity,:));
        IpsiAWLoBeta(animal,Intensity+1,:)   =mean(AWLoCurvesIpsi(AWLoBetaTtl(:,2)==Intensity,:));
        IpsiAWHiBeta(animal,Intensity+1,:)   =mean(AWHiCurvesIpsi(AWHiBetaTtl(:,2)==Intensity,:));
        IpsiSwsAll   (animal,Intensity+1,:)   =mean(SAllCurvesIpsi(SwsTtlOnsets(:,2)==Intensity,:));
        IpsiSwsLoBeta(animal,Intensity+1,:)   =mean(SLoCurvesIpsi(SwsLoBetaTtl(:,2)==Intensity,:));
        IpsiSwsHiBeta(animal,Intensity+1,:)   =mean(SHiCurvesIpsi(SwsHiBetaTtl(:,2)==Intensity,:));
        IpsiRemsAll   (animal,Intensity+1,:)   =mean(RAllCurvesIpsi(RemsTtlOnsets(:,2)==Intensity,:));
        IpsiRemsLoBeta(animal,Intensity+1,:)   =mean(RLoCurvesIpsi(RemsLoBetaTtl(:,2)==Intensity,:));
        IpsiRemsHiBeta(animal,Intensity+1,:)   =mean(RHiCurvesIpsi(RemsHiBetaTtl(:,2)==Intensity,:));
        ContraWakeAll   (animal,Intensity+1,:)   =mean(WAllCurvesContra(WakeTtlOnsets(:,2)==Intensity,:));
        ContraWakeLoBeta(animal,Intensity+1,:)   =mean(WLoCurvesContra(WakeLoBetaTtl(:,2)==Intensity,:));
        ContraWakeHiBeta(animal,Intensity+1,:)   =mean(WHiCurvesContra(WakeHiBetaTtl(:,2)==Intensity,:));
        ContraQWAll   (animal,Intensity+1,:)   =mean(QWAllCurvesContra(QWTtlOnsets(:,2)==Intensity,:));
        ContraQWLoBeta(animal,Intensity+1,:)   =mean(QWLoCurvesContra(QWLoBetaTtl(:,2)==Intensity,:));
        ContraQWHiBeta(animal,Intensity+1,:)   =mean(QWHiCurvesContra(QWHiBetaTtl(:,2)==Intensity,:));
        ContraAWAll   (animal,Intensity+1,:)   =mean(AWAllCurvesContra(AWTtlOnsets(:,2)==Intensity,:));
        ContraAWLoBeta(animal,Intensity+1,:)   =mean(AWLoCurvesContra(AWLoBetaTtl(:,2)==Intensity,:));
        ContraAWHiBeta(animal,Intensity+1,:)   =mean(AWHiCurvesContra(AWHiBetaTtl(:,2)==Intensity,:));
        ContraSwsAll   (animal,Intensity+1,:)   =mean(SAllCurvesContra(SwsTtlOnsets(:,2)==Intensity,:));
        ContraSwsLoBeta(animal,Intensity+1,:)   =mean(SLoCurvesContra(SwsLoBetaTtl(:,2)==Intensity,:));
        ContraSwsHiBeta(animal,Intensity+1,:)   =mean(SHiCurvesContra(SwsHiBetaTtl(:,2)==Intensity,:));
        ContraRemsAll   (animal,Intensity+1,:)   =mean(RAllCurvesContra(RemsTtlOnsets(:,2)==Intensity,:));
        ContraRemsLoBeta(animal,Intensity+1,:)   =mean(RLoCurvesContra(RemsLoBetaTtl(:,2)==Intensity,:));
        ContraRemsHiBeta(animal,Intensity+1,:)   =mean(RHiCurvesContra(RemsHiBetaTtl(:,2)==Intensity,:));
    
    end
end
%     
%     for Intensity=1:6
%         PeakIpsiWakeAll  (animal,Intensity)=max(IpsiWakeAll(animal,Intensity,Before:Before+40));
%         TroughIpsiWakeAll(animal,Intensity)=min(IpsiWakeAll(animal,Intensity,Before:Before+80));
%         PeakIpsiWakeLoBeta  (animal,Intensity)=max(IpsiWakeLoBeta(animal,Intensity,Before:Before+40));
%         TroughIpsiWakeLoBeta(animal,Intensity)=min(IpsiWakeLoBeta(animal,Intensity,Before:Before+80));
%         PeakIpsiWakeHiBeta  (animal,Intensity)=max(IpsiWakeHiBeta(animal,Intensity,Before:Before+40));
%         TroughIpsiWakeHiBeta(animal,Intensity)=min(IpsiWakeHiBeta(animal,Intensity,Before:Before+80));
%         PeakIpsiQWAll  (animal,Intensity)=max(IpsiQWAll(animal,Intensity,Before:Before+40));
%         TroughIpsiQWAll(animal,Intensity)=min(IpsiQWAll(animal,Intensity,Before:Before+80));
%         PeakIpsiQWLoBeta  (animal,Intensity)=max(IpsiQWLoBeta(animal,Intensity,Before:Before+40));
%         TroughIpsiQWLoBeta(animal,Intensity)=min(IpsiQWLoBeta(animal,Intensity,Before:Before+80));
%         PeakIpsiQWHiBeta  (animal,Intensity)=max(IpsiQWHiBeta(animal,Intensity,Before:Before+40));
%         TroughIpsiQWHiBeta(animal,Intensity)=min(IpsiQWHiBeta(animal,Intensity,Before:Before+80));
%         PeakIpsiAWAll  (animal,Intensity)=max(IpsiAWAll(animal,Intensity,Before:Before+40));
%         TroughIpsiAWAll(animal,Intensity)=min(IpsiAWAll(animal,Intensity,Before:Before+80));
%         PeakIpsiAWLoBeta  (animal,Intensity)=max(IpsiAWLoBeta(animal,Intensity,Before:Before+40));
%         TroughIpsiAWLoBeta(animal,Intensity)=min(IpsiAWLoBeta(animal,Intensity,Before:Before+80));
%         PeakIpsiAWHiBeta  (animal,Intensity)=max(IpsiAWHiBeta(animal,Intensity,Before:Before+40));
%         TroughIpsiAWHiBeta(animal,Intensity)=min(IpsiAWHiBeta(animal,Intensity,Before:Before+80));
%         
%         PeakContraWakeAll  (animal,Intensity)=max(ContraWakeAll(animal,Intensity,Before:Before+40));
%         TroughContraWakeAll(animal,Intensity)=min(ContraWakeAll(animal,Intensity,Before:Before+80));
%         PeakContraWakeLoBeta  (animal,Intensity)=max(ContraWakeLoBeta(animal,Intensity,Before:Before+40));
%         TroughContraWakeLoBeta(animal,Intensity)=min(ContraWakeLoBeta(animal,Intensity,Before:Before+80));
%         PeakContraWakeHiBeta  (animal,Intensity)=max(ContraWakeHiBeta(animal,Intensity,Before:Before+40));
%         TroughContraWakeHiBeta(animal,Intensity)=min(ContraWakeHiBeta(animal,Intensity,Before:Before+80));
%         PeakContraQWAll  (animal,Intensity)=max(ContraQWAll(animal,Intensity,Before:Before+40));
%         TroughContraQWAll(animal,Intensity)=min(ContraQWAll(animal,Intensity,Before:Before+80));
%         PeakContraQWLoBeta  (animal,Intensity)=max(ContraQWLoBeta(animal,Intensity,Before:Before+40));
%         TroughContraQWLoBeta(animal,Intensity)=min(ContraQWLoBeta(animal,Intensity,Before:Before+80));
%         PeakContraQWHiBeta  (animal,Intensity)=max(ContraQWHiBeta(animal,Intensity,Before:Before+40));
%         TroughContraQWHiBeta(animal,Intensity)=min(ContraQWHiBeta(animal,Intensity,Before:Before+80));
%         PeakContraAWAll  (animal,Intensity)=max(ContraAWAll(animal,Intensity,Before:Before+40));
%         TroughContraAWAll(animal,Intensity)=min(ContraAWAll(animal,Intensity,Before:Before+80));
%         PeakContraAWLoBeta  (animal,Intensity)=max(ContraAWLoBeta(animal,Intensity,Before:Before+40));
%         TroughContraAWLoBeta(animal,Intensity)=min(ContraAWLoBeta(animal,Intensity,Before:Before+80));
%         PeakContraAWHiBeta  (animal,Intensity)=max(ContraAWHiBeta(animal,Intensity,Before:Before+40));
%         TroughContraAWHiBeta(animal,Intensity)=min(ContraAWHiBeta(animal,Intensity,Before:Before+80));
%     end
%     
%     clear BetaAbsolute BetaNorm;
% end
% 
% IpsiZeroCurvesOut(1:length(files)+1,1:MatrixShift)  = GroupingVariable;
% IpsiZeroCurvesOut(1,MatrixShift+1:MatrixShift+(Before+After)*9)       = MakeLabelAllCurves(Before+After,'Beta');
% IpsiZeroCurvesOut(2:length(files)+1,MatrixShift+1:MatrixShift+Before+After) =                         num2cell(IpsiWakeAll(:,1,:));
% IpsiZeroCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*1+1:MatrixShift+(Before+After)*2) = num2cell(IpsiWakeLoBeta(:,1,:));
% IpsiZeroCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*2+1:MatrixShift+(Before+After)*3) = num2cell(IpsiWakeHiBeta(:,1,:));
% IpsiZeroCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*3+1:MatrixShift+(Before+After)*4) = num2cell     (IpsiQWAll(:,1,:));
% IpsiZeroCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*4+1:MatrixShift+(Before+After)*5) = num2cell  (IpsiQWLoBeta(:,1,:));
% IpsiZeroCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*5+1:MatrixShift+(Before+After)*6) = num2cell  (IpsiQWHiBeta(:,1,:));
% IpsiZeroCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*6+1:MatrixShift+(Before+After)*7) = num2cell     (IpsiAWAll(:,1,:));
% IpsiZeroCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*7+1:MatrixShift+(Before+After)*8) = num2cell  (IpsiAWLoBeta(:,1,:));
% IpsiZeroCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*8+1:MatrixShift+(Before+After)*9) = num2cell  (IpsiAWHiBeta(:,1,:));
% IpsiTwoCurvesOut(1:length(files)+1,1:MatrixShift)  = GroupingVariable;
% IpsiTwoCurvesOut(1,MatrixShift+1:MatrixShift+(Before+After)*9)       = MakeLabelAllCurves(Before+After,'Beta');
% IpsiTwoCurvesOut(2:length(files)+1,MatrixShift+1:MatrixShift+Before+After) =                         num2cell(IpsiWakeAll(:,2,:));
% IpsiTwoCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*1+1:MatrixShift+(Before+After)*2) = num2cell(IpsiWakeLoBeta(:,2,:));
% IpsiTwoCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*2+1:MatrixShift+(Before+After)*3) = num2cell(IpsiWakeHiBeta(:,2,:));
% IpsiTwoCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*3+1:MatrixShift+(Before+After)*4) = num2cell     (IpsiQWAll(:,2,:));
% IpsiTwoCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*4+1:MatrixShift+(Before+After)*5) = num2cell  (IpsiQWLoBeta(:,2,:));
% IpsiTwoCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*5+1:MatrixShift+(Before+After)*6) = num2cell  (IpsiQWHiBeta(:,2,:));
% IpsiTwoCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*6+1:MatrixShift+(Before+After)*7) = num2cell     (IpsiAWAll(:,2,:));
% IpsiTwoCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*7+1:MatrixShift+(Before+After)*8) = num2cell  (IpsiAWLoBeta(:,2,:));
% IpsiTwoCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*8+1:MatrixShift+(Before+After)*9) = num2cell  (IpsiAWHiBeta(:,2,:));
% IpsiFourCurvesOut(1:length(files)+1,1:MatrixShift)  = GroupingVariable;
% IpsiFourCurvesOut(1,MatrixShift+1:MatrixShift+(Before+After)*9)       = MakeLabelAllCurves(Before+After,'Beta');
% IpsiFourCurvesOut(2:length(files)+1,MatrixShift+1:MatrixShift+Before+After) =                         num2cell(IpsiWakeAll(:,3,:));
% IpsiFourCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*1+1:MatrixShift+(Before+After)*2) = num2cell(IpsiWakeLoBeta(:,3,:));
% IpsiFourCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*2+1:MatrixShift+(Before+After)*3) = num2cell(IpsiWakeHiBeta(:,3,:));
% IpsiFourCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*3+1:MatrixShift+(Before+After)*4) = num2cell     (IpsiQWAll(:,3,:));
% IpsiFourCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*4+1:MatrixShift+(Before+After)*5) = num2cell  (IpsiQWLoBeta(:,3,:));
% IpsiFourCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*5+1:MatrixShift+(Before+After)*6) = num2cell  (IpsiQWHiBeta(:,3,:));
% IpsiFourCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*6+1:MatrixShift+(Before+After)*7) = num2cell     (IpsiAWAll(:,3,:));
% IpsiFourCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*7+1:MatrixShift+(Before+After)*8) = num2cell  (IpsiAWLoBeta(:,3,:));
% IpsiFourCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*8+1:MatrixShift+(Before+After)*9) = num2cell  (IpsiAWHiBeta(:,3,:));
% IpsiSixCurvesOut(1:length(files)+1,1:MatrixShift)  = GroupingVariable;
% IpsiSixCurvesOut(1,MatrixShift+1:MatrixShift+(Before+After)*9)       = MakeLabelAllCurves(Before+After,'Beta');
% IpsiSixCurvesOut(2:length(files)+1,MatrixShift+1:MatrixShift+Before+After) =                         num2cell(IpsiWakeAll(:,4,:));
% IpsiSixCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*1+1:MatrixShift+(Before+After)*2) = num2cell(IpsiWakeLoBeta(:,4,:));
% IpsiSixCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*2+1:MatrixShift+(Before+After)*3) = num2cell(IpsiWakeHiBeta(:,4,:));
% IpsiSixCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*3+1:MatrixShift+(Before+After)*4) = num2cell     (IpsiQWAll(:,4,:));
% IpsiSixCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*4+1:MatrixShift+(Before+After)*5) = num2cell  (IpsiQWLoBeta(:,4,:));
% IpsiSixCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*5+1:MatrixShift+(Before+After)*6) = num2cell  (IpsiQWHiBeta(:,4,:));
% IpsiSixCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*6+1:MatrixShift+(Before+After)*7) = num2cell     (IpsiAWAll(:,4,:));
% IpsiSixCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*7+1:MatrixShift+(Before+After)*8) = num2cell  (IpsiAWLoBeta(:,4,:));
% IpsiSixCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*8+1:MatrixShift+(Before+After)*9) = num2cell  (IpsiAWHiBeta(:,4,:));
% IpsiEightCurvesOut(1:length(files)+1,1:MatrixShift)  = GroupingVariable;
% IpsiEightCurvesOut(1,MatrixShift+1:MatrixShift+(Before+After)*9)       = MakeLabelAllCurves(Before+After,'Beta');
% IpsiEightCurvesOut(2:length(files)+1,MatrixShift+1:MatrixShift+Before+After) =                         num2cell(IpsiWakeAll(:,5,:));
% IpsiEightCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*1+1:MatrixShift+(Before+After)*2) = num2cell(IpsiWakeLoBeta(:,5,:));
% IpsiEightCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*2+1:MatrixShift+(Before+After)*3) = num2cell(IpsiWakeHiBeta(:,5,:));
% IpsiEightCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*3+1:MatrixShift+(Before+After)*4) = num2cell     (IpsiQWAll(:,5,:));
% IpsiEightCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*4+1:MatrixShift+(Before+After)*5) = num2cell  (IpsiQWLoBeta(:,5,:));
% IpsiEightCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*5+1:MatrixShift+(Before+After)*6) = num2cell  (IpsiQWHiBeta(:,5,:));
% IpsiEightCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*6+1:MatrixShift+(Before+After)*7) = num2cell     (IpsiAWAll(:,5,:));
% IpsiEightCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*7+1:MatrixShift+(Before+After)*8) = num2cell  (IpsiAWLoBeta(:,5,:));
% IpsiEightCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*8+1:MatrixShift+(Before+After)*9) = num2cell  (IpsiAWHiBeta(:,5,:));
% IpsiTenCurvesOut(1:length(files)+1,1:MatrixShift)  = GroupingVariable;
% IpsiTenCurvesOut(1,MatrixShift+1:MatrixShift+(Before+After)*9)       = MakeLabelAllCurves(Before+After,'Beta');
% IpsiTenCurvesOut(2:length(files)+1,MatrixShift+1:MatrixShift+Before+After) =                         num2cell(IpsiWakeAll(:,6,:));
% IpsiTenCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*1+1:MatrixShift+(Before+After)*2) = num2cell(IpsiWakeLoBeta(:,6,:));
% IpsiTenCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*2+1:MatrixShift+(Before+After)*3) = num2cell(IpsiWakeHiBeta(:,6,:));
% IpsiTenCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*3+1:MatrixShift+(Before+After)*4) = num2cell     (IpsiQWAll(:,6,:));
% IpsiTenCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*4+1:MatrixShift+(Before+After)*5) = num2cell  (IpsiQWLoBeta(:,6,:));
% IpsiTenCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*5+1:MatrixShift+(Before+After)*6) = num2cell  (IpsiQWHiBeta(:,6,:));
% IpsiTenCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*6+1:MatrixShift+(Before+After)*7) = num2cell     (IpsiAWAll(:,6,:));
% IpsiTenCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*7+1:MatrixShift+(Before+After)*8) = num2cell  (IpsiAWLoBeta(:,6,:));
% IpsiTenCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*8+1:MatrixShift+(Before+After)*9) = num2cell  (IpsiAWHiBeta(:,6,:));
% 
% ContraZeroCurvesOut(1:length(files)+1,1:MatrixShift)  = GroupingVariable;
% ContraZeroCurvesOut(1,MatrixShift+1:MatrixShift+(Before+After)*9)       = MakeLabelAllCurves(Before+After,'Beta');
% ContraZeroCurvesOut(2:length(files)+1,MatrixShift+1:MatrixShift+Before+After) =                         num2cell(ContraWakeAll(:,1,:));
% ContraZeroCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*1+1:MatrixShift+(Before+After)*2) = num2cell(ContraWakeLoBeta(:,1,:));
% ContraZeroCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*2+1:MatrixShift+(Before+After)*3) = num2cell(ContraWakeHiBeta(:,1,:));
% ContraZeroCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*3+1:MatrixShift+(Before+After)*4) = num2cell     (ContraQWAll(:,1,:));
% ContraZeroCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*4+1:MatrixShift+(Before+After)*5) = num2cell  (ContraQWLoBeta(:,1,:));
% ContraZeroCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*5+1:MatrixShift+(Before+After)*6) = num2cell  (ContraQWHiBeta(:,1,:));
% ContraZeroCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*6+1:MatrixShift+(Before+After)*7) = num2cell     (ContraAWAll(:,1,:));
% ContraZeroCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*7+1:MatrixShift+(Before+After)*8) = num2cell  (ContraAWLoBeta(:,1,:));
% ContraZeroCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*8+1:MatrixShift+(Before+After)*9) = num2cell  (ContraAWHiBeta(:,1,:));
% ContraTwoCurvesOut(1:length(files)+1,1:MatrixShift)  = GroupingVariable;
% ContraTwoCurvesOut(1,MatrixShift+1:MatrixShift+(Before+After)*9)       = MakeLabelAllCurves(Before+After,'Beta');
% ContraTwoCurvesOut(2:length(files)+1,MatrixShift+1:MatrixShift+Before+After) =                         num2cell(ContraWakeAll(:,2,:));
% ContraTwoCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*1+1:MatrixShift+(Before+After)*2) = num2cell(ContraWakeLoBeta(:,2,:));
% ContraTwoCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*2+1:MatrixShift+(Before+After)*3) = num2cell(ContraWakeHiBeta(:,2,:));
% ContraTwoCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*3+1:MatrixShift+(Before+After)*4) = num2cell     (ContraQWAll(:,2,:));
% ContraTwoCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*4+1:MatrixShift+(Before+After)*5) = num2cell  (ContraQWLoBeta(:,2,:));
% ContraTwoCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*5+1:MatrixShift+(Before+After)*6) = num2cell  (ContraQWHiBeta(:,2,:));
% ContraTwoCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*6+1:MatrixShift+(Before+After)*7) = num2cell     (ContraAWAll(:,2,:));
% ContraTwoCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*7+1:MatrixShift+(Before+After)*8) = num2cell  (ContraAWLoBeta(:,2,:));
% ContraTwoCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*8+1:MatrixShift+(Before+After)*9) = num2cell  (ContraAWHiBeta(:,2,:));
% ContraFourCurvesOut(1:length(files)+1,1:MatrixShift)  = GroupingVariable;
% ContraFourCurvesOut(1,MatrixShift+1:MatrixShift+(Before+After)*9)       = MakeLabelAllCurves(Before+After,'Beta');
% ContraFourCurvesOut(2:length(files)+1,MatrixShift+1:MatrixShift+Before+After) =                         num2cell(ContraWakeAll(:,3,:));
% ContraFourCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*1+1:MatrixShift+(Before+After)*2) = num2cell(ContraWakeLoBeta(:,3,:));
% ContraFourCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*2+1:MatrixShift+(Before+After)*3) = num2cell(ContraWakeHiBeta(:,3,:));
% ContraFourCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*3+1:MatrixShift+(Before+After)*4) = num2cell     (ContraQWAll(:,3,:));
% ContraFourCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*4+1:MatrixShift+(Before+After)*5) = num2cell  (ContraQWLoBeta(:,3,:));
% ContraFourCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*5+1:MatrixShift+(Before+After)*6) = num2cell  (ContraQWHiBeta(:,3,:));
% ContraFourCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*6+1:MatrixShift+(Before+After)*7) = num2cell     (ContraAWAll(:,3,:));
% ContraFourCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*7+1:MatrixShift+(Before+After)*8) = num2cell  (ContraAWLoBeta(:,3,:));
% ContraFourCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*8+1:MatrixShift+(Before+After)*9) = num2cell  (ContraAWHiBeta(:,3,:));
% ContraSixCurvesOut(1:length(files)+1,1:MatrixShift)  = GroupingVariable;
% ContraSixCurvesOut(1,MatrixShift+1:MatrixShift+(Before+After)*9)       = MakeLabelAllCurves(Before+After,'Beta');
% ContraSixCurvesOut(2:length(files)+1,MatrixShift+1:MatrixShift+Before+After) =                         num2cell(ContraWakeAll(:,4,:));
% ContraSixCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*1+1:MatrixShift+(Before+After)*2) = num2cell(ContraWakeLoBeta(:,4,:));
% ContraSixCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*2+1:MatrixShift+(Before+After)*3) = num2cell(ContraWakeHiBeta(:,4,:));
% ContraSixCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*3+1:MatrixShift+(Before+After)*4) = num2cell     (ContraQWAll(:,4,:));
% ContraSixCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*4+1:MatrixShift+(Before+After)*5) = num2cell  (ContraQWLoBeta(:,4,:));
% ContraSixCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*5+1:MatrixShift+(Before+After)*6) = num2cell  (ContraQWHiBeta(:,4,:));
% ContraSixCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*6+1:MatrixShift+(Before+After)*7) = num2cell     (ContraAWAll(:,4,:));
% ContraSixCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*7+1:MatrixShift+(Before+After)*8) = num2cell  (ContraAWLoBeta(:,4,:));
% ContraSixCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*8+1:MatrixShift+(Before+After)*9) = num2cell  (ContraAWHiBeta(:,4,:));
% ContraEightCurvesOut(1:length(files)+1,1:MatrixShift)  = GroupingVariable;
% ContraEightCurvesOut(1,MatrixShift+1:MatrixShift+(Before+After)*9)       = MakeLabelAllCurves(Before+After,'Beta');
% ContraEightCurvesOut(2:length(files)+1,MatrixShift+1:MatrixShift+Before+After) =                         num2cell(ContraWakeAll(:,5,:));
% ContraEightCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*1+1:MatrixShift+(Before+After)*2) = num2cell(ContraWakeLoBeta(:,5,:));
% ContraEightCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*2+1:MatrixShift+(Before+After)*3) = num2cell(ContraWakeHiBeta(:,5,:));
% ContraEightCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*3+1:MatrixShift+(Before+After)*4) = num2cell     (ContraQWAll(:,5,:));
% ContraEightCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*4+1:MatrixShift+(Before+After)*5) = num2cell  (ContraQWLoBeta(:,5,:));
% ContraEightCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*5+1:MatrixShift+(Before+After)*6) = num2cell  (ContraQWHiBeta(:,5,:));
% ContraEightCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*6+1:MatrixShift+(Before+After)*7) = num2cell     (ContraAWAll(:,5,:));
% ContraEightCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*7+1:MatrixShift+(Before+After)*8) = num2cell  (ContraAWLoBeta(:,5,:));
% ContraEightCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*8+1:MatrixShift+(Before+After)*9) = num2cell  (ContraAWHiBeta(:,5,:));
% ContraTenCurvesOut(1:length(files)+1,1:MatrixShift)  = GroupingVariable;
% ContraTenCurvesOut(1,MatrixShift+1:MatrixShift+(Before+After)*9)       = MakeLabelAllCurves(Before+After,'Beta');
% ContraTenCurvesOut(2:length(files)+1,MatrixShift+1:MatrixShift+Before+After) =                         num2cell(ContraWakeAll(:,6,:));
% ContraTenCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*1+1:MatrixShift+(Before+After)*2) = num2cell(ContraWakeLoBeta(:,6,:));
% ContraTenCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*2+1:MatrixShift+(Before+After)*3) = num2cell(ContraWakeHiBeta(:,6,:));
% ContraTenCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*3+1:MatrixShift+(Before+After)*4) = num2cell     (ContraQWAll(:,6,:));
% ContraTenCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*4+1:MatrixShift+(Before+After)*5) = num2cell  (ContraQWLoBeta(:,6,:));
% ContraTenCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*5+1:MatrixShift+(Before+After)*6) = num2cell  (ContraQWHiBeta(:,6,:));
% ContraTenCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*6+1:MatrixShift+(Before+After)*7) = num2cell     (ContraAWAll(:,6,:));
% ContraTenCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*7+1:MatrixShift+(Before+After)*8) = num2cell  (ContraAWLoBeta(:,6,:));
% ContraTenCurvesOut(2:length(files)+1,MatrixShift+(Before+After)*8+1:MatrixShift+(Before+After)*9) = num2cell  (ContraAWHiBeta(:,6,:));
% 
% ContraPeaks(1:length(files)+1,1:MatrixShift)      = GroupingVariable;
% ContraPeaks(1,MatrixShift+1:MatrixShift+54)       = MakeLabelPeakTrough(6,'Beta');
% ContraPeaks(2:length(files)+1,MatrixShift+1:MatrixShift+6*1) = num2cell(PeakContraWakeAll(:,:));
% ContraPeaks(2:length(files)+1,MatrixShift+1+6*1:MatrixShift+6*2) = num2cell(PeakContraWakeLoBeta(:,:));
% ContraPeaks(2:length(files)+1,MatrixShift+1+6*2:MatrixShift+6*3) = num2cell(PeakContraWakeHiBeta(:,:));
% ContraPeaks(2:length(files)+1,MatrixShift+1+6*3:MatrixShift+6*4) = num2cell(PeakContraQWAll(:,:));
% ContraPeaks(2:length(files)+1,MatrixShift+1+6*4:MatrixShift+6*5) = num2cell(PeakContraQWLoBeta(:,:));
% ContraPeaks(2:length(files)+1,MatrixShift+1+6*5:MatrixShift+6*6) = num2cell(PeakContraQWHiBeta(:,:));
% ContraPeaks(2:length(files)+1,MatrixShift+1+6*6:MatrixShift+6*7) = num2cell(PeakContraAWAll(:,:));
% ContraPeaks(2:length(files)+1,MatrixShift+1+6*7:MatrixShift+6*8) = num2cell(PeakContraAWLoBeta(:,:));
% ContraPeaks(2:length(files)+1,MatrixShift+1+6*8:MatrixShift+6*9) = num2cell(PeakContraAWHiBeta(:,:));
% ContraTroughs(1:length(files)+1,1:MatrixShift)      = GroupingVariable;
% ContraTroughs(1,MatrixShift+1:MatrixShift+54)       = MakeLabelPeakTrough(6,'Beta');
% ContraTroughs(2:length(files)+1,MatrixShift+1:MatrixShift+6*1) = num2cell(TroughContraWakeAll(:,:));
% ContraTroughs(2:length(files)+1,MatrixShift+1+6*1:MatrixShift+6*2) = num2cell(TroughContraWakeLoBeta(:,:));
% ContraTroughs(2:length(files)+1,MatrixShift+1+6*2:MatrixShift+6*3) = num2cell(TroughContraWakeHiBeta(:,:));
% ContraTroughs(2:length(files)+1,MatrixShift+1+6*3:MatrixShift+6*4) = num2cell(TroughContraQWAll(:,:));
% ContraTroughs(2:length(files)+1,MatrixShift+1+6*4:MatrixShift+6*5) = num2cell(TroughContraQWLoBeta(:,:));
% ContraTroughs(2:length(files)+1,MatrixShift+1+6*5:MatrixShift+6*6) = num2cell(TroughContraQWHiBeta(:,:));
% ContraTroughs(2:length(files)+1,MatrixShift+1+6*6:MatrixShift+6*7) = num2cell(TroughContraAWAll(:,:));
% ContraTroughs(2:length(files)+1,MatrixShift+1+6*7:MatrixShift+6*8) = num2cell(TroughContraAWLoBeta(:,:));
% ContraTroughs(2:length(files)+1,MatrixShift+1+6*8:MatrixShift+6*9) = num2cell(TroughContraAWHiBeta(:,:));
% IpsiPeaks(1:length(files)+1,1:MatrixShift)      = GroupingVariable;
% IpsiPeaks(1,MatrixShift+1:MatrixShift+54)       = MakeLabelPeakTrough(6,'Beta');
% IpsiPeaks(2:length(files)+1,MatrixShift+1:MatrixShift+6*1) = num2cell(PeakIpsiWakeAll(:,:));
% IpsiPeaks(2:length(files)+1,MatrixShift+1+6*1:MatrixShift+6*2) = num2cell(PeakIpsiWakeLoBeta(:,:));
% IpsiPeaks(2:length(files)+1,MatrixShift+1+6*2:MatrixShift+6*3) = num2cell(PeakIpsiWakeHiBeta(:,:));
% IpsiPeaks(2:length(files)+1,MatrixShift+1+6*3:MatrixShift+6*4) = num2cell(PeakIpsiQWAll(:,:));
% IpsiPeaks(2:length(files)+1,MatrixShift+1+6*4:MatrixShift+6*5) = num2cell(PeakIpsiQWLoBeta(:,:));
% IpsiPeaks(2:length(files)+1,MatrixShift+1+6*5:MatrixShift+6*6) = num2cell(PeakIpsiQWHiBeta(:,:));
% IpsiPeaks(2:length(files)+1,MatrixShift+1+6*6:MatrixShift+6*7) = num2cell(PeakIpsiAWAll(:,:));
% IpsiPeaks(2:length(files)+1,MatrixShift+1+6*7:MatrixShift+6*8) = num2cell(PeakIpsiAWLoBeta(:,:));
% IpsiPeaks(2:length(files)+1,MatrixShift+1+6*8:MatrixShift+6*9) = num2cell(PeakIpsiAWHiBeta(:,:));
% IpsiTroughs(1:length(files)+1,1:MatrixShift)      = GroupingVariable;
% IpsiTroughs(1,MatrixShift+1:MatrixShift+54)       = MakeLabelPeakTrough(6,'Beta');
% IpsiTroughs(2:length(files)+1,MatrixShift+1:MatrixShift+6*1) = num2cell(TroughIpsiWakeAll(:,:));
% IpsiTroughs(2:length(files)+1,MatrixShift+1+6*1:MatrixShift+6*2) = num2cell(TroughIpsiWakeLoBeta(:,:));
% IpsiTroughs(2:length(files)+1,MatrixShift+1+6*2:MatrixShift+6*3) = num2cell(TroughIpsiWakeHiBeta(:,:));
% IpsiTroughs(2:length(files)+1,MatrixShift+1+6*3:MatrixShift+6*4) = num2cell(TroughIpsiQWAll(:,:));
% IpsiTroughs(2:length(files)+1,MatrixShift+1+6*4:MatrixShift+6*5) = num2cell(TroughIpsiQWLoBeta(:,:));
% IpsiTroughs(2:length(files)+1,MatrixShift+1+6*5:MatrixShift+6*6) = num2cell(TroughIpsiQWHiBeta(:,:));
% IpsiTroughs(2:length(files)+1,MatrixShift+1+6*6:MatrixShift+6*7) = num2cell(TroughIpsiAWAll(:,:));
% IpsiTroughs(2:length(files)+1,MatrixShift+1+6*7:MatrixShift+6*8) = num2cell(TroughIpsiAWLoBeta(:,:));
% IpsiTroughs(2:length(files)+1,MatrixShift+1+6*8:MatrixShift+6*9) = num2cell(TroughIpsiAWHiBeta(:,:));
% 
% xl = XL;
% xl.sourceInfo(mfilename('fullpath'));
% xl.rmDefaultSheets();
% xl2 = XL;
% xl2.sourceInfo(mfilename('fullpath'));
% xl2.rmDefaultSheets();
% 
% sheetsA = xl.addSheets({ 'Ipsi Troughs' 'Ipsi Peaks' 'IpsiCurves10Turns'  'IpsiCurves8Turns'  'IpsiCurves6Turns'  'IpsiCurves4Turns'  'IpsiCurves2Turns'  'IpsiCurves0Turns' });
% sheetsB = xl2.addSheets({ 'Contra Troughs' 'Contra Peaks' 'ContraCurves10Turns'  'ContraCurves8Turns'  'ContraCurves6Turns'  'ContraCurves4Turns'  'ContraCurves2Turns'  'ContraCurves0Turns' });
% 
% xl.setCells( sheetsA{8}, [1,1], [ IpsiZeroCurvesOut ] );
% xl.setCells( sheetsA{7}, [1,1], [ IpsiTwoCurvesOut ] );
% xl.setCells( sheetsA{6}, [1,1], [ IpsiFourCurvesOut ] );
% xl.setCells( sheetsA{5}, [1,1], [ IpsiSixCurvesOut ] );
% xl.setCells( sheetsA{4}, [1,1], [ IpsiEightCurvesOut ] );
% xl.setCells( sheetsA{3}, [1,1], [ IpsiTenCurvesOut ] );
% xl.setCells( sheetsA{2}, [1,1], [ IpsiPeaks ] );
% xl.setCells( sheetsA{1}, [1,1], [ IpsiTroughs ] );
% 
% xl2.setCells( sheetsB{8}, [1,1], [ ContraZeroCurvesOut ] );
% xl2.setCells( sheetsB{7}, [1,1], [ ContraTwoCurvesOut ] );
% xl2.setCells( sheetsB{6}, [1,1], [ ContraFourCurvesOut ] );
% xl2.setCells( sheetsB{5}, [1,1], [ ContraSixCurvesOut ] );
% xl2.setCells( sheetsB{4}, [1,1], [ ContraEightCurvesOut ] );
% xl2.setCells( sheetsB{3}, [1,1], [ ContraTenCurvesOut ] );
% xl2.setCells( sheetsB{2}, [1,1], [ ContraPeaks ] );
% xl2.setCells( sheetsB{1}, [1,1], [ ContraTroughs ] );
% 
% xl.saveAs(['Ipsi Evoked Traces W_QW_AW _25Pct75PctGamma'],path);
% xl2.saveAs(['Contra Evoked Traces W_QW_AW _25Pct75PctGamma'],path);
% 
% load chirp
% sound  (y)
% 
% 
