close all
clear
tic
%%
Fs=48000;

addpath('/Users/danielcarvalho/Library/CloudStorage/OneDrive-Pessoal/UFRJ/18 periodo/TCC/Base toda');
addpath('/Users/danielcarvalho/Library/CloudStorage/OneDrive-Pessoal/UFRJ/18 periodo/TCC/Funções/LoadData1');
data1=table();
plotOn=false;
delay=129;

for i=1:114


    name=strcat('loadData',num2str(i));
    fh=str2func(name);
    data1=fh(data1,plotOn,delay);
    toDelete = data1.Frequencia == 0;
    data1(toDelete,:) = [];

end
%%
addpath('/Users/danielcarvalho/Library/CloudStorage/OneDrive-Pessoal/UFRJ/18 periodo/TCC/Funções/LoadData2');

data2=table();
plotOn=false;

for i=1:108


    name=strcat('loadData2_',num2str(i));
    fh=str2func(name);
    data2=fh(data2,plotOn,delay);
    toDelete = data2.Frequencia == 0;
    data2(toDelete,:) = [];

end
%%
addpath('/Users/danielcarvalho/Library/CloudStorage/OneDrive-Pessoal/UFRJ/18 periodo/TCC/Funções/LoadData3');

data3=table();
plotOn=false;

for i=1:108

    name=strcat('loadData3_',num2str(i));
    fh=str2func(name);
    data3=fh(data3,plotOn,delay);
    toDelete = data3.Frequencia == 0;
    data3(toDelete,:) = [];

end

%%
addpath('/Users/danielcarvalho/Library/CloudStorage/OneDrive-Pessoal/UFRJ/18 periodo/TCC/Funções/LoadAcordes');

data4=table();

for i=1:56

    name=strcat('loadAcordes',num2str(i));
    fh=str2func(name);
    data4=fh(data4,delay);
    toDelete = data4.Frequencia == 0;
    data4(toDelete,:) = [];
end
%%
data1.('Base')=ones(size(data1,1),1);
data2.('Base')=ones(size(data2,1),1).*2;
data3.('Base')=ones(size(data3,1),1).*3;
data4.('Base')=ones(size(data4,1),1).*4;

%%
[~, indsort]=sort(data1.Frequencia);
data1=data1(indsort,:);
[~, indsort]=sort(data2.Frequencia);
data2=data2(indsort,:);
[~, indsort]=sort(data3.Frequencia);
data3=data3(indsort,:);
[~, indsort]=sort(data4.Frequencia);
data4=data4(indsort,:);
%%
%Apaga outliers
data1(1,:)=[];
data4(1:2,:)=[];
data1(end-1,:)=[];
data1(end-3,:)=[];

%%

noteMax=137;
res=1;%Divisões de uma nota
noteID=1:res:noteMax;
freqNote=2.^((noteID-69)/12)*440;
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

data1E1=table();
data2E1=table();
data3E1=table();
dataTransp=table();
for k=1:19
    if k<10
        name=strcat('0',num2str(k),'E1');
    else
        name=strcat(num2str(k),'E1');
    end
    indCell1=cellfun(@isempty,strfind(data1.CasaCorda,name));
    indCell2=cellfun(@isempty,strfind(data2.CasaCorda,name));
    indCell3=cellfun(@isempty,strfind(data3.CasaCorda,name));
    dataTransp=data1(not(indCell1),:);
    data1E1=[data1E1;dataTransp];
    dataTransp=data2(not(indCell2),:);
    data2E1=[data2E1;dataTransp];
    dataTransp=data3(not(indCell3),:);
    data3E1=[data3E1;dataTransp];
end

%%
data1A=table();
data2A=table();
data3A=table();


