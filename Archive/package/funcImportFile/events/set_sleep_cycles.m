function EEG = set_sleep_cycles(EEG)

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

stages = {EEG.event(ismember(lower({EEG.event.type}), {'1', '2', '3', 'n1', 'n2', 'n3', 's1', 's2', 's3', 'nrem1', 'nrem2', 'nrem3', 'r', 'rem', 'w', 'wake', 'ns'})).type};
stages = lower(stages);
definition = {'wake', 'n1', 'n2', 'n3', 'rem'};
cycles = sleep_cycles(stages, definition);

% Remove any sleep cycle event
idx_rm = contains({EEG.event.type}, {'slpcycle', 'slpep'});
EEG.event(idx_rm) = [];

for i = 1:length(cycles.times)
    if isnan(cycles.sleepcycle(i))
        continue
    end
    latency = cycles.times(i)*24*60*60*EEG.srate+1;
    EEG.event(end+1).latency = latency;
    EEG.event(end).duration = 30*EEG.srate;
    EEG.event(end).type = sprintf('slpcycle%i', cycles.sleepcycle(i));
    EEG.event(end).id = max([EEG.event.id])+1;
    EEG.event(end).is_reject = false;
end

for i = 1:length(cycles.times)
    if isnan(cycles.sleepepisode(i))
        continue
    end
    switch cycles.sleepepisode(i)
        case -1
            type = 'slpepdesc';
        case -2
            type = 'slpepsws';
        case 1
            type = 'slpepasc';
        case 2
            type = 'slpepremp';
    end
    latency = cycles.times(i)*24*60*60*EEG.srate+1;
    EEG.event(end+1).latency = latency;
    EEG.event(end).duration = 30*EEG.srate;
    EEG.event(end).type = type;
    EEG.event(end).id = max([EEG.event.id])+1;
    EEG.event(end).is_reject = false;
end

end