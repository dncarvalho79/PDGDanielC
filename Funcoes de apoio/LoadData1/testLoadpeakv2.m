%load
clear

data=table()

for i=1:114


    name=strcat('loadData',num2str(i));
    fh=str2func(name)
    data=fh(data);
    toDelete = data.Vazio == true;
    data(toDelete,:) = [];

end
clear toDelete
%%
% Plot
%{
dataPlot=data(data.MicZero==false & data.LinhaZero==false,:);
indices=cellfun(@isempty, (strfind(dataPlot.CasaCorda,'E1')));
figure('Name','Harmonicos presentes nos dois corda E1')
stem(dataPlot.Frequencia(indices,:),dataPlot.magnitudeDB(indices,:))       
ylim([-30 30])
xlim([80 24000])
hold on
%}
[~,indPlot]=sort(data.Frequencia);
plot(data.Frequencia(indPlot),unwrap(data.Angulo(indPlot)))
%%

 toDelete = data.MicZero == true | data.LinhaZero== true;
 data(toDelete,:) = [];

%%


noteMax=137;
res=0.25;%Divisões de uma nota
noteID=1:res:noteMax;
freqNote=2.^((noteID-69)/12)*440;
FreqLower=2.^((noteID-69-(0.5*res))/12)*440;
FreqUpper=2.^((noteID-69+(0.5*res))/12)*440;
%{
scatter(freqNote,zeros(length(noteID)), 'Marker', 'x', 'MarkerEdgeColor', 'red');
scatter(FreqLower,zeros(length(noteID)), 'Marker', '|', 'MarkerEdgeColor', 'black');
scatter(FreqLower(1),0, 'Marker', '|', 'MarkerEdgeColor', 'red');
scatter(FreqUpper,zeros(length(noteID)), 'Marker', '|', 'MarkerEdgeColor', 'black');
xlim([80 24000])
ylim([-30 30])
xscale('log')
hold off
%}

%%
dataSum=zeros(length(freqNote),1 );
data.('binFreq')=zeros(height(data),1);
for k=1:length(freqNote)
    binFreq=data.Frequencia >= FreqLower(k) & data.Frequencia <FreqUpper(k);
    data.binFreq(binFreq)=k;
    %mean? weigth?
    dataSum(k)=mag2db(median(db2mag(data.magnitudeDB(data.binFreq==k))));
end
%%
dataPlot=table();
dataPlot.('Mag')=dataSum;
dataPlot.('Freq')=freqNote';
%dataPlot.Mag(isnan(dataPlot.Mag)) = 0;
%dataPlot.Mag(dataPlot.Freq>15000)=0;
%%
x = 1:length(dataPlot.Mag) ;
dataPlot.Mag(isnan(dataPlot.Mag)) = interp1(x(~isnan(dataPlot.Mag)),dataPlot.Mag(~isnan(dataPlot.Mag)),x(isnan(dataPlot.Mag))) ;
plot(freqNote,dataPlot.Mag,'.r') 
hold on
plot(freqNote,dataPlot.Mag,'b')
%%
dataSmooth=smoothdata(dataPlot.Mag,1,"movmean",8);
plot(freqNote,dataSmooth,'-')
xscale('log')
%%
%ids=(dataPlot.Freq>80&dataPlot.Freq<15000);
f=dataPlot.Freq/24000;
a=dataSmooth;
n=2^16;
f(end)=1;
f(1)=0;
a(1)=0;
a(end)=0;
a(isnan(a))=0;
bfir2=fir2(n,f,db2mag(a));
bfir2=bfir2/max(bfir2);
%bfir2=bfir2*4;
%%

figure('Name','Resposta do filtro fir2')
[H,w]=freqz(bfir2,1,n);

stem(f*24000,a);
xlim([80 24000])
ylim([-20 20])
xscale('log')

hold on
semilogx(w/pi*24000,20*log10(abs(H)));
xlim([80 24000])
ylim([-20 20])

%%

addpath('/Users/danielcarvalho/Library/CloudStorage/OneDrive-Pessoal/UFRJ/18 periodo/TCC/Arquivos de Teste');
addpath('/Users/danielcarvalho/Library/CloudStorage/OneDrive-Pessoal/UFRJ/18 periodo/TCC/PEAQ_matlab-main/PQevalAudio');
y=audioread('Violao mic play.wav');
[x, Fs]=audioread('Violao linha play.wav');
y=y(1:240000);
x=x(1:240000);
xhat=filter(bfir2,1,x);


%%

[y_delay,~,delay_xhat]=alignsignals(y,xhat);
[x_delay,~, delay_x]=alignsignals(x,y_delay);
if delay_x < 0 || delay_xhat < 0
    disp('delay compensation error')
end
%%

energiay=sum(y.^2);
energiaXhat=sum(xhat.^2);
ganho=energiay/energiaXhat;
xhat=xhat.*ganho;
energiaXhat2=sum(xhat.^2);
ganho2=energiay/energiaXhat2;

%%
audiowrite('x.wav',x_delay,Fs);
audiowrite('y.wav',y_delay,Fs);
audiowrite('xhat.wav',xhat,Fs);


%%
%{
peaqNotaX=PQevalAudio('y.wav','x.wav');
peaqNotaxHat=PQevalAudio('y.wav','xhat.wav');
%}
figure('Name','Resposta de fase filtro fir2')

[H,w]=phasez(bfir2,1,512,48000);
semilogx(w,unwrap(H));
xlim([80 24000])