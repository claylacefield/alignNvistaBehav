function [behavNvSyncStruc] = alignNvBehav()

%% USAGE: [behavNvAlignStruc] = alignNvBehav();
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
% procNvistaGPIOsyncMat.m (clay) for Mosaic exported nVista GPIO
% (which calls) importNvistaGPIO.m (clay)
% importEthoXL.m (clay)
% nearestpoint.m (Mathworks Exchange)
% and
% processNVgpioPy.m (clay) for python exported nVista GPIO
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
    nvBehavOutOFFtime = nvGpSyncStruc.syncOffTimes;
    nvBehavOutONtime = nvGpSyncStruc.syncOnTimes;
    nvTimeSec = nvGpSyncStruc.nvTimeSec;
    
elseif ~isempty(strfind(ext,'.mat')) || ~isempty(strfind(ext,'.csv'))
    [nvGpSyncStruc] = procNvistaGPIOsyncMat(filename);
    nvFrInd = nvGpSyncStruc.nvFrInd;
    nvBehavOutOFFind = nvGpSyncStruc.nvBehavOutOFFind;
    nvBehavOutONind = nvGpSyncStruc.nvBehavOutONind;  % NOTE: this will leave out beginning of first pulse from Behav
    %nvDelay = nvGpSyncStruc.nvDelay;
    nvTimeSec = nvGpSyncStruc.nvTimeSec;
    nvBehavOutOFFtime = nvTimeSec(nvBehavOutOFFind);
    nvFrTimes = nvTimeSec(nvFrInd);
end


behavNvSyncStruc.nvFilename = nvGpSyncStruc.filename;


toc;

%% 2.) load and process behavior system data
[filename, path] = uigetfile('*.*', 'Select exported behavior (.xls for Ethovision, or .txt for MedAssoc)');
[noPath, behavBasename, ext] = fileparts(filename);
disp('Processing behavior signals'); tic;
behavNvSyncStruc.behavFilename = filename;
cd(path);

if strfind(ext,'.txt')
    system = 'medAssoc';
    [behavStruc] = procBehavMedAssoc(filename);
    ethoTime = behavStruc.behavTimeSec;
    ethoOutOFFtime = behavStruc.ttlOutOffTimes;
elseif ~isempty(strfind(ext,'.xlsx'))
    system = 'ethovision';
    [ethoTimeStruc] = importEthoXL(filename);
    ethoTime = ethoTimeStruc.ethoTime;  % ethovision time for each ethovision frame
    ethoOutONind = ethoTimeStruc.ethoOutONind;  % index of each TTL onset
    
    ethoOutOFFind = ethoTimeStruc.ethoOutOFFind;
    
    % sometimes etho doesn't capture end of last sync TTL pulse but nVista
    % does, so you have to cut this off
    if length(ethoOutOFFind)<length(nvBehavOutOFFtime)
        nvBehavOutOFFtime = nvBehavOutOFFtime(1:length(ethoOutOFFind));
    end
    
    
    
    ethFrNvTime = zeros(length(ethoTime),1); % initialize etho time vector
    ethFrNvTime(ethoOutOFFind) = nvBehavOutOFFtime; % assign frames at TTL OFF to nv times
    
end

behavNvSyncStruc.behavSystem = system;

%% 3.) align Etho with nVista
disp('Aligning Ethovision frames with nVista'); tic;

% fill in frame times between TTL OFF events
deo = diff(ethoOutOFFind); % number of frames between sync OFF pulses
for i=1:length(ethoOutOFFind)-1
    ethFrNvTime(ethoOutOFFind(i):ethoOutOFFind(i+1)) = linspace(nvBehavOutOFFtime(i),nvBehavOutOFFtime(i+1), deo(i)+1);
end

% now fill in first and last epochs based upon avg framerate
avIFI = mean(diff(ethFrNvTime(ethoOutOFFind(1):ethoOutOFFind(end))));

ethFrNvTime(ethoOutOFFind(1)-1:-1:1) = nvBehavOutOFFtime(1)-(avIFI*(1:(ethoOutOFFind(1)-1)));
%t = linspace(nvDelay/1000,nvEthoOutOFFtime(1), ethoOutOFFind(1));
ethFrNvTime(ethoOutOFFind(end)+1:end) = nvBehavOutOFFtime(end)+(avIFI*(1:(length(ethoTime)-ethoOutOFFind(end))));

behavNvSyncStruc.ethFrNvTime = ethFrNvTime; % save into output struc

%% 4.) Calc. nearest frames of nV/Etho to the other

[nrstNvFrToEthoInd, dist] = nearestpoint(ethFrNvTime,nvFrTimes, 'nearest');
[nrstEthoFrToNvInd, dist] = nearestpoint(nvFrTimes,ethFrNvTime, 'nearest');

behavNvSyncStruc.nrstNvFrToEthoInd = nrstNvFrToEthoInd;
behavNvSyncStruc.nrstEthoFrToNvInd = nrstEthoFrToNvInd;
toc;

%% also save nV/Etho strucs from which these were computed
behavNvSyncStruc.nvGpSyncStruc = nvGpSyncStruc;
behavNvSyncStruc.ethoTimeStruc = ethoTimeStruc;

%% and save to file
disp('Saving behavNvSyncStruc'); tic;
save(['behavNvSyncStruc_' date], 'behavNvSyncStruc');
toc;

