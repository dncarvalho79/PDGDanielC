clear
clc
tic
[yMic,Fs]=audioread("~/Library/CloudStorage/OneDrive-Pessoal/UFRJ/18 periodo/TCC/Base toda/tudoMic_01.wav");
[yLine]=audioread("~/Library/CloudStorage/OneDrive-Pessoal/UFRJ/18 periodo/TCC/Base toda/tudoLine_01.wav");
n=length(yLine);
[yLineAlign,yMicAlign, delayRec]=alignsignals(yLine,yMic,"Truncate",1);

%%
seg=3.4;

yLineCut=yLineAlign(1:48000*seg);
yMicCut=yMicAlign(1:48000*seg);
%yLineCut = yLineCut / (max(abs(yLineCut)) + eps);
%yMicCut  = yMicCut  / (max(abs(yMicCut)) + eps);


%%
L=2^10;%2^10
lag=L/2;
%%
yLineCut=[zeros(lag,1);yLineCut];
yMicCut=[yMicCut;zeros(lag,1)];

%yLineCut=[yLineCut;zeros(lag,1)];
%yMicCut=[zeros(lag,1);yMicCut];


%%


nlms = dsp.LMSFilter(L, 'Method', 'Normalized LMS');
[mumaxnlms, mumaxmsenlms] = maxstep(nlms, yLineCut);

%nlms.StepSize = mumaxmsenlms /20;

nlms.StepSize = 1.9;%1.9
%%
[yNLMS,err,coeff] = nlms(yLineCut, yMicCut);

%%
figure('Name','Erro NLMS')
semilogy(err.^2)
title('Erro NLMS')
xlabel('Amostra');
ylabel('Erro médio quadrático');
%%
b=coeff;
b=b./sqrt(sum(b.^2));
figure('Name','Resp Freq NLMS')

[h, f] = freqz(b, 1, L, Fs); 
plot(f, 20*log10(abs(h)));
title('Resposta em frequência NLMS')
xscale('log')
xlabel('Frequency (Hz)');
ylabel('Diferença de magnitude (dB)');
grid on
ylim([-30 30])
hold on
%%
addpath('/Users/danielcarvalho/Library/CloudStorage/OneDrive-Pessoal/UFRJ/18 periodo/TCC/Arquivos de Teste');
addpath('/Users/danielcarvalho/Library/CloudStorage/OneDrive-Pessoal/UFRJ/18 periodo/TCC/PEAQ_matlab-main/PQevalAudio');
y=audioread('Violao mic play.wav');
[x, Fs]=audioread('Violao linha play.wav');
y=y(1:240000);
x=x(1:240000);
%%

xhat=filter(b,1,x);

%%

[y_delay,~,delay_xhat]=alignsignals(y,xhat);
[x_delay,~, delay_x]=alignsignals(x,y_delay);
if delay_x < 0 || delay_xhat < 0
    disp('delay compensation error')
end
%%

yPow=mean(y_delay.^2);
xhatPow=mean(xhat.^2);
ydiff=yPow/xhatPow;
xhat=xhat*ydiff;

%%
audiowrite('x.wav',x_delay,Fs);
audiowrite('y.wav',y_delay,Fs);
audiowrite('xhatFPBS.wav',xhat,Fs);
%%

audiowrite('xhatNLMS.wav',xhat,Fs);
peaqNotaX=PQevalAudio('y.wav','x.wav');
peaqNotaxHat=PQevalAudio('y.wav','xhatNLMS.wav');%-3.112
toc%1.221609 seconds