for k=1:19
    if k<10
        name=strcat('0',num2str(k),'A');
    else
        name=strcat(num2str(k),'A');
    end
    indCell1=cellfun(@isempty,strfind(data1.CasaCorda,name));
    indCell2=cellfun(@isempty,strfind(data2.CasaCorda,name));
    indCell3=cellfun(@isempty,strfind(data3.CasaCorda,name));

    dataTransp=data1(not(indCell1),:);
    data1A=[data1A;dataTransp];
    dataTransp=data2(not(indCell2),:);
    data2A=[data2A;dataTransp];
    dataTransp=data3(not(indCell3),:);
    data3A=[data3A;dataTransp];
end

%%
data1D=table();
data2D=table();
data3D=table();

for k=1:19
    if k<10
        name=strcat('0',num2str(k),'D');
    else
        name=strcat(num2str(k),'D');
    end
    indCell1=cellfun(@isempty,strfind(data1.CasaCorda,name));
    indCell2=cellfun(@isempty,strfind(data2.CasaCorda,name));
    indCell3=cellfun(@isempty,strfind(data3.CasaCorda,name));
    dataTransp=data1(not(indCell1),:);
    data1D=[data1D;dataTransp];
    dataTransp=data2(not(indCell2),:);
    data2D=[data2D;dataTransp];
    dataTransp=data3(not(indCell3),:);
    data3D=[data3D;dataTransp];
end

%%
data1G=table();
data2G=table();
data3G=table();

for k=1:19
    if k<10
        name=strcat('0',num2str(k),'G');
    else
        name=strcat(num2str(k),'G');
    end
    indCell1=cellfun(@isempty,strfind(data1.CasaCorda,name));
    indCell2=cellfun(@isempty,strfind(data2.CasaCorda,name));
    indCell3=cellfun(@isempty,strfind(data3.CasaCorda,name));

    dataTransp=data1(not(indCell1),:);
    data1G=[data1G;dataTransp];
    dataTransp=data2(not(indCell2),:);
    data2G=[data2G;dataTransp];
    dataTransp=data3(not(indCell3),:);
    data3G=[data3G;dataTransp];
end
%%
data1B=table();
data2B=table();
data3B=table();


for k=1:19
    if k<10
        name=strcat('0',num2str(k),'B');
    else
        name=strcat(num2str(k),'B');
    end
    indCell1=cellfun(@isempty,strfind(data1.CasaCorda,name));
    indCell2=cellfun(@isempty,strfind(data2.CasaCorda,name));
    indCell3=cellfun(@isempty,strfind(data3.CasaCorda,name));

    dataTransp=data1(not(indCell1),:);
    data1B=[data1B;dataTransp];
    dataTransp=data2(not(indCell2),:);
    data2B=[data2B;dataTransp];
    dataTransp=data3(not(indCell3),:);
    data3B=[data3B;dataTransp];
end
%%
data1E2=table();
data2E2=table();
data3E2=table();


for k=1:19
    if k<10
        name=strcat('0',num2str(k),'E2');
    else
        name=strcat(num2str(k),'E2');
    end
    indCell1=cellfun(@isempty,strfind(data1.CasaCorda,name));
    indCell2=cellfun(@isempty,strfind(data2.CasaCorda,name));
    indCell3=cellfun(@isempty,strfind(data3.CasaCorda,name));

    
    
    dataTransp=data1(not(indCell1),:);
    data1E2=[data1E2;dataTransp];
    dataTransp=data2(not(indCell2),:);
    data2E2=[data2E2;dataTransp];
    dataTransp=data3(not(indCell3),:);
    data3E2=[data3E2;dataTransp];
end
%%

data1E1.('binFreq')=zeros(height(data1E1),1);
data2E1.('binFreq')=zeros(height(data2E1),1);
data3E1.('binFreq')=zeros(height(data3E1),1);

data1A.('binFreq')=zeros(height(data1A),1);
data2A.('binFreq')=zeros(height(data2A),1);
data3A.('binFreq')=zeros(height(data3A),1);

