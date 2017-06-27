function [nvGpioStruc] = importNvistaGPIO(varargin)

% Clay 111716
% 
if length(varargin)==0
[filename, path] = uigetfile('*.*', 'Select nVista GPIO file (.csv or Gpio1.mat)');
cd(path);
else
    filename = varargin{1};
end
    
if strfind(filename, '.csv')
%     fid = fopen(filename);
%     colNames = textscan(fid, '%s', 5, 'Delimiter', ',');
%     data = textscan(fid, '%f %u8 %u8 %u8 %u8', 'Delimiter', ',');
%     fclose(fid);
data = readTable;
    nvTimeSec = data{:,1};
    gpio1bin = data{:,2};
    syncBin = data{:,4};
    clear data;
elseif strfind(filename, '.mat')
    gpio1 = load(filename);
    gpio1bin = gpio1.Object.Data';
    nvTimeSec = gpio1.Object.XVector;
    sync = load('Obj_4 - Sync.mat');
    syncBin = sync.Object.Data';
    clear gpio1 sync;
end

nvGpioStruc.filename = filename;
nvGpioStruc.nvTimeSec = nvTimeSec;
nvGpioStruc.gpio1bin = gpio1bin;
nvGpioStruc.syncBin = syncBin;


