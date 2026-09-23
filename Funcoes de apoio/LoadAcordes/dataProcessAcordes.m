function [data] = dataProcessAcordes(HarmMic,HarmLine,Acorde)
%DATAPROCESS Processa os pontos para formar a base de dados
%   Detailed explanation goes here
arguments (Input)
    HarmMic
    HarmLine
    Acorde
end

arguments (Output)
    data
    
end
harmMax=max(length(HarmMic),length(HarmLine));
data=table('Size',[harmMax,6], ...
'VariableTypes',{'double','double','double','double','double','string'},...
'VariableNames',{'magnitudeDB','AnguloMic','AnguloLine','Frequencia','Complex','CasaCorda',});

id=0;
for j = 1:length(HarmMic)
    for k = 1 :length(HarmLine)
      if  HarmMic(j,2) == HarmLine(k,2) 
        id=id+1;
        data.magnitudeDB(id)=mag2db(abs(HarmMic(j,1)))-mag2db(abs(HarmLine(k,1)));
        data.AnguloMic(id)=angle(HarmMic(j,1));
        data.AnguloLine(id)=angle(HarmLine(k,1));
        data.Complex(id)=HarmMic(j,1)./HarmLine(k,1);
        data.Frequencia(id)=(HarmMic(j,2));
        data.CasaCorda(id)=Acorde;
      end
      
    
    end

end