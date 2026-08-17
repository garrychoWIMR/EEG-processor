function FuncManualImport(Subject,Session,Task,RunNumber,FilePath,GeoscanType,GeoscanPath,SavePath)
% KEY-VALS
Import.Subject = Subject;
Import.Session = Session;
Import.Task = Task;
Import.Run = RunNumber;

% INPUT DATA FILE
Import.FileType = 'EEG';
Import.DataFile.Type = 'MFF'; % choose from 'MFF', 'COMPU257', 'GRAEL'
Import.DataFile.Path = FilePath;
Import.SourceFileType = 'MFF'; % choose from 'MFF', 'COMPU257', 'GRAEL'
Import.SourceFilePath = FilePath;
% CHANNEL LOCATIONS
Import.Channels.Type = GeoscanType; % Choose from 'Geoscan', 'GSN-HydroCel-257', 'Compumedics-257'
Import.Channels.Path = GeoscanPath;
% EVENTS
Import.Events.Do = false;
Import.Events.HypnoPath = '';
Import.Events.EventsPath = '';
Import.Events.WonambiXMLPath = '';
% PROCESSING
Import.Processing.DoResample = false;
Import.Processing.DoFilter = true;
Import.Processing.FilterSettings.DoBandpass = true;
Import.Processing.FilterSettings.DoNotch = true;
Import.Processing.FilterSettings.Highpass = 0.1;
Import.Processing.FilterSettings.Lowpass = 60;
Import.Processing.FilterSettings.Notch = 50;
Import.Processing.FilterSettings.WindowType = 'Hamming';
Import.Processing.FilterSettings.TransitionBW = 0.2;
Import.Processing.FilterSettings.FilterOrder = 8250;
Import.Processing.DoSpectrogram = false;
Import.Processing.DoICA = false;
% SAVE AS
Import.TargetFilePath = SavePath;
Import.TargetFileType = 256;
Import.SaveAs.Type = 256;
Import.SaveAs.Path = SavePath;
% --------------------------------------------------
% RUN IMPORT
[~, fname] = fileparts(Import.DataFile.Path);
fprintf('>> ==============================\n')
fprintf('>> BIDS: IMPORTING ''%s''\n', fname)
[~, ~, Warnings] = ImportFile(Import);
end
