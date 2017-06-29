function [nvGpSyncStruc] = processNVgpioPy(varargin) % time, sync, io1) % (pyGpioStruc)

% Clay 2017
% This is a function to take output from the export_gpio.py script from
% Inscopix, and to process nVista frame times and med associates sync signals (io1).
% First: run from cmd
% python export_gpio.py --sync --trigger --io1 --io2 inFilename outTxtFilename
% and this will output a text file to select in this script

% This is a bit tricky because of the way that the signals are represented
% in the TXT file output by the python script. Basically, the signals are
% only recorded when there is a change in any of the input signals, and
% this is given a timestamp. This can be a frame change, trigger, or any
% input signal. Here are a few notes on this:
% 1.) While frame tells the frame number (since the system is started, not
% from the beginning of actual capture), the sync signal is not "1" on the
% first row for that frame, but the second
% [2.) Time is represented from the system time, so you have to subtract the
% first time from the time array to get the time relative to the start
% time] NOTE: I don't think this is true anymore...
% 3.) Time is in secs.
% 4.) Using this method, the nVista frame times show more variation than if
% one used the CSV export from Mosaic. So they either process this frame
% data differently or they regularize this when exporting.

if nargin==0
[filename, path] = uigetfile('.txt', 'Select TXT file of Python exported nVista gpio');
else
    filename = varargin{1};
    path = [pwd '\'];
end

disp(['Reading data for ' filename]); tic;
dataTable = readtable([path filename]); % read in data as a table (index like cell array)
%toc;

disp('Processing signals'); %tic;
% read in event arrays
frames = dataTable{:,1}; frames = frames - frames(1)+1; % frame number for each event
time = dataTable{:,2};  % time for each event (of whatever type)
sync = dataTable{:,3};  % frame trigger (0 to 1 for frame start, 1 to 0 for frame stop)
trig = dataTable{:,4};  % session trigger (high from onset, stops a few events before the end)
io1 = dataTable{:,5};   % similarly for GPIO#1/TTL behav sync signal
io2 = dataTable{:,6};

% NOTE: events are represented in a weird way in the nvista file-
% Basically, anytime a signal changes (of whatever sort) the time (and
% frame) of that event is logged with the change (e.g. 0 to 1, signal goes
% on or off, or frame changes).
% BUT: a few things remain unknown
% 1.) sometimes sync/frameTrig goes low at end and doesn't have trigger,
% even though there is a frame number listed, so I don't know whether this
% frame is actually captured, and I'm not currently assigning it a time
% 2.) the behav sync signal sometimes goes low at the end but I don't know
% if this is because it really goes low, or nVista stops acquiring it

t1 = time;%-time(1); % subtract first time to have adjusted time array (event based)
frInds = find(diff(sync)==1)+1; % find indices of frame trigger pulses
%frInds = [1; frInds];
frTimes = t1(frInds);   % then use these indices to find the times of these events

%% Find sync pulses (from behav system, e.g. Ethovision, MedAssoc, or arduino)
syncOnInds = find(diff(io1)==1)+1; % find onsets of negative-going MedAssoc sync
syncOffInds = find(diff(io1)==-1)+1;

syncOnTimes = t1(syncOnInds);   % and then the times
syncOffTimes = t1(syncOffInds);

syncOnFrames = frames(syncOnInds);   % and frames
syncOffFrames = frames(syncOffInds);

%%
try
    io2OnInds = find(diff(io2)==1)+1; %LocalMinima(diff(io1), 50, -0.5)+1;  % find onsets of negative-going MedAssoc sync
    io2OffInds = find(diff(io2)==-1)+1;
    
    io2OnTimes = t1(io2OnInds);   % and then the times
    io2OffTimes = t1(io2OffInds);
    
    io2OnFrames = frames(io2OnInds);   % and frames
    io2OffFrames = frames(io2OffInds);
catch
    disp('No signal on io2');
end

toc;

%% put stuff into output structure
nvGpSyncStruc.filename = filename;
nvTimeSec = 0:0.001:time(end);
nvGpSyncStruc.nvTimeSec = nvTimeSec';
nvGpSyncStruc.nvFrTimes = frTimes;

nvGpSyncStruc.syncOnTimes = syncOnTimes;
nvGpSyncStruc.syncOffTimes = syncOffTimes;
nvGpSyncStruc.syncOnNvFrames = syncOnFrames; % frame number for each TTL event
nvGpSyncStruc.syncOffNvFrames = syncOffFrames;

try
    nvGpSyncStruc.io2OnTimes = io2OnTimes;
    nvGpSyncStruc.io2OffTimes = io2OffTimes;
    nvGpSyncStruc.io2OnNvFrames = io2OnFrames;
    nvGpSyncStruc.io2OffNvFrames = io2OffFrames;
catch
    nvGpSyncStruc.io2OnTimes = [];
    nvGpSyncStruc.io2OffTimes = [];
    nvGpSyncStruc.io2OnNvFrames = [];
    nvGpSyncStruc.io2OffNvFrames = [];
end


