function [ArgOut, Next, Warnings] = Proc_Concatenate(Settings)
try
% ---------------------------------------------------------
% Initialize
ArgOut = [];
Next = 'none';
Warnings = [];
% ---------------------------------------------------------
clear ALLEEG
for i = 1:length(Settings.SourceFilePath)
    % ---------------------------------------------------------
    % Load the dataset
    tmp = LoadDataset(Settings.SourceFilePath{i}, 'all'); %#ok<*AGROW>
    % ---------------------------------------------------------
    % Remove the viewsettings
    if isfield(tmp.etc, 'viewsettings')
        tmp.etc = rmfield(tmp.etc, 'viewsettings');
    end
    % ---------------------------------------------------------
    % Remove the FASTER Stats
    if isfield(tmp.etc, 'faster')
        tmp.etc = rmfield(tmp.etc, 'faster');
    end
    % ---------------------------------------------------------
    % Force 'urevent' field in events (otherwise 'pop_mergeset' complains)
    if ~isfield(tmp.event, 'urevent')
        tmp.urevent = tmp.event;
        for j = 1:length(tmp.event)
            tmp.event(j).urevent = j;
        end
    end
    % ---------------------------------------------------------
    % Remove the Spectrogram
    if isfield(tmp, 'specdata')
        if ~isempty(tmp.specdata)
            Filename = reverse_fileparts(Settings.SourceFilePath{i});
            warning('Time-frequency spectral analysis data was removed, please recalculate on merged file.')
            Warnings = [Warnings; {sprintf('Time-frequency spectral analysis data was removed from ''%s'', please recalculate on merged file', Filename)}];
            Warnings = [Warnings; {'-----'}];
        end
    end
    tmp.specdata = [];
    tmp.specchans = [];
    tmp.specfreqs = [];
    tmp.spectimes = [];
    tmp.specnormmethod = 'none';
    tmp.specnormvals = struct();
    tmp.specnormfnc = [];
    % ---------------------------------------------------------
    % Remove the ICA
    tmp.icaact = [];
    tmp.icawinv = [];
    tmp.icasphere = [];
    tmp.icaweights = [];
    tmp.icachansind = [];
    tmp.specicaact = [];
    if isfield(tmp.etc, 'icaweights_beforerms')
        tmp.etc = rmfield(tmp.etc, 'icaweights_beforerms');
    end
    if isfield(tmp.etc, 'icasphere_beforerms')
        tmp.etc = rmfield(tmp.etc, 'icasphere_beforerms');
    end
    if isfield(tmp.etc, 'ic_classification')
        tmp.etc = rmfield(tmp.etc, 'ic_classification');
    end
    if isfield(tmp.etc, 'subtracted_components')
        tmp.etc = rmfield(tmp.etc, 'subtracted_components');
    end
    % Store in ALLEEG
    if i == 1
        ALLEEG = tmp; 
    else
        ALLEEG(i) = tmp;
    end
    clear tmp;
end
% ---------------------------------------------------------
% Checks
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Number of channels must be equal
if length(unique([ALLEEG.nbchan])) > 1
    error('Cannot append datasets because number of channels are not equal.')
end
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Sampling rate must be equal
if length(unique([ALLEEG.srate])) > 1
    error('Cannot append datasets because sampling rates are not equal.')
end
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% If the user wants to concatenate, and any of the datasets is an epoched
% recording, then we first need to force a continuous dataset
if strcmpi(Settings.Concatenate, 'time') && any([ALLEEG.trials] > 1)
    for i = 1:length(ALLEEG)
        if ALLEEG(i).trials > 1
            ALLEEG(i) = eeg_epoch2continuous(ALLEEG(i));
            ALLEEG(i).trials = 1;
            ALLEEG(i).xmin = 0;
            ALLEEG(i).xmax = ALLEEG(i).pnts/ALLEEG(i).srate - 1/ALLEEG(i).srate;
            ALLEEG(i).times = ALLEEG(i).xmin:1/ALLEEG(i).srate:ALLEEG(i).xmax;
            ALLEEG(i).etc.JSON.RecordingDuration = ALLEEG(i).pnts/ALLEEG(i).srate;
            ALLEEG(i).etc.JSON.RecordingType = 'discontinuous';
            ALLEEG(i).etc.JSON.TrialCount = 1;
        end
    end
end
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% If the user wants to append the dataset (epoch-wise) then we need to
% check the dimensions are equal
if strcmpi(Settings.Concatenate, 'epochs')
    if length(unique([ALLEEG.pnts])) > 1
        error('Cannot append datasets epoch-wise because the epoch lengths are not equal.')
    end
    if length(unique([ALLEEG.xmin])) > 1
        error('Cannot append datasets epoch-wise because the epoch start times are not equal.')
    end
    if length(unique([ALLEEG.xmax])) > 1
        error('Cannot append datasets epoch-wise because the epoch end times are not equal.')
    end
