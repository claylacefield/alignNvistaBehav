function [behavStruc] = procBehavMedAssoc(varargin)

% Clay Jun.27, 2017
% (originally from Final_FP_MedPC_analysis_20170108.m, but changed greatly 041817)
% 170627: this is now a general MedAssoc data parsing script
% This script reads in a TXT file of MedAssociates data for GoNogo Operant
% tasks in conjunction with fiber photometry recording of calcium signals
% in mouse brain.
% Outputs a structure of times of desired events (in sec).


% select file to process
if nargin == 0
    [filename, path] = uigetfile('.txt', 'Select TXT file of MedAssoc data to process');
else
    filename = varargin{1};
    path = pwd;
end
cd path;

behavStruc.txtFilename = filename;
behavStruc.txtPath = path;
behavStruc.system = 'medAssoc';

disp(['Processing MedAssoc behavior data for operant data file: ' filename]);
tic;

% Define names and codes for events (comment lines for ones you don't want)
codeArr = {...
    'levInTimes', '0028';... % RLevOnCode
    'levOutTimes', '0030';... % RLevOffCode
    'pressTimes', '1016';... % RPressOnCode
    % 'pressOffTimes', '1018';... % RPressOff
    'dipInTimes', '0025';... % DipOn
    'dipOutTimes', '0026';... % DipOff
    'pokeTimes', '1011';...
    'corrGoTimes', '1111';...
    'corrNogoTimes', '1110'}; % Nosepoke
      
% Import MedPCIV data
dataTable = readtable([path filename]); % (strcat(medpciv_folder,'/',medpciv_filename));
codes = dataTable{13:end,2}; % only keep codes column, and cut off header lines
s = size(codes);
numEvents = s(1);
code = cell(numEvents,1);

% Get time of events; MedPC-IV time resolution is 5ms
old_time = zeros(numEvents,1);
for evNum = 1:numEvents
    currCode = codes{evNum}; % extract current full code
    old_time(evNum) = str2double(currCode(1:end-4));    % and get time (in ms)
    code{evNum} = currCode(end-3:end);
end

%Subtract out initial time such that first events occur at time=0
times = old_time - old_time(1); 
times = times/1000;  % convert to sec
%behavStruc.times = times; % don't need to output all event times

%% % % % Create arrays containing events and their corresponding times

for numCode = 1:size(codeArr,1)
    evName = codeArr{numCode,1};
    evRows = find(ismember(code, codeArr(numCode,2)));
    evTimes = times(evRows);
    behavStruc.(evName) = evTimes;
end
    
toc;

