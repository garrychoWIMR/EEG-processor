function [EEG, warnmsg] = remlogic_import_sleep_events(EEG, eventFile, mffName)
% ID: remlogic import GC 13/11/2025

disp('>> BIDS: Importing events from Scored Events file')
warnmsg = [];

events=readtable(eventFile,'NumHeaderLines', 212);
events.Properties.VariableNames={'Position','Time','Event','Duration','None'};

% 1. Check whether events are before the start of the recording
% (EEG.etc.rec_startdate)

edfStart=find(events.Time==EEG.etc.rec_startdate); % index of staging start...
events_edf=events(edfStart:height(events),:); % filtered events table from start of staging
event_types=unique(events_edf.Event);
sleep_event_start=events.Time(edfStart,:);    


% sleep stages
sleepstages_idx=find(startsWith([events_edf.Event],'SLEEP'));
sleepstages=events_edf(sleepstages_idx,:);
    
% resp events- Unsure what a lot of them mean? 
resp_idx=find(startsWith([events_edf.Event],{'RESP','SNORE','AROUSAL','DESAT','APNEA','HYPOPNEA','EQUIPMENT','LIGHTS'}));
resp_events=events_edf(resp_idx,:);


% compiling the new structure
% event_struct=struct('latency',{},'duration',{},'type',{},'id',{},'is_reject',{},'orig_latency',{});

% need to populate within a loop

for i=1:height(resp_events)
    EEG.event(end+1).latency=seconds(resp_events.Time(i)-sleep_event_start)*EEG.srate;
    EEG.event(end).type=char(resp_events.Event(i));
    EEG.event(end).duration=resp_events.Duration(i)*EEG.srate;
    EEG.event(end).orig_latency=seconds(resp_events.Time(i)-sleep_event_start)*EEG.srate;
    EEG.event(end).is_reject=false;
    EEG.event(end).id=[];
end


% EEG.event=[EEG.event,event_struct]; % concatenate with EEG.event

EEG = eeg_checkset(EEG, 'eventconsistency');
EEG = forceValidEventType(EEG);

end