data1D.('binFreq')=zeros(height(data1D),1);
data2D.('binFreq')=zeros(height(data2D),1);
data3D.('binFreq')=zeros(height(data3D),1);

data1G.('binFreq')=zeros(height(data1G),1);
data2G.('binFreq')=zeros(height(data2G),1);
data3G.('binFreq')=zeros(height(data3G),1);

data1B.('binFreq')=zeros(height(data1B),1);
data2B.('binFreq')=zeros(height(data2B),1);
data3B.('binFreq')=zeros(height(data3B),1);

data1E2.('binFreq')=zeros(height(data1E2),1);
data2E2.('binFreq')=zeros(height(data2E2),1);
data3E2.('binFreq')=zeros(height(data3E2),1);

data4.('binFreq')=zeros(height(data4),1);



%%
for k=1:length(freqNote)
    binFreq1E1=data1E1.Frequencia >= FreqLower(k) & data1E1.Frequencia <FreqUpper(k);
    binFreq2E1=data2E1.Frequencia >= FreqLower(k) & data2E1.Frequencia <FreqUpper(k);
    binFreq3E1=data3E1.Frequencia >= FreqLower(k) & data3E1.Frequencia <FreqUpper(k);

    binFreq1A=data1A.Frequencia >= FreqLower(k) & data1A.Frequencia <FreqUpper(k);
    binFreq2A=data2A.Frequencia >= FreqLower(k) & data2A.Frequencia <FreqUpper(k);
    binFreq3A=data3A.Frequencia >= FreqLower(k) & data3A.Frequencia <FreqUpper(k);
    
    binFreq1D=data1D.Frequencia >= FreqLower(k) & data1D.Frequencia <FreqUpper(k);
    binFreq2D=data2D.Frequencia >= FreqLower(k) & data2D.Frequencia <FreqUpper(k);
    binFreq3D=data3D.Frequencia >= FreqLower(k) & data3D.Frequencia <FreqUpper(k);

    binFreq1G=data1G.Frequencia >= FreqLower(k) & data1G.Frequencia <FreqUpper(k);
    binFreq2G=data2G.Frequencia >= FreqLower(k) & data2G.Frequencia <FreqUpper(k);
    binFreq3G=data3G.Frequencia >= FreqLower(k) & data3G.Frequencia <FreqUpper(k);
    
    binFreq1B=data1B.Frequencia >= FreqLower(k) & data1B.Frequencia <FreqUpper(k);
    binFreq2B=data2B.Frequencia >= FreqLower(k) & data2B.Frequencia <FreqUpper(k);
    binFreq3B=data3B.Frequencia >= FreqLower(k) & data3B.Frequencia <FreqUpper(k);
    
    binFreq1E2=data1E2.Frequencia >= FreqLower(k) & data1E2.Frequencia <FreqUpper(k);
    binFreq2E2=data2E2.Frequencia >= FreqLower(k) & data2E2.Frequencia <FreqUpper(k);
    binFreq3E2=data3E2.Frequencia >= FreqLower(k) & data3E2.Frequencia <FreqUpper(k);

    binFreq4=data4.Frequencia >= FreqLower(k) & data4.Frequencia <FreqUpper(k);


    data1E1.binFreq(binFreq1E1)=k;
    data2E1.binFreq(binFreq2E1)=k;
    data3E1.binFreq(binFreq3E1)=k;

    data1A.binFreq(binFreq1A)=k;
    data2A.binFreq(binFreq2A)=k;
    data3A.binFreq(binFreq3A)=k;

    data1D.binFreq(binFreq1D)=k;
    data2D.binFreq(binFreq2D)=k;
    data3D.binFreq(binFreq3D)=k;

    data1G.binFreq(binFreq1G)=k;
    data2G.binFreq(binFreq2G)=k;
    data3G.binFreq(binFreq3G)=k;

    data1B.binFreq(binFreq1B)=k;
    data2B.binFreq(binFreq2B)=k;
    data3B.binFreq(binFreq3B)=k;

    data1E2.binFreq(binFreq1E2)=k;
    data2E2.binFreq(binFreq2E2)=k;
    data3E2.binFreq(binFreq3E2)=k;

    data4.binFreq(binFreq4)=k;

    metodo=str2func('median');

    %mean? weigth?
    data1E1grid(k,1)=mag2db(metodo(db2mag(data1E1.magnitudeDB(data1E1.binFreq==k))));
    data2E1grid(k,1)=mag2db(metodo(db2mag(data2E1.magnitudeDB(data2E1.binFreq==k))));
    data3E1grid(k,1)=mag2db(metodo(db2mag(data3E1.magnitudeDB(data3E1.binFreq==k))));

    data1Agrid(k,1)=mag2db(metodo(db2mag(data1A.magnitudeDB(data1A.binFreq==k))));
    data2Agrid(k,1)=mag2db(metodo(db2mag(data2A.magnitudeDB(data2A.binFreq==k))));
    data3Agrid(k,1)=mag2db(metodo(db2mag(data3A.magnitudeDB(data3A.binFreq==k))));

    data1Dgrid(k,1)=mag2db(metodo(db2mag(data1D.magnitudeDB(data1D.binFreq==k))));
    data2Dgrid(k,1)=mag2db(metodo(db2mag(data2D.magnitudeDB(data2D.binFreq==k))));
    data3Dgrid(k,1)=mag2db(metodo(db2mag(data3D.magnitudeDB(data3D.binFreq==k))));

    data1Ggrid(k,1)=mag2db(metodo(db2mag(data1G.magnitudeDB(data1G.binFreq==k))));
    data2Ggrid(k,1)=mag2db(metodo(db2mag(data2G.magnitudeDB(data2G.binFreq==k))));
    data3Ggrid(k,1)=mag2db(metodo(db2mag(data3G.magnitudeDB(data3G.binFreq==k))));

    data1Bgrid(k,1)=mag2db(metodo(db2mag(data1B.magnitudeDB(data1B.binFreq==k))));
    data2Bgrid(k,1)=mag2db(metodo(db2mag(data2B.magnitudeDB(data2B.binFreq==k))));
    data3Bgrid(k,1)=mag2db(metodo(db2mag(data3B.magnitudeDB(data3B.binFreq==k))));

    data1E2grid(k,1)=mag2db(metodo(db2mag(data1E2.magnitudeDB(data1E2.binFreq==k))));
    data2E2grid(k,1)=mag2db(metodo(db2mag(data2E2.magnitudeDB(data2E2.binFreq==k))));
    data3E2grid(k,1)=mag2db(metodo(db2mag(data3E2.magnitudeDB(data3E2.binFreq==k))));

    data4grid(k,1)=mag2db(metodo(db2mag(data4.magnitudeDB(data4.binFreq==k))));


    %Contribuicoes
    data1E1grid(k,3)=sum(binFreq1E1);
    data2E1grid(k,3)=sum(binFreq2E1);
    data3E1grid(k,3)=sum(binFreq3E1);

    data1Agrid(k,3)=sum(binFreq1A);
    data2Agrid(k,3)=sum(binFreq2A);
    data3Agrid(k,3)=sum(binFreq3A);

    data1Dgrid(k,3)=sum(binFreq1D);
    data2Dgrid(k,3)=sum(binFreq2D);
    data3Dgrid(k,3)=sum(binFreq3D);

    data1Ggrid(k,3)=sum(binFreq1G);
    data2Ggrid(k,3)=sum(binFreq2G);
    data3Ggrid(k,3)=sum(binFreq3G);

    data1Bgrid(k,3)=sum(binFreq1B);
    data2Bgrid(k,3)=sum(binFreq2B);
    data3Bgrid(k,3)=sum(binFreq3B);

    data1E2grid(k,3)=sum(binFreq1E2);
    data2E2grid(k,3)=sum(binFreq2E2);
    data3E2grid(k,3)=sum(binFreq3E2);

    data4grid(k,3)=sum(binFreq4);

