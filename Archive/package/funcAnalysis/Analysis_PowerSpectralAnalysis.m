function [ArgOut, Next, Warnings] = Analysis_PowerSpectralAnalysis(Settings)
% ---------------------------------------------------------
% Initialize
ArgOut = [];
Next = 'none';
Warnings = [];
% ---------------------------------------------------------
% Get data path
[~, filename] = fileparts(Settings.SourceFilePath);
% ---------------------------------------------------------
% Check if dataset exists
if exist(Settings.SourceFilePath) == 0 %#ok<EXIST> 
    Warnings = [Warnings; {sprintf('Could not load dataset ''%s'', file not found.', filename)}];
    Warnings = [Warnings; {'-----'}];
    return
end
% ---------------------------------------------------------
% Load data
disp('>> BIDS: Loading dataset')
EEG = LoadDataset(Settings.SourceFilePath, 'all');
% Initialize the output 
KeyVals = filename2struct(Settings.Filename);
PSD = struct();
PSD.filename = [Settings.Filename, '.mat'];
if isfield(KeyVals, 'ses')
    PSD.filepath = [Settings.ProtocolPath, '/derivatives/EEG-output-fstlvl/sub-', KeyVals.sub, '/ses-', KeyVals.ses];
else
    PSD.filepath = [Settings.ProtocolPath, '/derivatives/EEG-output-fstlvl/sub-', KeyVals.sub];
end
PSD.subject = KeyVals.sub;
if isfield(KeyVals, 'ses')
    PSD.session = KeyVals.ses;
else
    PSD.session = [];
end
PSD.task = KeyVals.task;
if isfield(KeyVals, 'run')
    PSD.run = KeyVals.run;
else
    PSD.run = [];
end
PSD.group = '';
PSD.condition = '';
PSD.nbchan = EEG.nbchan;
PSD.trials = EEG.trials;
PSD.srate = EEG.srate;
PSD.ref = EEG.ref;
PSD.history = EEG.history;
% ---------------------------------------------------------
% Define parameters for the analysis
% Channel selection
ChanSel = strcmpi({EEG.chanlocs.type}, 'EEG');
% Window length in samples
WinLength = Settings.Window.Length * EEG.srate;
% Check if the window length is smaller than the epoch length
if WinLength > EEG.pnts
    fprintf('>> BIDS: Warning. The window length was longer than the number of datapoints. Window length was adjusted to %.3f seconds.\n', EEG.pnts/EEG.srate)
    Warnings = [Warnings; {sprintf('Window length was longer than the number of datapoints. Window length was adjusted to %.3f seconds.\n', EEG.pnts/EEG.srate)}];
    Warnings = [Warnings; {'-----'}];
    WinLength = EEG.pnts;
end
% Define window step
WinStep = floor(WinLength * (Settings.Window.Overlap/100));
% ---------------------------------------------------------
% If the settings contain outlier channels, interpolate those first
if isfield(Settings, 'Outliers')
    fprintf('>> BIDS: Interpolating %i outlier channels\n', length(Settings.Outliers))
    EEG = Proc_InterpolateChannels(EEG, find(...
        ismember({EEG.chanlocs.labels}, Settings.Outliers) ...
        ));
