function [dataOut] = loadAcordes28(dataIn,recdelay)
%load Data com findpeak

arguments (Input)
    dataIn
    recdelay
end

arguments (Output)
    dataOut
end
%Acorde repetido na base de dados

a=recdelay;

dataOut = [dataIn];

end