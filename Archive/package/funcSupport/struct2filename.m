function Filename = struct2filename(KeyVals)

if isfield(KeyVals, 'exclude')
    if isfield(KeyVals.exclude, 'ses')
        if KeyVals.exclude.ses
            KeyVals = rmfield(KeyVals, 'ses');
        end
    end
    if isfield(KeyVals.exclude, 'run')
        if KeyVals.exclude.run
            KeyVals = rmfield(KeyVals, 'run');
        end
    end
    KeyVals = rmfield(KeyVals, 'exclude');
end

Keys = fieldnames(KeyVals);
if find(strcmpi(Keys, 'filetype')) ~= length(Keys)
    idx = strcmpi(Keys, 'filetype');
    Keys(idx) = [];
    Keys(end+1) = {'filetype'};
    KeyVals = orderfields(KeyVals, Keys);
end

Values = struct2cell(KeyVals);
Filename = cellfun(@(key, val) [key, '-', val], Keys, Values, 'UniformOutput', false);
Filename = [strjoin(Filename(1:end-1), '_'), '_', KeyVals.filetype];

end