end
% ---------------------------------------------------------
fprintf('>> BIDS: Running power-spectral analysis using Welch''s method on %i trials with windows of %.3f sec and %.1f%% overlap.\n', EEG.trials, WinLength/EEG.srate, 100*WinStep/WinLength)
% ---------------------------------------------------------
% Run
for i = 1:EEG.trials
    Data = squeeze(EEG.data(ChanSel, :, i));
    [Pow, Freq] = pwelch(Data', WinLength, WinStep, max([256, 2^nextpow2(WinLength)]), EEG.srate);
    if i == 1
        % Initialize the output matrix
        PSD.data = nan(sum(ChanSel), length(Freq), EEG.trials);
    end
    PSD.data(:, :, i) = Pow';
    PSD.freqs = Freq;
end
PSD.freqstep = mean(diff(PSD.freqs));
% ---------------------------------------------------------
% Calculate the absolute and normalized power in user-specified frequency bands
PSD = NormalizePowerSpectrum(PSD, Settings);
% ---------------------------------------------------------
% Calculate the mean/median across trials or squeeze the dataset
switch Settings.EpochAverage
    case 'mean'
        fprintf('>> BIDS: calculating the mean power spectral density estimates across trials.\n')
        PSD.data = squeeze(mean(PSD.data, 3));
        for i = 1:length(PSD.features)
            PSD.features(i).data = squeeze(mean(PSD.features(i).data, 3));
        end
    case 'median'
        fprintf('>> BIDS: calculating the median power spectral density estimates across trials.\n')
        PSD.data = squeeze(median(PSD.data, 3));
        for i = 1:length(PSD.features)
            PSD.features(i).data = squeeze(median(PSD.features(i).data, 3));
        end
    otherwise
        % Try to squeeze the data, i.e. when there was only one trial
        PSD.data = squeeze(PSD.data);
        for i = 1:length(PSD.features)
            PSD.features(i).data = squeeze(PSD.features(i).data);
        end
end
% ---------------------------------------------------------
% Save some more info
PSD.nbchan = sum(ChanSel);
PSD.trials = size(PSD.data, 3);
PSD.chanlocs = EEG.chanlocs(ChanSel);
PSD.chaninfo = EEG.chaninfo;
% ---------------------------------------------------------
% JSON
PSD.etc.JSON = struct();
PSD.etc.JSON.Description = 'Power spectral density estimate of the EEG signal, using Welch''s overlapped segment averaging estimator.';
PSD.etc.JSON.Sources = fullpath2bidsuri(Settings.ProtocolPath, [EEG.filepath, '/', EEG.filename]);
PSD.etc.JSON.TaskName = KeyVals.task;
PSD.etc.JSON.EEGReference = EEG.etc.JSON.EEGReference;
PSD.etc.JSON.EEGChannelCount = PSD.nbchan;
PSD.etc.JSON.ECGChannelCount = 0;
PSD.etc.JSON.EMGChannelCount = 0;
PSD.etc.JSON.EOGChannelCount = 0;
PSD.etc.JSON.MiscChannelCount = 0;
PSD.etc.JSON.TrialCount = PSD.trials;
PSD.etc.JSON.SpectralAnalysis = struct();
PSD.etc.JSON.SpectralAnalysis.ChannelSelection = {PSD.chanlocs.labels};
PSD.etc.JSON.SpectralAnalysis.SpectrogramType = 'pwelch';
PSD.etc.JSON.SpectralAnalysis.FrequencyStep = mean(abs(diff(PSD.freqs)));
PSD.etc.JSON.SpectralAnalysis.MaximumFrequency = PSD.freqs(end);
PSD.etc.JSON.SpectralAnalysis.WindowLength = Settings.Window.Length;
PSD.etc.JSON.SpectralAnalysis.WindowOverlap = Settings.Window.Overlap;
PSD.etc.JSON.SpectralAnalysis.Norm.AcrossFreqBands = ifelse(Settings.Norm.AcrossFreqBands, 1, 0);
PSD.etc.JSON.SpectralAnalysis.Norm.AcrossChannels = ifelse(Settings.Norm.AcrossChannels, 1, 0);
PSD.etc.JSON.SpectralAnalysis.Norm.AcrossTrials = ifelse(Settings.Norm.AcrossTrials, 1, 0);
PSD.etc.JSON.SpectralAnalysis.EpochAverage = Settings.EpochAverage;
% ---------------------------------------------------------
% Store history
PSD = storeHistory(PSD, 'Analysis_PowerSpectralAnalysis', Settings);
% ---------------------------------------------------------
% Save file to disk
PSD = SaveDataset(PSD, 'matrix');
% ---------------------------------------------------------
% Set output
ArgOut = PSD;
% What step to do next?
Next = 'AddFile';

end