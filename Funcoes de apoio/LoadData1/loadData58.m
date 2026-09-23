function [dataOut] = loadData58(dataIn,plotOn,recdelay)
%load Data com findpeak

arguments (Input)
    dataIn
    plotOn
    recdelay
end

arguments (Output)
    dataOut
end

%Load com findpeaks individual nota 58
    minPeakDist=600;
    minPeakProminence=0.4;
    nPeaks=1000;    
casaCorda='01G';

addpath('/Users/danielcarvalho/Library/CloudStorage/OneDrive-Pessoal/UFRJ/18 periodo/TCC/Base toda');
nomeMic='Corda_G_Mic_1.wav';
nomeLine='Corda_G_Line_1.wav';
[yMicFull,Fs]=audioread(nomeMic);
lFull=numel(yMicFull);
yMic=zeros(lFull+recdelay,1);
yMic(1:lFull)=yMicFull;
L=numel(yMic);
yMicFFT=fft(yMic,2*L);
%%
    if plotOn==true
        figure(Name='mic peaks')
        findpeaks(log10(1+abs(yMicFFT(1:end/2))),NPeaks=nPeaks,SortStr="descend",MinPeakDistance=minPeakDist,MinPeakProminence=minPeakProminence);        
    end
    [~,indListMic]=findpeaks(log10(1+abs(yMicFFT(1:end/2))),NPeaks=nPeaks,SortStr="descend",MinPeakDistance=minPeakDist,MinPeakProminence=minPeakProminence);        
    HarmMic(:,1)=yMicFFT(indListMic);
    HarmMic(:,2)=indListMic*Fs/(2*L);
    %%
    [yLineFull,Fs]=audioread(nomeLine);
    yLine=zeros(lFull+recdelay,1);
    yLine(recdelay+1:lFull+recdelay)=yLineFull;    
    yLineFFT=fft(yLine,2*L);
    if plotOn==true
        figure(Name='line peaks')
        findpeaks(log10(1+abs(yLineFFT(1:end/2))),NPeaks=nPeaks,SortStr="descend",MinPeakDistance=minPeakDist,MinPeakProminence=minPeakProminence);   
    end
    [~,indListLine]=findpeaks(log10(1+abs(yLineFFT(1:end/2))),NPeaks=nPeaks,SortStr="descend",MinPeakDistance=minPeakDist,MinPeakProminence=minPeakProminence);   
    HarmLine(:,1)=yLineFFT(indListLine);
    HarmLine(:,2)=indListLine*Fs/(2*L);
    %%
    
    data=dataProcess(HarmMic,HarmLine,casaCorda);
    
    dataOut = [dataIn;data];
end