end
%%

x=1:length(freqNote);

data1E1grid(isnan(data1E1grid(:,1))) = interp1(x(~isnan(data1E1grid(:,1))),data1E1grid(~isnan(data1E1grid(:,1))),x(isnan(data1E1grid(:,1)))) ;
data2E1grid(isnan(data2E1grid(:,1))) = interp1(x(~isnan(data2E1grid(:,1))),data2E1grid(~isnan(data2E1grid(:,1))),x(isnan(data2E1grid(:,1)))) ;
data3E1grid(isnan(data3E1grid(:,1))) = interp1(x(~isnan(data3E1grid(:,1))),data3E1grid(~isnan(data3E1grid(:,1))),x(isnan(data3E1grid(:,1))));
data1Agrid(isnan(data1Agrid(:,1))) = interp1(x(~isnan(data1Agrid(:,1))),data1Agrid(~isnan(data1Agrid(:,1))),x(isnan(data1Agrid(:,1)))) ;
data2Agrid(isnan(data2Agrid(:,1))) = interp1(x(~isnan(data2Agrid(:,1))),data2Agrid(~isnan(data2Agrid(:,1))),x(isnan(data2Agrid(:,1)))) ;
data3Agrid(isnan(data3Agrid(:,1))) = interp1(x(~isnan(data3Agrid(:,1))),data3Agrid(~isnan(data3Agrid(:,1))),x(isnan(data3Agrid(:,1)))) ;

