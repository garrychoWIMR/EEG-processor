function EEG = forceChannelOrder(EEG)

eegChans = find(strcmp({EEG.chanlocs.type}, 'EEG'));
pnsChans = find(~strcmp({EEG.chanlocs.type}, 'EEG'));
if isempty(eegChans) || isempty(pnsChans)
    return
end
EEG.chanlocs = [asrow(EEG.chanlocs(eegChans)), asrow(EEG.chanlocs(pnsChans))];
if ~isfield(EEG, 'data')
    return
end
try
    EEG.data = [EEG.data(eegChans, :, :); EEG.data(pnsChans, :, :)];
catch ME
    keyboard
end
end