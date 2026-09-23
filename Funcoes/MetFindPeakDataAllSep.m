%met find peak base separada
tic
dataInit

%%

noteMax=137;
res=1;%Divisões de uma nota
noteID=1:res:noteMax;
FreqNote=2.^((noteID-69)/12)*440;
FreqLower=2.^((noteID-69-(0.5*res))/12)*440;
FreqUpper=2.^((noteID-69+(0.5*res))/12)*440;
%{
% linear Grid
freqNote=0:1:24000;
res=0.5;%Divisões de uma Freq
FreqLower=freqNote-res;
FreqUpper=freqNote+res;
%}


%%
%Combina no grid

metodoCombina=str2func('mean');

%Criando base de dados no grid de frequencias

for k=1:length(FreqNote)
   
    binFreqAll=dataAll.Frequencia >= FreqLower(k) & dataAll.Frequencia <FreqUpper(k);

    dataAll.binFreq(binFreqAll)=k;

    dataAllgrid(k,1)=mag2db(metodoCombina(db2mag(dataAll.magnitudeDB(dataAll.binFreq==k))));


    %Contribuicoes
  
    dataAllgrid(k,4)=sum(binFreqAll);

end


figure('Name','Histogram')

stem(FreqNote,dataAllgrid(:,4))
title('Histogram')
xlabel('Frequência em Hz')
ylabel('Contagem de contribuições para o bin de frequência')
xlim([80 24000])
xscale('log')
%%
figure('Name','dataAll')
scatter(dataAll.Frequencia,dataAll.magnitudeDB)
title('Diferênças')
xlim([80 24000])
ylim([-30 30])
xscale('log')
xlabel('Frequência em Hz')
ylabel('Magitude da diferença em dB')


%%
%figure('Name','Grid e dataALL')
%{

scatter(freqNote,zeros(length(noteID)), 'Marker', 'x', 'MarkerEdgeColor', 'red');
hold on
scatter(FreqLower(1),0, 'Marker', '|', 'MarkerEdgeColor', 'black');
scatter(FreqUpper,zeros(length(noteID)), 'Marker', '|', 'MarkerEdgeColor', 'black');
%}

hold on
plot(FreqNote,(dataAllgrid(:,1)),Color='black',linewidth=1);
legend('Pontos de diferença','média nos bins de frequência')
hold off

%plot(FreqNote,unwrap(dataAllgrid(:,2)))

%xlim([80 24000])
%ylim([-30 30])
%xscale('log')

%%
%interpolando o grid
%{
metodo='linear';

%pchip
%makima
%nearest
%linear

x=1:length(FreqNote);
dataAllgrid(:,2)=dataAllgrid(:,1);
dataAllgrid(isnan(dataAllgrid(:,2)),2) = interp1(x(~isnan(dataAllgrid(:,2))),dataAllgrid(~isnan(dataAllgrid(:,2))),x(isnan(dataAllgrid(:,2)))) ;
    
figure('Name','Data All grid interpolado')
stem(FreqNote,(dataAllgrid(:,1)))
hold on
plot(FreqNote,(dataAllgrid(:,2)))
xlabel('Frequência em Hz')
ylabel('Magitude da diferença em dB')
xscale('log')
legend('média nos bins de frequência','data interpolada')
ylim([-20 20])

%%
%smooth data
mediaSize=4;
metodoMedia="movmean";

%movmean
%movmedian
%gaussian
%lowess
%loess
%rlowess
%rloess

dataAllgrid(:,3)=smoothdata(dataAllgrid(:,2),1,metodoMedia,mediaSize);

figure('Name','Data All smooth')
plot(FreqNote,dataAllgrid(:,2),FreqNote,dataAllgrid(:,3))
xlim([80 24000])
xscale('log')
xlabel('Frequência em Hz')
ylabel('Magitude da diferença em dB')
legend('data interpolada','Após média móvel')
%ylim([-20 20])
%}

%%
F=FreqNote*2/Fs;
A=dataAllgrid(:,1);
N=2^10;
F(end)=1;
F(1)=0;
A(1)=-99;
A(end)=-99;
A(isnan(A))=-99;

A=db2mag(A);
d = fdesign.arbmag("N,F,A",N,F,A);
Hd = design(d,"freqsamp",SystemObject=true);
Hd.Numerator=Hd.Numerator/max(abs(Hd.Numerator));

%%

figure('Name','Resposta do filtro')
%[H,w]=freqz(d,n);
freqz(Hd.Numerator,1,N,Fs)
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
audiowrite('xhatFPBSFast.wav',xhat,Fs);
%%
peaqNotaX=PQevalAudio('y.wav','x.wav');
peaqNotaxHat=PQevalAudio('y.wav','xhatFPBSFast.wav'); % na 1 vez -2.202,  -2.057 na segunda a partir da filtragem de xhat fast -3.088
toc%Elapsed time is 18.851814 seconds.