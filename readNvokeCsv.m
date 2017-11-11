function [nvokeGpioStruc] = readNvokeCsv()

% Select and read in a meta_decode.py exported nVoke CSV file
% (see email with description of exported data from Inscopix, at bottom)
% Clay 2017

%% read data
filename = uigetfile('.csv');  % select CSV file

dataTable = readtable(filename);    % read CSV as MATLAB table
dataCell = table2cell(dataTable);   % now convert to cell array

%% specify all possible event types
eventNameCell = {'SYNC', 'EX LED', 'TRIG', 'OG LED', 'GPIO1', 'GPIO2'};

exLedActs = {'On', 'Off'}; 
ogLedActs = {'Ramp Up', 'On', 'Ramp Down', 'Off'};
syncActs = {'High', 'Low'}; 
trigActs = {'High', 'Low'}; 
gpio1Acts = {'High', 'Low'}; 
gpio2Acts = {'High', 'Low'};

%% Parse data array
tic;
disp(['Reading all expected nVoke event types from: ' filename]);
% for all event types
for i = 1:length(eventNameCell)
    eventName = eventNameCell{i};
    
    % find row inds of this event
    evRowInds = find(~cellfun('isempty', strfind(dataCell(:,1), eventName)));
    evTimes = [dataCell{evRowInds,4}]';
    
    if i == 1
        startTime = evTimes(1);
        evActions = syncActs;
    elseif i == 2
        evActions = exLedActs;
    elseif i==3
        evActions = trigActs;
    elseif i == 4
        evActions = ogLedActs;
    elseif i==5
        evActions = gpio1Acts;
    elseif i==6
        evActions = gpio2Acts;
    end
    
    evTimes = evTimes-startTime; % computes time relative to start
    
    evCell = dataCell(evRowInds,3); % extract action type column
    
    % find inds for all action types for an input/event
    for j = 1:length(evActions)
        evActionRowInds{j} = find(~cellfun('isempty', strfind(evCell, evActions(j))));
    end
    
    % and save them into the appropriate event type
    if i == 1
        nvokeGpioStruc.nvFrTimes = evTimes(evActionRowInds{1});
    elseif i==2
        nvokeGpioStruc.exLedTimes = evTimes(evActionRowInds{1});
    elseif i==3
        nvokeGpioStruc.trigOnTimes = evTimes(evActionRowInds{1});
    elseif i==4
        nvokeGpioStruc.ogRampUpTimes = evTimes(evActionRowInds{1});
        nvokeGpioStruc.ogOnTimes = evTimes(evActionRowInds{2});
        nvokeGpioStruc.ogRampDownTimes = evTimes(evActionRowInds{3});
        nvokeGpioStruc.ogOffTimes = evTimes(evActionRowInds{4});
    elseif i==5
        nvokeGpioStruc.syncOnTimes = evTimes(evActionRowInds{1});
        nvokeGpioStruc.syncOffTimes = evTimes(evActionRowInds{2});
    elseif i==6
        nvokeGpioStruc.gpio2OnTimes = evTimes(evActionRowInds{1});
        nvokeGpioStruc.gpio2OffTimes = evTimes(evActionRowInds{2});
    end
    
end
toc;




%%%%%%%%%%%%%%%%%%%%
% (email from Lara/Inscopix on 5/17/17)
% To run the attached script (meta_decode.py), please do the following:
% 1. Open up the command prompt (cmd.exe).
% 2. Copy the directory path of your nVoke install directory (for example, C:\Program Files\Inscopix\nVoke)
% 3. In the command prompt, type “cd [RIGHT CLICK TO PASTE YOUR DIRECTORY LOCATION HERE]” and hit enter. Don’t include quotation marks or brackets – just remember to right-click to paste.
% 4. In the command prompt, type “env.bat” and hit enter. You should see a large block of text on your screen. This is normal.
% 5. Put the meta_decode.py script in the same location as the GPIO file you want to convert.
% 6. Copy the directory path where the meta_decode.py script and GPIO file are saved.
% 7. In the command prompt, type “cd [RIGHT CLICK TO PASTE YOUR DIRECTORY LOCATION HERE]” and hit enter.
% 8. In the command prompt, type “python meta_decode.py [INSERT NAME OF GPIO FILE HERE] output” and hit enter.
% CSV File Column Headers – the list shown below are the headings for the columns in the CSV file
% The Running Counter rolls over at 255
% Seconds are total seconds from January 1, 1970 (UTC)
% Absolute accuracy depends upon the time of the PC when nVista was launched
% Relative time is accurate to 1 microsecond
% Power is only relevant to EX LED and OG LED in 0.1 * mW/mm^2
% GPIO Follow/Trigger
% Only relevant to OG LED
% Only relevant in GPIO Trigger or GPIO Follow mode
% Describes which GPIO was used to trigger OG LED event (0 = GPIO1, 1 = GPIO2, 2 = GPIO3, 3 = GPIO4)
% To get your timestamps in relation to the start of the calcium recording, you can subtract each GPIO time stamp from the first SYNCH timestamp. If you scroll down in your excel file, you should see the sync timestamps following the GPIO timestamps. The first SYNCtimestamp is the timestamp for the start of the session.
% Let me know how that works for you and we look forward to hearing more about your work with nVoke :)
% Cheers,
% Lara

%% NOTE: Clay 11/09/2017
% To run meta_decoder.py, use Anaconda/Spyder (it has the correct python
% packages)
% Open command prompt (Tools>Open command prompt)
% "python meta_decode.py inputFilename outputFilename(no .csv)"
% Then output will be .csv (not the "analog" one- it doesn't seem to have
% any data)