end
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Check that the labels and ref-chan are equal and the positions are similar
labels = arrayfun(@(e) {e.chanlocs.labels}', ALLEEG, 'UniformOutput', false);
labels = cat(2, labels{:});
for i = 1:size(labels, 1)
    if length(unique(labels(i, :))) > 1
        error('Cannot append datasets because the channel labels are different.')
    end
end
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
refs = arrayfun(@(e) {e.chanlocs(strcmpi({e.chanlocs.type}, 'EEG')).ref}', ALLEEG, 'UniformOutput', false);
refs = cat(2, refs{:});
for i = 1:size(refs, 1)
    if length(unique(refs(i, :))) > 1
        error('Cannot append datasets because some EEG channels have a different reference channel.')
    end
end
% ---------------------------------------------------------
% Sort the input datasets according to the start date of the recording and amplifier
rec_startdate = nan(1, length(ALLEEG));
for i = 1:length(ALLEEG)
    if isfield(ALLEEG(i).etc, 'rec_startdate')
        rec_startdate(i) = datenum(ALLEEG(i).etc.rec_startdate,'yyyy-mm-ddTHH:MM:SS');
    else
        warning('Could not sort the input datasets by the recording start date and time. Original input order assumed.')
        Warnings = [Warnings; {'Could not sort the input datasets by the recording start date and time. Original input order assumed.'}];
        Warnings = [Warnings; {'-----'}];
    end
end
if ~any(isnan(rec_startdate))
    [~, idx] = sort(rec_startdate);
    if ~all(1:length(ALLEEG) == idx)
        ALLEEG = ALLEEG(idx);
        warning('Sorted the input datasets by recording start date and time.')
        Warnings = [Warnings; {'Sorted the input datasets by recording start date and time.'}];
        Warnings = [Warnings; {'-----'}];
    end
end
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
locs = arrayfun(@(e) [[e.chanlocs.X]; [e.chanlocs.Y]; [e.chanlocs.Z]]', ALLEEG, 'UniformOutput', false);
locs = cat(3, locs{:});
for i = 1:size(locs, 1)
    if max([ ...
            max(locs(i, 1, :)) - min(locs(i, 1, :)), ...
            max(locs(i, 2, :)) - min(locs(i, 2, :)), ...
            max(locs(i, 3, :)) - min(locs(i, 3, :))]) > 0.1
        warning('Channel locations are not exactly equal. The output dataset will have the channel locations of the first input dataset.');
        Warnings = [Warnings; {'Channel locations are not exactly equal. The output dataset has the channel locations of the first input dataset.'}];
        Warnings = [Warnings; {'-----'}];
        break
    end
end
% ---------------------------------------------------------
% Go on and merge
EEG = pop_mergeset(ALLEEG, 1:length(ALLEEG), 0);
% ---------------------------------------------------------
% Dataset info
[EEG.filepath, EEG.setname] = fileparts(Settings.TargetFilePath);
EEG.filepath = strrep(EEG.filepath, filesep, '/');
EEG.filename = [EEG.setname, '.set'];
NewKeyVals = filename2struct(EEG.setname);
EEG.subject = NewKeyVals.sub;
if isfield(NewKeyVals, 'ses')
    EEG.session = NewKeyVals.ses;
else
    EEG.session = [];
end
% ---------------------------------------------------------
% Bad and interpolated channels
if ~isfield(EEG.etc, 'rej_channels')
    EEG.etc.rej_channels = cell(0);
end
if ~isfield(EEG.etc, 'interp_channels')
    EEG.etc.interp_channels = cell(0);
end
for i = 1:length(ALLEEG)
    if isfield(ALLEEG(i).etc, 'rej_channels')
        EEG.etc.rej_channels = unique([EEG.etc.rej_channels, ALLEEG(i).etc.rej_channels]);
    end
    if isfield(ALLEEG(i).etc, 'interp_channels')
        EEG.etc.interp_channels = unique([EEG.etc.interp_channels, ALLEEG(i).etc.interp_channels]);
    end
end
if isempty(EEG.etc.rej_channels)
    EEG.etc = rmfield(EEG.etc, 'rej_channels');
end
if isempty(EEG.etc.interp_channels)
    EEG.etc = rmfield(EEG.etc, 'interp_channels');
end
% ---------------------------------------------------------
% JSON
EEG.etc.JSON.TaskName = NewKeyVals.task;
EEG.etc.JSON.RecordingDuration = EEG.pnts/EEG.srate;
EEG.etc.JSON.RecordingType = 'discontinuous';
EEG.etc.JSON.TrialCount = EEG.trials;
EEG.etc.JSON.Sources = ascolumn(fullpath2bidsuri(Settings.ProtocolPath, arrayfun(@(e) fullfile(e.filepath, e.filename), ALLEEG, 'UniformOutput', false)));
% ---------------------------------------------------------
% Store history
EEG = storeHistory(EEG, 'Proc_Concatenate', Settings);
% ---------------------------------------------------------
% Save
EEG = SaveDataset(EEG, 'all');
% -------------------------------------------------------------------------
% Generate the output variable
EEG.data = []; % To save memory
EEG.specdata = [];
EEG.times = [];
EEG.icawinv = [];
EEG.icawsphere = [];
EEG.icawchansind = [];
EEG.filepath = strrep(EEG.filepath, filesep, '/');
ArgOut = EEG;
% What step to do next?
Next = 'AddFile';
catch ME
    disp('CALL RICK PLESAE')
    keyboard
end
end
