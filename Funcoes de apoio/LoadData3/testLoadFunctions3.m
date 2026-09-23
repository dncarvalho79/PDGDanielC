clear

data=table();
plotOn=false;

for i=1:108

    name=strcat('loadData3_',num2str(i));
    fh=str2func(name)
    data=fh(data,plotOn);
    toDelete = data.Frequencia == 0;
    data(toDelete,:) = [];

end
%%

indices=not(cellfun(@isempty, (strfind(data.CasaCorda,'E1'))));
figure('Name','Harmonicos presentes nos dois corda E1')
stem(data.Frequencia(indices,:),data.magnitudeDB(indices,:))       
ylim([-30 30])
xlim([80 24000])

xscale('log')
%%

indices=not(cellfun(@isempty, (strfind(data.CasaCorda,'A'))));
figure('Name','Harmonicos presentes nos dois corda A')
stem(data.Frequencia(indices,:),data.magnitudeDB(indices,:))   
ylim([-30 30])
xlim([80 24000])

xscale('log')
%%

indices=not(cellfun(@isempty, (strfind(data.CasaCorda,'D'))));
figure('Name','Harmonicos presentes nos dois corda D')
stem(data.Frequencia(indices,:),data.magnitudeDB(indices,:))    
xlim([80 24000])
ylim([-30 30])
xscale('log')
%%

indices=not(cellfun(@isempty, (strfind(data.CasaCorda,'G'))));
figure('Name','Harmonicos presentes nos dois corda G')
stem(data.Frequencia(indices,:),data.magnitudeDB(indices,:))    
xlim([80 24000])
ylim([-30 30])

xscale('log')
%%

indices=not(cellfun(@isempty, (strfind(data.CasaCorda,'B'))));
figure('Name','Harmonicos presentes nos dois corda B')
stem(data.Frequencia(indices,:),data.magnitudeDB(indices,:))
xlim([80 24000])
ylim([-30 30])

xscale('log')
%%
indices=not(cellfun(@isempty, (strfind(data.CasaCorda,'E2'))));
figure('Name','Harmonicos presentes nos dois corda E2')
stem(data.Frequencia(indices,:),data.magnitudeDB(indices,:)) 
ylim([-30 30])
xlim([80 24000])
xscale('log')
%%

figure('Name','Harmonicos presentes nos dois')
[~,indices]=sort(data.Frequencia);
stem(data.Frequencia,data.magnitudeDB) 
ylim([-30 30])
xlim([80 24000])
xscale('log')
%%
figure('Name','angulo de harmonicos presentes nos dois')
[freqSort, indSort]=sort(data.Frequencia);
angSort=data.Angulo(indSort);
plot(freqSort,unwrap(angSort))
xlim([80 24000])
xscale('log')