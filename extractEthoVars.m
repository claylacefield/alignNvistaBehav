function [ethoStruc] = extractEthoVars()

% Clay 2017
% Reads in all relevant variables from an Ethovision XL file
% (written based upon Brad and Grace's EPM data)

% NOTE: I think this has to be run on computer with Excel in order for this
% to work, otherwise you can't use indexing within xlsread

[filename, path] = uigetfile('.xlsx', 'Select .XL file to process');
cd(path);
tic;

%% find num header lines
[num, txt, raw] = xlsread(filename, 1, 'B1');
headerLines = str2num(txt{1});

% find all column names (max = 26, A-Z)
[num, colNames, raw] = xlsread(filename, 1, ['A' num2str(headerLines-1) ':Z' num2str(headerLines-1)]);

% read in numerical data
allCol = xlsread(filename);

begFr = 60*30;

%% now extract all necessary vars (make first frames NaN)
ethFrTimes = allCol(:,1);
xPos = allCol(:,3); xPos(1:begFr) = NaN;
yPos = allCol(:,4); yPos(1:begFr) = NaN;
vel = allCol(:,9); vel(1:begFr) = NaN;
inOpen = allCol(:,15); inOpen(1:begFr) = NaN;
inClosed = allCol(:,16); inClosed(1:begFr) = NaN;

%% fill in missing values (bad tracking?)
xPos = fillmissing(xPos, 'linear');
yPos = fillmissing(yPos, 'linear');
vel = fillmissing(vel, 'linear');
inOpen = fillmissing(inOpen, 'linear');
inClosed = fillmissing(inClosed, 'linear');

% and zero negative velocities
vel(vel<0) = 0;

toc;

%% save into output structure
ethoStruc.filename = filename;
ethoStruc.ethFrTimes = ethFrTimes;
ethoStruc.xPos = xPos;
ethoStruc.yPos = yPos;
ethoStruc.vel = vel;
ethoStruc.inOpen = inOpen;
ethoStruc.inClosed = inClosed;

figure; hold on;
plot(ethoStruc.ethFrTimes, ethoStruc.inClosed*200, 'r');
plot(ethoStruc.ethFrTimes, ethoStruc.inOpen*250, 'g');
plot(ethoStruc.ethFrTimes, ethoStruc.vel);
legend('inClosed', 'inOpen', 'vel');
xlabel('sec');
