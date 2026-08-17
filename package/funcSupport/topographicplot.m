function topographicplot(fpath, outpath, varargin)

CLim = nan;

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'clim'
            CLim = varargin{i+1};
    end
end

chanlocs = readlocs(which('GSN-HydroCel-257.sfp'));
incl = hdeeg_scalpchannels('egi257');
incl = ismember({chanlocs.labels}, incl);
chanlocs = chanlocs(incl);

CData = readtable(fpath, 'ReadVariableNames', false);
CData = CData{:,:};

dim_chan = find(size(CData) == length(chanlocs));
if dim_chan == 2
    CData = CData';
end

CData = mean(CData, 2, 'omitnan');

Fig = figure();
Ax = axes();
topoplot(CData, chanlocs, ...
    'style', 'map', ...
    'whitebk', 'on', ...
    'conv', 'on')
if isnan(CLim)
    Ax.CLim = [-1*max(abs(CData(:))), max(abs(CData(:)))];
else
    Ax.CLim = CLim;
end

drawnow();

colorbar();
CMap = load('colormap_roma.mat');
Ax.Colormap = CMap.roma;

exportgraphics(Fig, outpath, 'Resolution', 600)

end
