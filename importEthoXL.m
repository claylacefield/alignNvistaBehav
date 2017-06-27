function [ethoTimeStruc] = importEthoXL(varargin)

% Clay 2016
% Imports Ethovision data 
% NOTE: makes a few assumptions about the TTL data represented in the
% Ethovision XL file, in order to find appropriate columns of data

if nargin == 0
    [filename, path] = uigetfile('.xlsx', 'Select Ethovision XL file');
    cd(path);
else
    filename = varargin{1};
end

data = xlsread(filename);

ethoTime = data(:,1);   % extract ethoTime data (probably first column)

% find columns for TTL data (based upon assumed characteristics)
ttlOffCol = intersect(find(isnan(data(1,:))), find(nansum(data,1)>1 & nansum(data,1)<1000));
putNumPulses = nansum(data(:,ttlOffCol));
ttlOnCol = intersect(find(data(1,:)==1), find(nansum(data,1)==putNumPulses & nansum(data,1)<1000));

% now use these to find event
ethoOutONind = find(data(:,ttlOnCol)==1);
ethoOutOFFind = find(data(:,ttlOffCol)==1);

% and save to output structure
ethoTimeStruc.filename = filename;
ethoTimeStruc.ethoTime = ethoTime;
ethoTimeStruc.ethoOutONind = ethoOutONind;
ethoTimeStruc.ethoOutOFFind = ethoOutOFFind;
