function [behavNvSyncStruc] = alignNvBehav()

%% USAGE: [ethoNvAlignStruc] = alignNvEtho2b();
% Clay
% Jan. 2017
% This function uses a new method for aligning the Ethovision
% frames with nVista frame times, based upon a TTL signal sent
% out from the Noldus IO box to the nVista GPIO#1 port.
% The timing of the TTL output is kind of inconsistent in 
% administration, as well as its attribution to a particular 
% Ethovision frame, so this method just creates a linearly spaced 
% time vector between each TTL OFF event. This is probably accurate
% to within a frame.
%
% Function calls:
% procNvistaGPIOsyncMat.m (clay)
% (which calls) importNvistaGPIO.m (clay)
% importEthoXL.m (clay)
% nearestpoint.m (Mathworks Exchange)
%
% OUTPUT:
% ethFrNvTime : vector of ethovision frame times with respect to nVista
% timebase
% nrstNvFrToEthoInd: vector of indices of nearest nVista frame for each
% Ethovision frame
% nrstEthoFrToNvInd: vector of indices of nearest Ethovision frame for each
% nVista frame
% 
% THUS to find a zeroFrame for any behav or Ca2+ event, find the number at
% the index of that event 
% EXAMPLE: If a behavioral event happens at Ethovision frame 1000, the
% nVista frame that corresponds to this will be nrstNvFrToEthoInd(1000)

%% 1.) load and process nv events

[filename, path] = uigetfile('*.*', 'Select exported nVista gpio (.csv, .mat, or .txt)');
[noPath, nvGpBasename, ext] = fileparts(filename);
disp(['Processing nVista signals for ' filename]); tic;

if strfind(ext,'.txt')
    [nvGpSyncStruc] = processNVgpioPy(filename);
    nvFrTimes = nvGpSyncStruc.nvFrTimes;
    nvBehavOutOFFtimes = nvGpSyncStruc.syncOffTimes;
    nvBehavOutONtimes = nvGpSyncStruc.syncOnTimes;
    
    
elseif ~isempty(strfind(ext,'.mat')) || ~isempty(strfind(ext,'.csv'))
    [nvGpSyncStruc] = procNvistaGPIOsyncMat(filename);
    nvFrInd = nvGpSyncStruc.nvFrInd;
    nvBehavOutOFFind = nvGpSyncStruc.nvBehavOutOFFind;
    nvBehavOutONind = nvGpSyncStruc.nvBehavOutONind;  % NOTE: this will leave out beginning of first pulse from Behav
    %nvDelay = nvGpSyncStruc.nvDelay;
end


behavNvSyncStruc.nvFilename = nvGpSyncStruc.filename;
nvTimeSec = nvGpSyncStruc.nvTimeSec;

toc;

%% 2.) load and process behavior system data
[filename, path] = uigetfile('*.*', 'Select exported behavior (.xls for Ethovision, or .txt for MedAssoc)');
[noPath, behavBasename, ext] = fileparts(filename);
disp('Processing behavior signals'); tic;
behavNvSyncStruc.behavFilename = filename;
cd path;

if strfind(ext,'.txt')
    system = 'medAssoc';
    [behavStruc] = procBehavMedAssoc(filename);
    ethoTime = behavStruc.behavTimeSec;
    ethoOutOFFtime = behavStruc.ttlOutOffTimes;
elseif strfind(ext,'.mat') || strfind(ext,'.csv')
    system = 'ethovision';
    [ethoTimeStruc] = importEthoXL(filename);
    ethoTime = ethoTimeStruc.ethoTime;  % ethovision time for each ethovision frame
    ethoOutONind = ethoTimeStruc.ethoOutONind;  % index of each TTL onset
    
    ethoOutOFFind = ethoTimeStruc.ethoOutOFFind;
    nvEthoOutOFFtime = nvTimeSec(nvEthoOutOFFind);
    
    ethFrNvTime = zeros(length(ethoTime),1); % initialize etho time vector
    ethFrNvTime(ethoOutOFFind) = nvEthoOutOFFtime; % assign frames at TTL OFF to nv times
    
end

behavNvSyncStruc.behavSystem = system;

%% 3.) align Etho with nVista
disp('Aligning Ethovision frames with nVista'); tic;

% fill in frame times between TTL OFF events
deo = diff(ethoOutOFFind); % number of frames between sync OFF pulses
for i=1:length(ethoOutOFFind)-1
    ethFrNvTime(ethoOutOFFind(i):ethoOutOFFind(i+1)) = linspace(nvEthoOutOFFtime(i),nvEthoOutOFFtime(i+1), deo(i)+1);
end

% now fill in first and last epochs based upon avg framerate
avIFI = mean(diff(ethFrNvTime(ethoOutOFFind(1):ethoOutOFFind(end))));

ethFrNvTime(ethoOutOFFind(1)-1:-1:1) = nvEthoOutOFFtime(1)-(avIFI*(1:(ethoOutOFFind(1)-1)));
%t = linspace(nvDelay/1000,nvEthoOutOFFtime(1), ethoOutOFFind(1));
ethFrNvTime(ethoOutOFFind(end)+1:end) = nvEthoOutOFFtime(end)+(avIFI*(1:(length(ethoTime)-ethoOutOFFind(end))));

behavNvSyncStruc.ethFrNvTime = ethFrNvTime; % save into output struc

%% 4.) Calc. nearest frames of nV/Etho to the other

[nrstNvFrToEthoInd, dist] = nearestpoint(ethFrNvTime,nvTimeSec(nvFrInd), 'nearest');
[nrstEthoFrToNvInd, dist] = nearestpoint(nvTimeSec(nvFrInd),ethFrNvTime, 'nearest');

behavNvSyncStruc.nrstNvFrToEthoInd = nrstNvFrToEthoInd;
behavNvSyncStruc.nrstEthoFrToNvInd = nrstEthoFrToNvInd;
toc;

%% also save nV/Etho strucs from which these were computed
behavNvSyncStruc.nvGpSyncStruc = nvGpSyncStruc;
behavNvSyncStruc.ethoTimeStruc = ethoTimeStruc;

%% and save to file
disp('Saving ethoNvAlignStruc'); tic;
save(['ethoNvAlignStruc_' date], 'ethoNvAlignStruc');
toc;

