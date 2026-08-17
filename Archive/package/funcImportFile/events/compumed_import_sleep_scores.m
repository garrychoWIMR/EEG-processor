function [EEG, warnmsg] = compumed_import_sleep_scores(EEG, scoreFile)

disp('>> BIDS: Importing events from Hypnogram file')
warnmsg = [];

createEvents = false;
if ~isfield(EEG, 'event')
    createEvents = true;
elseif isempty(EEG.event)
    createEvents = true;
end

if createEvents
    EEG.event = struct();
    EEG.event.latency = 0.5;
    EEG.event.duration = 1;
    EEG.event.type = 'start';
    EEG.event.id = 1;
    EEG.event.is_reject = false;
end

% Check if Hypnogram events exist already, if so, overwrite them
if isstruct(EEG.event)
    if isfield(EEG.event, 'type')
        idx = ismember(lower({EEG.event.type}), {'1', '2', '3', 'n1', 'n2', 'n3', 's1', 's2', 's3', 'nrem1', 'nrem2', 'nrem3', 'r', 'rem', 'w', 'wake', 'ns'});
        if any(idx)
            warnmsg = 'Hypnogram events have been overwritten';
            EEG.event(idx) = [];
        end
    end
end
            
% get the hypnogram
stages = readtable(scoreFile, 'ReadVariableNames', false, 'Format', '%s');
EEG.etc.stages = stages.Var1;
for s = 1:size(stages, 1)
    EEG.event(end+1).latency  = (s-1)*30*EEG.srate + 1;
    EEG.event(end).duration   = 30*EEG.srate;
    switch lower(stages.Var1{s})
        case {'n1', '1'}
            EEG.event(end).type = 'N1';
        case {'n2', '2'}
            EEG.event(end).type = 'N2';
        case {'n3', '3'}
            EEG.event(end).type = 'N3';
        case {'r', 'rem'}
            EEG.event(end).type = 'REM';
        case 'w'
            EEG.event(end).type = 'Wake';
        otherwise
            EEG.event(end).type = 'NS';
    end
end

EEG = set_sleep_cycles(EEG);

% Save the original event latency
for i = 1:length(EEG.event)
    EEG.event(i).orig_latency = EEG.event(i).latency;
end

EEG = eeg_checkset(EEG, 'eventconsistency');
EEG = forceValidEventType(EEG);

end
