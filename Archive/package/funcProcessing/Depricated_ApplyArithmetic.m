function EEG = Proc_ApplyArithmetic(Settings)

% Check we have the correct number of files
switch Settings.Arithmetic
    case 'average'
        if size(Settings.Files, 1) < 2
            error('Must specify at least 2 input files to average.')
        end
    case 'subtract'
        if size(Settings.Files, 1) ~= 2
            error('Must specify 2 and only 2 input files to subtract.')
        end
    otherwise
        error('The arithmetic ''%s'' is not supported.', Settings.Arithmetic)
end

% Check that all input files are the same type
Subs = cellfun(@(kv) kv.sub, Settings.Files.KeyVals, 'UniformOutput', false);
FileTypes = cellfun(@(kv) kv.filetype, Settings.Files.KeyVals, 'UniformOutput', false);
if length(unique(Subs)) ~= 1
    error('Input files must be from the same subject.')
end
if length(unique(FileTypes)) ~= 1
    error('Input files must be of the same type.')
end

% Load input files
try
    for i = 1:size(Settings.Files, 1)
        if i == 1
            IN = LoadDataset(Settings.Files.Path{i}, 'all');
        else
            IN(i) = LoadDataset(Settings.Files.Path{i}, 'all');
        end
    end
catch ME
    getReport(ME)
    fprintf('Could not load all datasets, copy the error above and notify Rick please.\n');
    EEG = struct([]);
    return
end

% Check that all the data properties and sizes are compatible
if length(unique([IN.nbchan])) ~= 1
    error('Number of channels in each input file must be equal.')
end
if length(unique([IN.trials])) ~= 1
    error('Number of trials in each input file must be equal.')
end
if unique([IN.trials]) ~= 1
    error('Number of trials in each input file must be 1.')
end
if length(unique({IN.ref})) ~= 1
    error('Reference montages in each input file must be equal.')
end

EEG = struct();
switch FileTypes{1}
    case 'powerspect'
        % Some more checks
        Check = arrayfun(@(i) length(i.bands), IN, 'UniformOutput', true);
        if length(unique(Check)) ~= 1
            error('The frequency band specification of all input files must be equal.')
        end
        Check = arrayfun(@(i) i.etc.JSON.SpectralAnalysis.SpectrogramType, IN, 'UniformOutput', false);
        if length(unique(Check)) ~= 1
            error('The spectrogram type of all input files must be equal.')
        end
        Check = arrayfun(@(i) i.etc.JSON.SpectralAnalysis.FrequencyStep, IN, 'UniformOutput', true);
        if length(unique(Check)) ~= 1
            error('The frequency step (resolution) of all input files must be equal.')
        end
        Check = arrayfun(@(i) i.etc.JSON.SpectralAnalysis.MaximumFrequency, IN, 'UniformOutput', true);
        if length(unique(Check)) ~= 1
            error('The maximum frequency of all input files must be equal.')
        end
        Check = arrayfun(@(i) i.etc.JSON.SpectralAnalysis.Norm.AcrossFreqBands, IN, 'UniformOutput', true);
        if length(unique(Check)) ~= 1
            error('The normalization settings of all input files must be equal.')
        end
        Check = arrayfun(@(i) i.etc.JSON.SpectralAnalysis.Norm.AcrossChannels, IN, 'UniformOutput', true);
        if length(unique(Check)) ~= 1
            error('The normalization settings of all input files must be equal.')
        end
        Check = arrayfun(@(i) i.etc.JSON.SpectralAnalysis.Norm.AcrossTrials, IN, 'UniformOutput', true);
        if length(unique(Check)) ~= 1
            error('The normalization settings of all input files must be equal.')
        end
        % Create header info
        [EEG.filepath, EEG.filename] = fileparts(Settings.FullFilePath);
        NewKeyVals = filename2struct(EEG.filename);
        EEG.filename = [EEG.filename, '.mat'];
        EEG.subject = NewKeyVals.sub;
        EEG.session = NewKeyVals.ses;
        EEG.task = NewKeyVals.task;
        EEG.run = NewKeyVals.run;
        EEG.group = [];
        EEG.condition = [];
        EEG.nbchan = IN(1).nbchan;
        EEG.trials = 1; % assumed to be one
        if length(unique([IN.srate])) ~= 1
            EEG.srate = 'mixed';
        else
            EEG.srate = IN(1).srate;
        end
        EEG.ref = IN(1).ref;
        EEG.history = IN(1).history;
        EEG.data = [];
        EEG.freqs = IN(1).freqs;
        EEG.freqstep = IN(1).freqstep;
        EEG.bands = struct();
        EEG.chanlocs = struct();
        EEG.chaninfo = struct();
        EEG.etc = struct();
        EEG.etc.JSON = struct();
        EEG.etc.JSON.Description = IN(1).etc.JSON.Description;
        EEG.etc.JSON.Sources = fullpath2bidsuri(Settings.ProtocolPath, Settings.Files.Path);
        EEG.etc.JSON.TaskName = NewKeyVals.task;
        EEG.etc.JSON.EEGReference = EEG.ref;
        EEG.etc.JSON.EEGChannelCount = EEG.nbchan;
        EEG.etc.JSON.ECGChannelCount = 0;
        EEG.etc.JSON.EMGChannelCount = 0;
        EEG.etc.JSON.EOGChannelCount = 0;
        EEG.etc.JSON.MiscChannelCount = 0;
        EEG.etc.JSON.TrialCount = EEG.trials;
        EEG.etc.JSON.SpectralAnalysis = IN(1).etc.JSON.SpectralAnalysis;

        % Construct the settings for normalization
        cnt = 0;
        for k = 1:length(IN(1).bands)
            % Check that the frequency band definitions are the same
            Check = arrayfun(@(i) i.bands(k).label, IN, 'UniformOutput', false);
            if length(unique(Check)) ~= 1
                error('The frequency band specification of all input files must be equal.')
            end
            Check = arrayfun(@(i) i.bands(k).type, IN, 'UniformOutput', false);
            if length(unique(Check)) ~= 1
                error('The frequency band specification of all input files must be equal.')
            end
            Check = arrayfun(@(i) i.bands(k).freqrange(1), IN, 'UniformOutput', true);
            if length(unique(Check)) ~= 1
                error('The frequency band specification of all input files must be equal.')
            end
            Check = arrayfun(@(i) i.bands(k).freqrange(2), IN, 'UniformOutput', true);
            if length(unique(Check)) ~= 1
                error('The frequency band specification of all input files must be equal.')
            end
            % We can skip the normalized freq-band definitions, they will be calculated
            if strcmpi(IN(1).bands(k).type, 'normalized')
                continue
            end
            % Increase counter
            cnt = cnt+1;
            % Define freq-band settings
            Settings.FreqDef(cnt).band = IN(1).bands(k).freqrange;
            Settings.FreqDef(cnt).label = IN(1).bands(k).label;
            Settings.FreqDef(cnt).type = IN(1).bands(k).type;
            Settings.Norm = IN(1).etc.JSON.SpectralAnalysis.Norm;
        end

        % Apply arithmetic
        switch Settings.Arithmetic
            case 'average'

                EEG.data = mean(cat(4, IN.data), 4, 'omitnan');
                EEG = NormalizePowerSpectrum(EEG, Settings);
            otherwise
                error('The arithmetic ''%s'' is not supported.', Settings.Arithmetic)
        end
end


% Average the channel locations across files

% Average the 'ndchanlocs' across files

% Check that the nose direction is the same
