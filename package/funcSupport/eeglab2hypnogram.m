function HYP = eeglab2hypnogram(EEG)
% Crop between lights off and on
% idx_lightsoff = find(strcmpi({EEG.event.type}, 'loff'));
% idx_lightson = find(strcmpi({EEG.event.type}, 'lon'));
% if ~isempty(idx_lightson) && length(idx_lightson) == 1
%     EEG.event = EEG.event(1:idx_lightson);
% elseif isempty(idx_lightson)
%     warning('File ''%s'' does not have lights-on marker, did not crop data.', EEG.setname);
% elseif length(idx_lightson) > 1
%     warning('File ''%s'' has more than one lights-on marker, did not crop data.', EEG.setname);
% end
% if ~isempty(idx_lightsoff) && length(idx_lightsoff) == 1
%     EEG.event = EEG.event(idx_lightsoff:end);
% elseif isempty(idx_lightsoff)
%     warning('File ''%s'' does not have lights-off marke, did not crop datar.', EEG.setname);
% elseif length(idx_lightsoff) > 1
%     warning('File ''%s'' has more than one lights-off marker, did not crop data.', EEG.setname);
% end
% Extract sleep stages
HYP = EEG.event(ismember(lower({EEG.event.type}), {'n1', 'n2', 'n3', 'w', 'r', 'wake', 'rem', 's1', 's2', 's3', 'nrem1', 'nrem2', 'nrem3', '1', '2', '3'}));
stages = {HYP.type};
% Calculte sleep cycles
HYP = sleep_cycles(stages, {'wake', 'n1', 'n2', 'n3', 'rem'});
% Transform data and create output table
HYP.times = HYP.times';
HYP.stage_num = HYP.sleepstage'; 
HYP.stage_str = stages';
HYP.cycle = HYP.sleepcycle';
HYP.episode = HYP.sleepepisode';
HYP.latency = HYP.times * 24*60*60*EEG.srate;
HYP.datnm = HYP.times + datenum(EEG.etc.rec_startdate, 'yyyy-mm-ddTHH:MM:SS'); %#ok<*DATNM>
HYP.datst = cellstr(datestr(HYP.datnm, 'yyyy-mm-ddTHH:MM:SS')); %#ok<*DATST>
HYP.sleepwin = false(length(HYP.times), 1);
HYP.sleepwin(find(HYP.sleepstage ~= 1, 1, 'first') : find(HYP.sleepstage ~= 1, 1, 'last')) = true;
HYP = rmfield(HYP, {'sleepcycle', 'sleepepisode', 'sleepstage'});
HYP = struct2table(HYP);
end