data1Dgrid(isnan(data1Dgrid(:,1))) = interp1(x(~isnan(data1Dgrid(:,1))),data1Dgrid(~isnan(data1Dgrid(:,1))),x(isnan(data1Dgrid(:,1)))) ;
data2Dgrid(isnan(data2Dgrid(:,1))) = interp1(x(~isnan(data2Dgrid(:,1))),data2Dgrid(~isnan(data2Dgrid(:,1))),x(isnan(data2Dgrid(:,1)))) ;
data3Dgrid(isnan(data3Dgrid(:,1))) = interp1(x(~isnan(data3Dgrid(:,1))),data3Dgrid(~isnan(data3Dgrid(:,1))),x(isnan(data3Dgrid(:,1)))) ;

data1Ggrid(isnan(data1Ggrid(:,1))) = interp1(x(~isnan(data1Ggrid(:,1))),data1Ggrid(~isnan(data1Ggrid(:,1))),x(isnan(data1Ggrid(:,1)))) ;
data2Ggrid(isnan(data2Ggrid(:,1))) = interp1(x(~isnan(data2Ggrid(:,1))),data2Ggrid(~isnan(data2Ggrid(:,1))),x(isnan(data2Ggrid(:,1)))) ;
data3Ggrid(isnan(data3Ggrid(:,1))) = interp1(x(~isnan(data3Ggrid(:,1))),data3Ggrid(~isnan(data3Ggrid(:,1))),x(isnan(data3Ggrid(:,1)))) ;

data1Bgrid(isnan(data1Bgrid(:,1))) = interp1(x(~isnan(data1Bgrid(:,1))),data1Bgrid(~isnan(data1Bgrid(:,1))),x(isnan(data1Bgrid(:,1)))) ;
data2Bgrid(isnan(data2Bgrid(:,1))) = interp1(x(~isnan(data2Bgrid(:,1))),data2Bgrid(~isnan(data2Bgrid(:,1))),x(isnan(data2Bgrid(:,1)))) ;
data3Bgrid(isnan(data3Bgrid(:,1))) = interp1(x(~isnan(data3Bgrid(:,1))),data3Bgrid(~isnan(data3Bgrid(:,1))),x(isnan(data3Bgrid(:,1)))) ;

