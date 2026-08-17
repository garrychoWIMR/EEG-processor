function EEG = compumedics_import_data(FullFilePath, varargin)

DoResample = false;
for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'doresample'
            DoResample = varargin{i+1};
    end
end

% Create empty set
EEG = eeg_emptyset();
% Read header and data
HDR = ft_read_header(FullFilePath);
% ID #0022
% Ability to read mixed sampling frequencies
tmp = edf2fieldtrip(FullFilePath);
EEG.data = single(tmp.trial{1});
% EEG.data = single(ft_read_data(FullFilePath));
% Set filename and path
[EEG.filepath, EEG.setname] = fileparts(FullFilePath);
EEG.filename = [EEG.setname, '.set'];
EEG.comments = sprintf('Original file: %s', FullFilePath);
% Set the recording dimensions
EEG.trials = HDR.nTrials;
EEG.pnts = size(EEG.data, 2);
EEG.srate = tmp.fsample;
EEG.times = 0:1/EEG.srate:(EEG.pnts-1)/EEG.srate;
EEG.xmin = EEG.times(1);
EEG.xmax = EEG.times(end);
% Set the reference type
EEG.ref = 'common';
% insert start date
EEG.etc.T0 = HDR.orig.T0;
EEG.etc.rec_startdate = datenum(EEG.etc.T0);
% Set the channel locations
EEG.chanlocs = struct('labels', '', 'ref', [], 'theta', [], 'radius', [], 'X', [], 'Y', [], 'Z', [], 'type', '', 'unit', '');
for i = 1:length(tmp.label)
    EEG.chanlocs(i, 1).labels = tmp.label{i};
end
% Insert reference channel
EEG.chanlocs(end+1).labels = 'REF';
if ndims(EEG.data) == 3
    EEG.data(end+1, :, :) = zeros(1, EEG.pnts, EEG.trials, 'single');
else
    EEG.data(end+1, :) = zeros(1, EEG.pnts, 'single');
end
EEG.nbchan = size(EEG.data, 1);

% For large files sampled at 1000 Hz, we need to downsample to prevent
% memory issues.
if DoResample && EEG.srate > 500
    % Automatically applies low-pass antialiasing filter at 90% of the
    % Nyquist frequency
    Settings = struct();
    Settings.DoResample = true;
    Settings.ResampleRate = 500;
    EEG = Proc_Resample(EEG, Settings);
end

% The PIB channels are intermixed with the EEG channels, so we need
% to extract them and place them at the end of the rows
chanlocs = readlocs(which('Compumedics-257.sfp'));
isEEG = ismember(lower({EEG.chanlocs.labels}), lower({chanlocs.labels}));
% make sure we have all the expected EEG channels
missingEEG = setdiff(lower({chanlocs.labels}), lower({EEG.chanlocs.labels}));
if ~isempty(missingEEG)
    error('Missing EEG channels:\n%s', strjoin(missingEEG, ', '));
end
% Make sure we do not have any extra EEG chans
extraEEG = setdiff(lower({EEG.chanlocs(isEEG).labels}), lower({chanlocs.labels}));
if ~isempty(extraEEG)
    error('Unexpected EEG channels found:\n%s', strjoin(extraEEG, ', '));
end
% Add the channel type and reference label
for i = 1:EEG.nbchan
    if isEEG(i)
        EEG.chanlocs(i).type = 'EEG';
        EEG.chanlocs(i).ref = 'REF';
    else
        EEG.chanlocs(i).type = 'PNS';
    end
    EEG.chanlocs(i).unit = '';
end
% Reorder the chanlocs and data
% Indices of EEG channels in dataset, sorted to expectedEEG order
[~, eegIdx] = ismember(lower({chanlocs.labels}), lower({EEG.chanlocs.labels}));
physIdx = find(~isEEG);
% Reorder
resortIdx = [ascolumn(eegIdx); ascolumn(physIdx)];
EEG.data = EEG.data(resortIdx, :, :);
EEG.chanlocs = EEG.chanlocs(resortIdx);

% Save original channel locations
EEG.urchanlocs = EEG.chanlocs;

% Rename the physiology channels
EEG.chanlocs = MapPnsWorkspace(EEG.chanlocs);

end