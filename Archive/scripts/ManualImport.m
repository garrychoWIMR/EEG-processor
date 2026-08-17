%%



mff_files=dir('V:\From RDS 2022\2. Substudy - HDEEG\1.EEG Files - RAW Data\*\*\labwind*N1*.mff');
rawdatapath='U:\rawdata';

for i=10:length(mff_files)
try 
    if i==4 || i==7
        continue
    end
    sourcename=[mff_files(i).folder,filesep,mff_files(i).name];
    KeyVals_manual=strsplit(mff_files(i).name,'_');
    switch KeyVals_manual{3}
        case 'V1N1'
            ses='1';
        case 'V2N1'
            ses='2';
        case 'V3N1'
            ses='3';
    end
    sub_name=lower(KeyVals_manual{2});
    hypnogramfile=dir([mff_files(i).folder,filesep,'*hypnogram*.txt']);
    new_fname=sprintf('sub-%s_ses-%s_task-psg_run-1_eeg.set',sub_name,ses);
        
    % KEY-VALS
    Import.Subject = sub_name;
    Import.Session = ses;
    Import.Task = 'psg';
    Import.Run = 1;
    Import.Auth='';
    % INPUT DATA FILE
    Import.FileType = 'EEG';
    Import.SourceFileType = 'MFF'; % choose from 'MFF', 'COMPU257', 'GRAEL'
    Import.SourceFilePath = sourcename;
    Import.DataFile.Type = 'MFF'; % choose from 'MFF', 'COMPU257', 'GRAEL'
    Import.DataFile.Path = sourcename;

    % CHANNEL LOCATIONS
    Import.Channels.Type = 'S:\Sleep\SleepSoftware\EEG_Processor\develop\package\defaults\GSN-HydroCel-257.sfp'; % Choose from 'Geoscan', 'GSN-HydroCel-257', 'Compumedics-257', or 'Nomenclature'
    Import.Channels.Path = '';
    % EVENTS
    Import.Events.Do = false;
    Import.Events.HypnoPath = [hypnogramfile.folder,filesep,hypnogramfile.name];
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
    Import.TargetFileType = 256;
    Import.TargetFilePath = [rawdatapath,filesep,'sub-',sub_name,filesep,'ses-',ses,filesep,new_fname];
    % --------------------------------------------------
    % RUN IMPORT
    [~, fname] = fileparts(Import.DataFile.Path);
    fprintf('>> ==============================\n')
    fprintf('>> BIDS: IMPORTING ''%s''\n', fname)
    [ArgOut, Next, Warnings] = ImportFile(Import);

catch ME
    disp(ME.message)
    keyboard
end
end
