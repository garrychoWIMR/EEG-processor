function PSD = NormalizePowerSpectrum(PSD, Settings)

% Garry Add 20/06/2025
if isfield(Settings, 'EEG')
    Settings.FreqDef = Settings.EEG.eeg.bands;
end
% BIG CHANGE - All of the Settings.FreqDef(i).freqrange values normally -
% Setings.FreqDef(i).band indicated by % at end of the line
% Garry Finished adding

try
    AllFreqs = cat(1, Settings.FreqDef.freqrange); 
catch ME
    for i = 1:length(Settings.FreqDef)
        Settings.FreqDef(i).freqrange = Settings.FreqDef(i).band;
    end
end
AllFreqs = cat(1, Settings.FreqDef.freqrange); 

cnt = 0;
for i = 1:length(Settings.FreqDef)
    % ---------------------------------------------------------
    % Get indices of this frequency band
    idxFreq = PSD.freqs >= Settings.FreqDef(i).freqrange(1) & PSD.freqs < Settings.FreqDef(i).freqrange(2);

    if ~any(idxFreq)
        continue
    end
    % ---------------------------------------------------------
    % increase counter
    cnt = cnt+1;
    % ---------------------------------------------------------
    % Integrate absolute power
    fprintf('>> BIDS: Integrating power spectral density for frequency band ''%s'' between %.1f - %.1f Hz.\n', Settings.FreqDef(i).label, Settings.FreqDef(i).freqrange(1), Settings.FreqDef(i).freqrange(2))
    PSD.features(cnt).label = sprintf('%s', Settings.FreqDef(i).label);
    PSD.features(cnt).type = 'absolute power';
    PSD.features(cnt).freqrange = Settings.FreqDef(i).freqrange;
    PSD.features(cnt).data = squeeze(sum(PSD.data(:, idxFreq, :), 2) .* PSD.freqstep);
    % ---------------------------------------------------------
    % Extract the frequency indices for normalization (across all freqs or within freq band)
    fprintf('>> BIDS: Normalizing %s power relative to: ', Settings.FreqDef(i).label);
    if Settings.Norm.AcrossFreqBands
        fprintf('total power in the frequencies %.1f - %.1f Hz ', min(AllFreqs(:)), max(AllFreqs(:)));
        idxNormFreq = PSD.freqs >= min(AllFreqs(:)) & PSD.freqs < max(AllFreqs(:));
    else
        fprintf('total power in the frequencies %.1f - %.1f Hz ', Settings.FreqDef(i).freqrange(1), Settings.FreqDef(i).freqrange(2));
        idxNormFreq = idxFreq;
    end
    % ---------------------------------------------------------
    % Caluclate normalization factor i.e. integrate across frequencies
    NormFactor = sum(PSD.data(:, idxNormFreq, :), 2) .* PSD.freqstep;
    % Take the average across channels if requested
    if Settings.Norm.AcrossChannels
        fprintf('averaged across channels ');
        NormFactor = mean(NormFactor, 1);
    else
        fprintf('for each individual channel ');
    end
    % Take the average across trials if requested
    if Settings.Norm.AcrossTrials
        fprintf('and averaged across %i trials', PSD.trials);
        NormFactor = mean(NormFactor, 3);
    else
        fprintf('and for each individual trial (%i trials)', PSD.trials);
    end
    fprintf('\n');
    % Re-expand the normalization factor so it is the same size as the data
    if size(NormFactor, 1) == 1
        NormFactor = repmat(NormFactor, size(PSD.data, 1), 1, 1);
    end
    if size(NormFactor, 3) == 1
        NormFactor = repmat(NormFactor, 1, 1, size(PSD.data, 3));
    end
    % Normalize the power relative to the normalization factor
    cnt = cnt+1;
    PSD.features(cnt).label = sprintf('%s', Settings.FreqDef(i).label);
    PSD.features(cnt).type = 'normalized power';
    PSD.features(cnt).freqrange = Settings.FreqDef(i).freqrange;
    PSD.features(cnt).data = squeeze((sum(PSD.data(:, idxFreq, :), 2) .* PSD.freqstep) ./ NormFactor);
end
end
