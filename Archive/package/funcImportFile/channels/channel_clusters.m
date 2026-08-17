function chanlocs = channel_clusters(chanlocs, DataType)

switch lower(DataType)
    case 'mff'
        clusters = readtable('egi256_clusters.csv');
    case 'compu257'
        clusters = readtable('neuvo256_clusters.csv');
    otherwise
        for i = 1:length(chanlocs)
            if ~strcmpi(chanlocs(i).type, 'EEG')
                continue
            end
            chanlocs(i).cluster = 1;
        end
        return
end

for i = 1:length(chanlocs)
    idx = strcmpi(chanlocs(i).labels, clusters.chan);
    chanlocs(i).cluster = clusters.cluster(idx);
end
