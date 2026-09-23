function [data] = dataProcess(HarmMic,HarmLine,casaCorda)
    %DATAPROCESS Processa os pontos para formar a base de dados
    %   Detailed explanation goes here
    arguments (Input)
        HarmMic
        HarmLine
        casaCorda
    end
    
    arguments (Output)
        data
        
    end
    %%
    tableMaxSize=max(length(HarmMic),length(HarmLine));
    data=table('Size',[tableMaxSize,6], ...
    'VariableTypes',{'double','double','double','double','double','string'},...
    'VariableNames',{'magnitudeDB','AnguloMic','AnguloLine','Frequencia','Complex','CasaCorda'});
    erro=0.01;
    id=0;
    for m = 1:length(HarmMic)
        for l =1:length(HarmLine)
            if 1-erro< HarmLine(l,2)/HarmMic(m,2) & HarmLine(l,2)/HarmMic(m,2) < 1+erro
                id=id+1;
                data.magnitudeDB(id)=mag2db(abs(HarmMic(m,1)))-mag2db(abs(HarmLine(l,1)));
                data.AnguloMic(id)=angle(HarmMic(m,1));
                data.AnguloLine(id)=angle(HarmLine(l,1));
                data.Frequencia(id)=(HarmMic(m,2)+HarmLine(l,2))/2;
                data.Complex(id)=HarmMic(m,1)./HarmLine(l,1);
                data.CasaCorda(id)=casaCorda;
                
            end
        end
    end
end
