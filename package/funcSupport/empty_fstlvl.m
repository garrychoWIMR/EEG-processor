function EEG = empty_fstlvl(Settings)

KeyVals = filename2struct(Settings.Filename);

EEG = struct();
EEG.filename = [Settings.Filename, '.mat'];
EEG.filepath = Settings.filepath;
EEG.subject = KeyVals.sub;
if isfield(KeyVals, 'ses')
    EEG.session = KeyVals.ses;
else
    EEG.session = [];
end
EEG.task = KeyVals.task;
if isfield(KeyVals, 'run')
    EEG.run = KeyVals.run;
else
    EEG.run = [];
end
EEG.group = '';
EEG.condition = '';
EEG.nbchan = nan;
EEG.trials = nan;
EEG.srate = nan;
EEG.features = struct([]);
EEG.ref = ''; % use 'avref' or 'common'
EEG.history = '';
EEG.chanlocs = struct([]); % channel locations
EEG.chaninfo = struct([]); % channel information
%
% ---------------------------------------------------------
% JSON
EEG.etc.JSON = struct();
EEG.etc.JSON.Description = 'description of file';
EEG.etc.JSON.Sources = fullpath2bidsuri(Settings.ProtocolPath, [EEG.filepath, '/', EEG.filename]);
EEG.etc.JSON.TaskName = KeyVals.task;
EEG.etc.JSON.EEGReference = EEG.ref;
EEG.etc.JSON.EEGChannelCount = EEG.nbchan;
EEG.etc.JSON.ECGChannelCount = 0;
EEG.etc.JSON.EMGChannelCount = 0;
EEG.etc.JSON.EOGChannelCount = 0;
EEG.etc.JSON.MiscChannelCount = 0;
EEG.etc.JSON.TrialCount = EEG.trials;
