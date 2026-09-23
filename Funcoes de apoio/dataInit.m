close all
clear
%tentando interpolar antes do grp delay
%%
%130?
recdelay=0;
Fs=48000;
addpath('/Users/danielcarvalho/Library/CloudStorage/OneDrive-Pessoal/UFRJ/18 periodo/TCC/Base toda');
addpath('/Users/danielcarvalho/Library/CloudStorage/OneDrive-Pessoal/UFRJ/18 periodo/TCC/Funções/LoadData1');
data1=table();
plotOn=false;

for i=1:114


    name=strcat('loadData',num2str(i));
    fh=str2func(name);
    data1=fh(data1,plotOn,recdelay);
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
    data2=fh(data2,plotOn,recdelay);
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
    data3=fh(data3,plotOn,recdelay);
    toDelete = data3.Frequencia == 0;
    data3(toDelete,:) = [];

end

%%
addpath('/Users/danielcarvalho/Library/CloudStorage/OneDrive-Pessoal/UFRJ/18 periodo/TCC/Funções/LoadAcordes');

data4=table();

for i=1:56

    name=strcat('loadAcordes',num2str(i));
    fh=str2func(name);
    data4=fh(data4,recdelay);
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
dataAll=[data1;data2;data3;data4];
%mesma freq
%dataAll(4626,:)=[];
%dataAll(7857,:)=[];
%%
dataE1=[data1E1;data2E1;data3E1];
dataA=[data1A;data2A;data3A];
dataD=[data1D;data2D;data3D];
dataG=[data1G;data2G;data3G];
dataB=[data1B;data2B;data3B];
dataE2=[data1E2;data2E2;data3E2];
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
dataAll.('binFreq')=zeros(height(dataAll),1);

dataE1.('binFreq')=zeros(height(dataE1),1);
dataA.('binFreq')=zeros(height(dataA),1);
dataD.('binFreq')=zeros(height(dataD),1);
dataG.('binFreq')=zeros(height(dataG),1);
dataB.('binFreq')=zeros(height(dataB),1);
dataE2.('binFreq')=zeros(height(dataE2),1);

%%
clear fh
clear indCell1
clear indCell2
clear indCell3
clear indsort
clear k
clear name
clear toDelete
clear plotOn
clear i
clear dataTransp
%%
