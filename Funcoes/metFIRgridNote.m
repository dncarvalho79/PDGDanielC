%sum grid note FIR base tudo junto
clear
tic
[yMic,Fs]=audioread("~/Library/CloudStorage/OneDrive-Pessoal/UFRJ/18 periodo/TCC/Base toda/tudoMic_01.wav");
[yLine]=audioread("~/Library/CloudStorage/OneDrive-Pessoal/UFRJ/18 periodo/TCC/Base toda/tudoLine_01.wav");
[yLineAlign,yMicAlign, delayRec]=alignsignals(yLine,yMic,"Truncate",1);

%yLineAlign = yLineAlign / (max(abs(yLineAlign)) + eps);
%yMicAlign  = yMicAlign  / (max(abs(yMicAlign)) + eps);

%%
nSize=length(yLine);
nVect=1:nSize;
n2Vect=1:nSize/2;
timeVect=nVect/Fs;
freqVect=(n2Vect-1) * (Fs / nSize);
yLineFFT=fft(yLineAlign);
yMicFFT=fft(yMicAlign);

%%
%137 para 23Khz
noteMax=137;
res=1;%Divisões de uma nota
noteID=1:res:noteMax;
FreqNote=2.^((noteID-69)/12)*440;
FreqLower=2.^((noteID-69-(0.5*res))/12)*440;
FreqUpper=2.^((noteID-69+(0.5*res))/12)*440;

%scatter(freqNote,zeros(length(noteID)), 'Marker', 'x', 'MarkerEdgeColor', 'red');
%hold on
%scatter(FreqLower,zeros(length(noteID)), 'Marker', '|', 'MarkerEdgeColor', 'black');
%scatter(FreqLower(1),0, 'Marker', '|', 'MarkerEdgeColor', 'red');
%scatter(FreqUpper,zeros(length(noteID)), 'Marker', '|', 'MarkerEdgeColor', 'black');
%xlim([80 24000])
%ylim([-30 30])
%xscale('log')

%%
data=[];
%1 mag mic
%2 mag line
%3 angle mic
%4 angle line
%5 complex mic
%6 complex line

for k=1:length(FreqNote)    
    binFreq=freqVect >= FreqLower(k) & freqVect <FreqUpper(k);
    data(k,1)=sum(abs(yMicFFT(binFreq)));
    data(k,2)=sum(abs(yLineFFT(binFreq)));
    %data(k,3)=mean(angle(yMicFFT(binFreq)));
    %data(k,4)=mean(angle(yLineFFT(binFreq)));
    %data(k,5)=sum(yMicFFT(binFreq));
    %data(k,6)=sum(yLineFFT(binFreq));



end

%%
figure('Name','Magnitudes')
plot(FreqNote,mag2db((data(:,2))),FreqNote,mag2db((data(:,1))));
title('Respostas em frequência dos sinais')
xlim([50 24000])
%ylim([-60 1])
xlabel('Frequência (Hz)');
ylabel('Magnitude (dB)');
legend('Linha','Microfone')
grid on
xscale("log")
%figure('Name','Magnitudes complex')
%plot(FreqNote,mag2db(abs(data(:,5))),FreqNote,mag2db(abs(data(:,6))));
%xscale("log")
%figure('Name','Angulos')
%plot(FreqNote,unwrap((data(:,3))),FreqNote,unwrap((data(:,4))));
%xscale("log")
%figure('Name','Angulos complex')
%plot(FreqNote,unwrap(angle(data(:,5))),FreqNote,unwrap(angle(data(:,6))));
%xscale("log")

%xlim([20 23006])

%%
resultado(:,1)=mag2db(data(:,1))-mag2db(data(:,2));
%resultado(:,2)=unwrap(data(:,3))-unwrap(data(:,4));
figure('Name','Resultado magnitude dB');
plot(FreqNote,resultado(:,1));
title('Curva final')
xlabel('Frequência (Hz)');
ylabel('Diferença de magnitude (dB)');
grid on
xscale("log")
xlim([50 24000])
ylim([-20 20])
%figure('Name','Resultado Fase');
%plot(FreqNote,resultado(:,2));
%xscale("log")
%xlim([20 23006])
%%
%{
%smooth data
mediaSize=1;
metodoMedia="movmean";

%movmean
%movmedian
%gaussian
%lowess
%loess
%rlowess
%rloess

resultado(:,2)=smoothdata(resultado(:,1),1,metodoMedia,mediaSize);

figure('Name','Data All smooth')
plot(FreqNote,resultado(:,2),FreqNote,resultado(:,1))
xlim([80 24000])
xscale('log')
xlabel('Frequência em Hz')
ylabel('Magitude da diferença em dB')
legend('data antes da média','Após média móvel')
%ylim([-20 20])
%}
%%
N=2^10;
F=FreqNote*2/Fs;
F(1)=0;
F(end)=1;
A= db2mag(resultado(:,1));
A(1:31)=0;
%H(135:end)=0;
d = fdesign.arbmag("N,F,A",N,F,A);
Hd = design(d,"freqsamp",SystemObject=true);
Hd.Numerator=Hd.Numerator/max(abs(Hd.Numerator));

%hFiltAnalyzer = filterAnalyzer(Hd);
%hFiltAnalyzer.setAnalysisOptions(MagnitudeMode="zerophase")
%%
figure('Name','Resposta do filtro FIR')
freqz(Hd,N,Fs)
subplot(2,1,1)
title('Magnitude')
xlim([0.050 24])
ylim([-20 20])
xlabel('Frequência (Khz)');
ylabel('Magnitude (dB)');
xscale('log')
subplot(2,1,2)
title('Fase')
xlim([0.050 24])
%ylim([-20 20])
xlabel('Frequência (Khz)');
ylabel('Fase (grau)');
%xscale('log')

%%
addpath('/Users/danielcarvalho/Library/CloudStorage/OneDrive-Pessoal/UFRJ/18 periodo/TCC/Arquivos de Teste');
addpath('/Users/danielcarvalho/Library/CloudStorage/OneDrive-Pessoal/UFRJ/18 periodo/TCC/PEAQ_matlab-main/PQevalAudio');
y=audioread('Violao mic play.wav');
[x, Fs]=audioread('Violao linha play.wav');
y=y(1:240000);
x=x(1:240000);

%%
xhat=Hd(x);
%xhat=filter(Hd.Numerator,1,xTest);
%%
[y_delay,~,delay_xhat]=alignsignals(y,xhat);
[x_delay,~, delay_x]=alignsignals(x,y_delay);
if delay_x < 0 || delay_xhat < 0
    disp('delay compensation error')
end
%Neste piorou

yPow=mean(y_delay.^2);
xhatPow=mean(xhat.^2);
ydiff=yPow/xhatPow;
xhat=xhat*ydiff;


%%
audiowrite('x.wav',x_delay,Fs);
audiowrite('y.wav',y_delay,Fs);
audiowrite('xhatFIRgridNoteFast.wav',xhat,Fs);
%%

peaqNotaX=PQevalAudio('y.wav','x.wav');
peaqNotaxHat=PQevalAudio('y.wav','xhatFIRgridNoteFast.wav'); %-2.129 rod 2 vez a partir da filtragem -2.378 na 1 %fast-3.034
%toc Elapsed time is 2.871419 seconds.