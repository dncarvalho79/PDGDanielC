%divdas DFTs

clear
tic
[yMic,Fs]=audioread("~/Library/CloudStorage/OneDrive-Pessoal/UFRJ/18 periodo/TCC/Base toda/tudoMic_01.wav");
[yLine]=audioread("~/Library/CloudStorage/OneDrive-Pessoal/UFRJ/18 periodo/TCC/Base toda/tudoLine_01.wav");
[yLineAlign,yMicAlign, delayRec]=alignsignals(yLine,yMic,"Truncate",1);

%yLineAlign = yLineAlign / (max(abs(yLineAlign)) + eps);
%yMicAlign  = yMicAlign  / (max(abs(yMicAlign)) + eps);

%%
n=length(yLine);
nVect=1:n;
timeVect=nVect/Fs;
freqVect=(nVect-1) * (Fs / n);


yLineFFT=fft(yLineAlign);
yMicFFT=fft(yMicAlign);

%%
figure('name','Magnitude')
plot(freqVect(1:n/2),mag2db(1+abs(yLineFFT(1:n/2))));
title('Espectros de frequência')

xscale('log')
xlim([50 24000])
hold on
plot(freqVect(1:n/2),mag2db(1+abs(yMicFFT(1:n/2))));
hold off
legend('Sinal de linha','Sinal do microfone')
xlabel('Frequência (Hz)');
ylabel('Magnitude (dB)');

figure('name','Phase')
plot(freqVect(1:n/2),unwrap(angle(yLineFFT(1:n/2))));
title('Fases')
xlabel('Frequência (Hz)');
ylabel('Fase (grau)');


hold on
plot(freqVect(1:n/2),unwrap(angle(yMicFFT(1:n/2))));
legend('Sinal de linha','Sinal do microfone')
hold off
figure('name','Phase diff')

phaseDiff=unwrap(angle(yMicFFT(1:n/2)))-unwrap(angle(yLineFFT(1:n/2)));
plot(freqVect(1:n/2),phaseDiff,color='black');
%xscale('log')
xlabel('Frequência (Hz)');
ylabel('Fase (grau)');
title('Diferença das fases')

%%
L=2^10;
freqResp=yMicFFT./yLineFFT;
b=ifft(freqResp);
b=b(1:L);
%b=b/(sqrt(sum(b.^2)));
%b=b/max(b);
%b=b/sum(b);

[h, f] = freqz(b, 1,L, Fs); 


figure('name','Res Freq Div FFT')


plot(f, mag2db(abs(h)),Color='black');
title('Curva resultante')
xscale("log")
xlim([50 24000])
ylim([-40 40])
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
grid on

%%

addpath('/Users/danielcarvalho/Library/CloudStorage/OneDrive-Pessoal/UFRJ/18 periodo/TCC/Arquivos de Teste');
addpath('/Users/danielcarvalho/Library/CloudStorage/OneDrive-Pessoal/UFRJ/18 periodo/TCC/PEAQ_matlab-main/PQevalAudio');
y=audioread('Violao mic play.wav');
[x, Fs]=audioread('Violao linha play.wav');
y=y(1:240000);
x=x(1:240000);

%%
%xhat=Hd(x);
xhat=filter(b,1,x);
%%
[y_delay,~,delay_xhat]=alignsignals(y,xhat);
[x_delay,~, delay_x]=alignsignals(x,y_delay);
if delay_x < 0 || delay_xhat < 0
    disp('delay compensation error')
end
%Neste piorou
%{
yPow=mean(y_delay.^2);
xhatPow=mean(xhat.^2);
ydiff=yPow/xhatPow;
xhat=xhat*ydiff;
%}

%%
audiowrite('x.wav',x_delay,Fs);
audiowrite('y.wav',y_delay,Fs);
audiowrite('xhatDivFreqFast.wav',xhat,Fs);
%%

peaqNotaX=PQevalAudio('y.wav','x.wav');
peaqNotaxHat=PQevalAudio('y.wav','xhatDivFreqFast.wav'); %n16-3.898 fast -2.902

toc%Elapsed time is 1.221531 seconds.