data1E2grid(isnan(data1E2grid(:,1))) = interp1(x(~isnan(data1E2grid(:,1))),data1E2grid(~isnan(data1E2grid(:,1))),x(isnan(data1E2grid(:,1)))) ;
data2E2grid(isnan(data2E2grid(:,1))) = interp1(x(~isnan(data2E2grid(:,1))),data2E2grid(~isnan(data2E2grid(:,1))),x(isnan(data2E2grid(:,1)))) ;
data3E2grid(isnan(data3E2grid(:,1))) = interp1(x(~isnan(data3E2grid(:,1))),data3E2grid(~isnan(data3E2grid(:,1))),x(isnan(data3E2grid(:,1)))) ;

data4grid(isnan(data4grid(:,1))) = interp1(x(~isnan(data4grid(:,1))),data4grid(~isnan(data4grid(:,1))),x(isnan(data4grid(:,1)))) ;

%%

mediaSize=1;
dataSmooth1E1=smoothdata(data1E1grid(:,1),1,"movmean",mediaSize);
dataSmooth2E1=smoothdata(data2E1grid(:,1),1,"movmean",mediaSize);
dataSmooth3E1=smoothdata(data3E1grid(:,1),1,"movmean",mediaSize);

dataSmooth1A=smoothdata(data1Agrid(:,1),1,"movmean",mediaSize);
dataSmooth2A=smoothdata(data2Agrid(:,1),1,"movmean",mediaSize);
dataSmooth3A=smoothdata(data3Agrid(:,1),1,"movmean",mediaSize);

dataSmooth1D=smoothdata(data1Dgrid(:,1),1,"movmean",mediaSize);
dataSmooth2D=smoothdata(data2Dgrid(:,1),1,"movmean",mediaSize);
dataSmooth3D=smoothdata(data3Dgrid(:,1),1,"movmean",mediaSize);

dataSmooth1G=smoothdata(data1Ggrid(:,1),1,"movmean",mediaSize);
dataSmooth2G=smoothdata(data2Ggrid(:,1),1,"movmean",mediaSize);
dataSmooth3G=smoothdata(data3Ggrid(:,1),1,"movmean",mediaSize);

dataSmooth1B=smoothdata(data1Bgrid(:,1),1,"movmean",mediaSize);
dataSmooth2B=smoothdata(data2Bgrid(:,1),1,"movmean",mediaSize);
dataSmooth3B=smoothdata(data3Bgrid(:,1),1,"movmean",mediaSize);

dataSmooth1E2=smoothdata(data1E2grid(:,1),1,"movmean",mediaSize);
dataSmooth2E2=smoothdata(data2E2grid(:,1),1,"movmean",mediaSize);
dataSmooth3E2=smoothdata(data3E2grid(:,1),1,"movmean",mediaSize);

dataSmooth4=smoothdata(data4grid(:,1),1,"movmean",mediaSize);


%%
dataSmoothE1(:,1)=dataSmooth1E1;
dataSmoothE1(:,2)=dataSmooth2E1;
dataSmoothE1(:,3)=dataSmooth3E1;

dataSmoothA(:,1)=dataSmooth1A;
dataSmoothA(:,2)=dataSmooth2A;
dataSmoothA(:,3)=dataSmooth3A;

dataSmoothD(:,1)=dataSmooth1D;
dataSmoothD(:,2)=dataSmooth2D;
dataSmoothD(:,3)=dataSmooth3D;

dataSmoothG(:,1)=dataSmooth1G;
dataSmoothG(:,2)=dataSmooth2G;
dataSmoothG(:,3)=dataSmooth3G;

dataSmoothB(:,1)=dataSmooth1B;
dataSmoothB(:,2)=dataSmooth2B;
dataSmoothB(:,3)=dataSmooth3B;

dataSmoothE2(:,1)=dataSmooth1E2;
dataSmoothE2(:,2)=dataSmooth2E2;
dataSmoothE2(:,3)=dataSmooth3E2;


