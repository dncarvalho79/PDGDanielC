function [dataOut] = loadAcordes54(dataIn,recdelay)
%load Data com findpeak

arguments (Input)
    dataIn
    recdelay
end

arguments (Output)
    dataOut
end

Acorde='54';

addpath('/Users/danielcarvalho/Library/CloudStorage/OneDrive-Pessoal/UFRJ/18 periodo/TCC/Base toda');
nomeMic='Acordes_Mic_54.wav';
nomeLine='Acordes_Line_54.wav';
[yMicFull,Fs]=audioread(nomeMic);
lFull=numel(yMicFull);
yMic=zeros(lFull+recdelay,1);
yMic(1:lFull)=yMicFull;
L=numel(yMic);
yMicFFT=fft(yMic,2*L);
%%
%figure(Name='mic peaks') 
%findpeaks(log10(1+abs(yMicFFT(1:end/2))),NPeaks=2000,SortStr="descend",MinPeakDistance=100,MinPeakProminence=0.1);        
[~,indListMic]=findpeaks(log10(1+abs(yMicFFT(1:end/2))),NPeaks=2000,SortStr="descend",MinPeakDistance=100,MinPeakProminence=0.1);        
%%

indListMic(:,2)=indListMic(:,1)*Fs/(2*L);
%indListMic(:,3)=indListMic(:,2)/indListMic(1,2);

[yLineFull,Fs]=audioread(nomeLine);
yLine=zeros(lFull+recdelay,1);
yLine(recdelay+1:lFull+recdelay)=yLineFull;

yLineFFT=fft(yLine,2*L);
%%
%figure(Name='line peaks')
%findpeaks(log10(1+abs(yLineFFT(1:end/2))),NPeaks=2000,SortStr="descend",MinPeakDistance=100,MinPeakProminence=0.1);   
[~,indListLine]=findpeaks(log10(1+abs(yLineFFT(1:end/2))),NPeaks=2000,SortStr="descend",MinPeakDistance=100,MinPeakProminence=0.1);   

indListLine(:,2)=indListLine(:,1)*Fs/(2*L);
%indListLine(:,3)=indListLine(:,2)/indListLine(1,2);
%%

HarmMic=zeros(length(indListMic),2);
HarmLine=zeros(length(indListLine),2);

HarmMic(:,1)=yMicFFT(indListMic(:,1));
HarmLine(:,1)=yLineFFT(indListLine(:,1));
HarmMic(:,2)=indListMic(:,2);
HarmLine(:,2)=indListLine(:,2);
%%

data=dataProcessAcordes(HarmMic,HarmLine,Acorde);

dataOut = [dataIn;data];

end