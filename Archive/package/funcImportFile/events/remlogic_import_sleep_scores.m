function [EEG, warnmsg] = remlogic_import_sleep_scores(EEG, scoreFile)

% ID: remlogic import GC 13/11/2025
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
        idx = ismember(lower({EEG.event.type}), {'SLEEP-S0','SLEEP-S1','SLEEP-S2','SLEEP-S3','SLEEP-REM'});
        if any(idx)
            warnmsg = 'Hypnogram events have been overwritten';
            EEG.event(idx) = [];
        end
    end
end
            
% get the hypnogram
stages = readtable(scoreFile, 'Delimiter', '\t', 'HeaderLines', 12);
stages.Properties.VariableNames = {'Time', 'Event', 'Duration_s'};

EEG.etc.stages = stages.Event; % second column
for s = 1:size(stages, 1)
    EEG.event(end+1).latency  = (s-1)*30*EEG.srate + 1;
    EEG.event(end).duration   = 30*EEG.srate;
    switch lower(stages.Event{s})
        case {'sleep-s1'}
            EEG.event(end).type = 'N1';
        case {'sleep-s2'}
            EEG.event(end).type = 'N2';
        case {'sleep-s3'}
            EEG.event(end).type = 'N3';
        case {'sleep-rem'}
            EEG.event(end).type = 'REM';
        case 'sleep-s0'
            EEG.event(end).type = 'Wake';
        otherwise
            EEG.event(end).type = 'NS';
    end
end

% EEG = set_sleep_cycles(EEG);

% Save the original event latency
for i = 1:length(EEG.event)
    EEG.event(i).orig_latency = EEG.event(i).latency;
end

EEG = eeg_checkset(EEG, 'eventconsistency');
EEG = forceValidEventType(EEG);

end