%% ?
%Median melhor que mean??
dataFinalE1=mag2db(mean(db2mag(dataSmoothE1),2,'omitmissing'));
dataFinalA=mag2db(mean(db2mag(dataSmoothA),2,'omitmissing'));
dataFinalD=mag2db(mean(db2mag(dataSmoothD),2,'omitmissing'));
dataFinalG=mag2db(mean(db2mag(dataSmoothG),2,'omitmissing'));
dataFinalB=mag2db(mean(db2mag(dataSmoothB),2,'omitmissing'));
dataFinalE2=mag2db(mean(db2mag(dataSmoothE2),2,'omitmissing'));

%%
figure('Name','Curvas E1')
plot(freqNote,dataSmooth1E1,'-')
grid on
title('Corda E1')
hold on
plot(freqNote,dataSmooth2E1,'-')
plot(freqNote,dataSmooth3E1,'-')
%plot(freqNote,dataFinalE1,'-','Color','black')
xlabel('Frequência em Hz')
ylabel('Magitude da diferença em dB')
xscale('log')
legend('Fraca','Forte','Palheta')
ylim([-20 20])
xlim([50 24000])
xscale('log')

figure('Name','Curvas A')
plot(freqNote,dataSmooth1A,'-')
grid on
title('Corda A')
hold on
plot(freqNote,dataSmooth2A,'-')
plot(freqNote,dataSmooth3A,'-')
%plot(freqNote,dataFinalA,'-','Color','black')
xlabel('Frequência em Hz')
ylabel('Magitude da diferença em dB')
legend('Fraca','Forte','Palheta')
ylim([-20 20])
xlim([50 24000])

xscale('log')

figure('Name','Curvas D')

plot(freqNote,dataSmooth1D,'-')
grid on
title('Corda D')
hold on
plot(freqNote,dataSmooth2D,'-')
plot(freqNote,dataSmooth3D,'-')
%plot(freqNote,dataFinalD,'-','Color','black')
xlabel('Frequência em Hz')
ylabel('Magitude da diferença em dB')

legend('Fraca','Forte','Palheta')
ylim([-20 20])
xlim([50 24000])
xscale('log')
figure('Name','Curvas G')

plot(freqNote,dataSmooth1G,'-')
grid on
title('Corda G')
hold on
plot(freqNote,dataSmooth2G,'-')
plot(freqNote,dataSmooth3G,'-')
%plot(freqNote,dataFinalG,'-','Color','black')
xlabel('Frequência em Hz')
ylabel('Magitude da diferença em dB')
legend('Fraca','Forte','Palheta')
ylim([-20 20])
xlim([50 24000])
xscale('log')
figure('Name','Curvas B')

plot(freqNote,dataSmooth1B,'-')
grid on
title('Corda B')
hold on
plot(freqNote,dataSmooth2B,'-')
plot(freqNote,dataSmooth3B,'-')
%plot(freqNote,dataFinalB,'-','Color','black')
xlabel('Frequência em Hz')
ylabel('Magitude da diferença em dB')
legend('Fraca','Forte','Palheta')
ylim([-20 20])
xlim([50 24000])
xscale('log')
figure('Name','Curvas E2')

plot(freqNote,dataSmooth1E2,'-')
title('Corda E2')
grid on
hold on
plot(freqNote,dataSmooth2E2,'-')
plot(freqNote,dataSmooth3E2,'-')
%plot(freqNote,dataFinalE2,'-','Color','black')
xlabel('Frequência em Hz')
ylabel('Magitude da diferença em dB')
legend('Fraca','Forte','Palheta')
ylim([-20 20])
xlim([50 24000])
xscale('log')
%%
figure('Name','Curva acordes')
plot(freqNote,dataSmooth4,'-')
grid on
title('Base de dados de acordes')
xlabel('Frequência em Hz')
ylabel('Magitude da diferença em dB')
ylim([-20 20])
xlim([50 24000])
xscale('log')

