clear
clc
[yMic,Fs]=audioread("~/Library/CloudStorage/OneDrive-Pessoal/UFRJ/18 periodo/TCC/Base toda/tudoMic_01.wav");
[yLine]=audioread("~/Library/CloudStorage/OneDrive-Pessoal/UFRJ/18 periodo/TCC/Base toda/tudoLine_01.wav");
n=length(yLine);
[yLineAlign,yMicAlign, delayRec]=alignsignals(yLine,yMic,"Truncate",1);

%%
seg=1;

yLineCut=yLineAlign(1:48000*seg);
yMicCut=yMicAlign(1:48000*seg);
yLineCut = yLineCut / (max(abs(yLineCut)) + eps);
yMicCut  = yMicCut  / (max(abs(yMicCut)) + eps);


%%
L=1024;
lag=L/2;
%%
yLineCut=[zeros(lag,1);yLineCut];
yMicCut=[yMicCut;zeros(lag,1)];

%yLineCut=[yLineCut;zeros(lag,1)];
%yMicCut=[zeros(lag,1);yMicCut];


%%




nlms = dsp.LMSFilter(L, 'Method', 'Normalized LMS');
[mumaxnlms, mumaxmsenlms] = maxstep(nlms, yLineCut);

nlms.StepSize = mumaxmsenlms / 20;


%%
[yNLMS,err,coeff] = nlms(yLineCut, yMicCut);

%%
figure('Name','Erro NLMS')
semilogy(err.^2)
[minErr,iMinErr]=min(err.^2);
%%
b=coeff;
%b=b./sqrt(sum(b.^2));
figure('Name','Resp Freq NLMS')

[h, f] = freqz(b, 1, L, Fs); 
semilogx(f, 20*log10(abs(h)));
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
grid on
ylim([-40 15])

%%

[xTest,Fs]=audioread('x.wav');
yTest=audioread('y.wav');
xTest=xTest(1:240000);
yTest=yTest(1:240000);

%%
xhat=filter(b,1,xTest);
audiowrite('xhatNLMS.wav',xhat,Fs);
peaqNotaX=PQevalAudio('y.wav','x.wav');
peaqNotaxHat=PQevalAudio('y.wav','xhatNLMS.wav');