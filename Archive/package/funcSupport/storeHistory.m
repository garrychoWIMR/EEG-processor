function EEG = storeHistory(EEG, funcName, Settings)
% -------------------------------------------------------------------------
% Extract all the settings from the structure
History = struct();
History.Fcn = funcName;
History.Date = char(datetime('now'), 'd MMM yyyy H:mm:ss');
History.Auth = Settings.Auth;
try
    Settings.SourceFilePath = fullpath2bidsuri(Settings.ProtocolPath, Settings.SourceFilePath);
    Settings.TargetFilePath = fullpath2bidsuri(Settings.ProtocolPath, Settings.TargetFilePath);
    Settings = removeFields(Settings);
    Settings = sortFields(Settings);
catch ME
    % TODO: Still working on this
    % Spectral analysis does not have TargetFilePath
end
History.Settings = Settings;
if ~isfield(EEG.etc, 'history')
    EEG.etc.history = History;
else
    EEG.etc.history = [EEG.etc.history; History];
end

    % ---------------------------------------------------------------------
    % SUB FUNCTION
    function r = isexempt(fname)
        switch lower(fname)
            case 'allevents'
                r = true;
            case 'auth'
                r = true;
            case 'chanlocs'
                r = true;
            case 'commoneventlabels'
                r = true;
            case 'commonchannels'
                r = true;
            case 'editable'
                r = true;
            case 'eeg'
                r = true;
            case 'hasica'
                r = true;
            case 'header'
                r = true;
            case 'inputratio'
                r = true;
            case 'iscropped'
                r = true;
            case 'ishdeeg'
                r = true;
            case 'legend'
                r = true;
            case 'logtransdata'
                r = true;
            case 'markersize'
                r = true;
            case 'minrecduration'
                r = true;
            case 'minsamplingfreq'
                r = true;
            case 'ntrials'
                r = true;
            case 'psd'
                r = true;
            case 'protocolpath'
                r = true;
            case 'recordingname'
                r = true;
            case 'selchan'
                r = true;
            case 'threshold'
                r = true;
            case 'topochanlocs'
                r = true;
            otherwise
                r = false;
        end
    end
    % ---------------------------------------------------------------------
    function s = removeFields(s)
        fn = fieldnames(s);
        for i = 1:length(fn)
            if isexempt(fn{i})
                s = rmfield(s, fn{i});
                continue
            end
            if isstruct(s.(fn{i}))
                s.(fn{i}) = removeFields(s.(fn{i}));
            end
        end
    end
    % ---------------------------------------------------------------------
    function s = sortFields(s)
        fn = fieldnames(s);
        bool = false(length(fn), 1);
        for i = 1:length(fn)
            if isstruct(s.(fn{i}))
                bool(i) = true;
                s.(fn{i}) = sortFields(s.(fn{i}));
            end
        end
        asorted = [sort(fn(~bool)); sort(fn(bool))];
        s = orderfields(s, asorted);
    end

end