hold off

%%

dataFinal(:,1)=dataFinalE1;
dataFinal(:,2)=dataFinalA;
dataFinal(:,3)=dataFinalD;
dataFinal(:,4)=dataFinalG;
dataFinal(:,5)=dataFinalB;
dataFinal(:,6)=dataFinalE2;


figure('Name','Curvas médias por corda')
plot(freqNote,dataFinal(:,1))
grid on
title('Curvas médias por corda')

hold on,
plot(freqNote,dataFinal(:,2))
plot(freqNote,dataFinal(:,3))
plot(freqNote,dataFinal(:,4))
plot(freqNote,dataFinal(:,5))
plot(freqNote,dataFinal(:,6))
xlabel('Frequência em Hz')
ylabel('Magitude da diferença em dB')
legend('E1','A','D','G','B','E2')
ylim([-20 20])
xlim([50 24000])

xscale('log')


%curvaMedia=mag2db(mean(db2mag(dataFinal),2,"omitmissing"));
%figure('Name','Curva Final')
%plot(freqNote,curvaMedia)
%ylim([-20 20])
%xlim([50 24000])
%xscale('log')
%%
norm=mean(dataFinal,1,"omitmissing");
normAcordes=mean(dataSmooth4,1,"omitmissing");
%%

dataFinalNorm(:,1)=dataFinalE1-norm(1);
dataFinalNorm(:,2)=dataFinalA-norm(2);
dataFinalNorm(:,3)=dataFinalD-norm(3);
dataFinalNorm(:,4)=dataFinalG-norm(4);
dataFinalNorm(:,5)=dataFinalB-norm(5);
dataFinalNorm(:,6)=dataFinalE2-norm(6);
dataFinalNorm(:,7)=dataSmooth4-normAcordes;


figure('Name','Curvas médias por corda comensando volumes')
plot(freqNote,dataFinalNorm(:,1))
grid on
title('Curvas médias equilibradas')

hold on,
plot(freqNote,dataFinalNorm(:,2))
plot(freqNote,dataFinalNorm(:,3))
plot(freqNote,dataFinalNorm(:,4))
plot(freqNote,dataFinalNorm(:,5))
plot(freqNote,dataFinalNorm(:,6))
plot(freqNote,dataFinalNorm(:,7))

xlabel('Frequência em Hz')
ylabel('Magitude da diferença em dB')
legend('E1','A','D','G','B','E2','Acordes')
ylim([-20 20])
xlim([50 24000])
xscale('log')
%%
%Median melhor que mean aqui tambem
curvaFinal=mag2db(median(db2mag(dataFinalNorm),2,"omitmissing"));
%curvaFinal=dataFinalNorm(:,4);
figure('Name','Curva final')
plot(freqNote,curvaFinal)
grid on
title('Curva final')
xlabel('Frequência em Hz')
ylabel('Magitude da diferença em dB')
ylim([-20 20])
xlim([50 24000])
xscale('log')


%%
F=freqNote*2/Fs;
A=curvaFinal;
N=2^16;
F(end)=1;
F(1)=0;
A(1)=-99;
A(end)=-99;
A(isnan(A))=-99;
%bfir2=fir2(n,f,db2mag(a));
%bfir2=bfir2/max(abs(bfir2));
A=db2mag(A);
d = fdesign.arbmag("N,F,A",N,F,A);
Hd = design(d,"freqsamp",SystemObject=true);
%Hd.Numerator=Hd.Numerator/max(abs(Hd.Numerator));

%%

figure('Name','Resposta do filtro fir2')
freqz(Hd,N,Fs);
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
audiowrite('xhatMediaCordas.wav',xhat,Fs);
%%
peaqNotaX=PQevalAudio('y.wav','x.wav');
peaqNotaxHat=PQevalAudio('y.wav','xhatMediaCordas.wav');%-2.209 fast -3.001
toc
%Elapsed time is 21.044155 seconds.