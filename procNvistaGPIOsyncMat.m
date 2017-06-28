function [nvGpSyncStruc] = procNvistaGPIOsyncMat(varargin)

% Clay 2016
% This function imports an nVista GPIO file, saved as .csv from Mosaic,
% then finds frame times (in ms) and event times on all GPIO ports.
% Results are output as structure.

if nargin==0
[filename, path] = uigetfile('*.*', 'Select nVista GPIO file (.csv or Gpio1.mat)');
cd(path);
else
    filename = varargin{1};
end

% import nVista GPIO
[nvGpioStruc] = importNvistaGPIO(filename);

syncBin = nvGpioStruc.syncBin;
gpio1bin = nvGpioStruc.gpio1bin;
nvTimeSec = nvGpioStruc.nvTimeSec;

nvGpSyncStruc.filename = nvGpioStruc.filename;

if syncBin(1) == 1
    nvFrInd = [1 find(diff(syncBin)==1)+1]; % get nVista frame ind
else
    nvFrInd = find(diff(syncBin)==1)+1;
end

nvBehavOutOFFind = find(diff(double(gpio1bin))==-1)+1;   % find GPIO 1 event times (in ms)

nvBehavOutONind = find(diff(gpio1bin)==1)+1; % if nVista starts during first pulse, won't include this ON

% gp2evTimes = find(diff(gpio2bin)==1);

% extTrigTimes = find(diff(extBin)==1);
% if extBin(1) == 1
%    extTrigTimes = [0; extTrigTimes];    % if extTrig HIGH at beginning, add this time 
% end

nvGpSyncStruc.nvTimeSec = nvTimeSec;
nvGpSyncStruc.nvFrInd = nvFrInd;
nvGpSyncStruc.nvFrTimes = nvTimeSec(nvFrInd);
nvGpSyncStruc.nvBehavOutOFFind = nvBehavOutOFFind;
nvGpSyncStruc.nvBehavOutONind = nvBehavOutONind;
% nvGpStruc.gp2evTimes = gp2evTimes;
% nvGpStruc.extTrigTimes = extTrigTimes;

nvGpSyncStruc.nvDelay = 1033-nvBehavOutOFFind(1); % NOTE: this may differ so isn't a great measure

nvGpSyncStruc.nvGpioStruc = nvGpioStruc;