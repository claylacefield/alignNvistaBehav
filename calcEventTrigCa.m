function [eventCa, zeroInds] = calcEventTrigCa(ca, tCa, eventTimes, prePostSec)

%% USAGE: [eventCa, zeroInds] = calcEventTrigCa(ca, tCa, eventTimes, prePostSec);
% This is intended to be a general script for calculating an
% event-triggered calcium signal.
% INPUT:
% ca: a calcium timecourse (or actually any timecourse)
% tCa: a vector of times corresponding to calcium frames (in sec)
% eventTimes: array of event times (already in same timebase as ca)
% prePostSec: window pre/post event to excerpt calcium ( e.g. [10 30])

toPlot = 0;

% window for event triggered calcium signal extraction
preEvSec = prePostSec(1);
postEvSec = prePostSec(2);


% adjust ca frame times if downsampled
if length(tCa)/length(ca) > 1.5
   tCa = tCa(2:2:end); 
end

fps = round(1/mean(diff(tCa)));

preEvFr = round(preEvSec*fps); % samples before event to include in ca epoch
postEvFr = round(postEvSec*fps);

% NaN any eventTimes outside of imaging period (+/- pre/post)
eventTimes(eventTimes>(max(tCa)-postEvSec))= NaN;
eventTimes(eventTimes<(min(tCa)+preEvSec))= NaN;

%% extract calcium window around events
for evNum = 1:length(eventTimes)
    %try
        if ~isnan(eventTimes(evNum))
            evTime = eventTimes(evNum);
            [minVal, zeroInd] = min(abs(tCa-evTime));
            eventCa(:, evNum) = ca(zeroInd-preEvFr:zeroInd+postEvFr);
            zeroInds(evNum) = zeroInd;
        else
            eventCa(:, evNum) = NaN([length(-preEvFr:postEvFr) 1], 'single');
            zeroInds(evNum) = NaN;
        end
%     catch
%         disp(['Problem with event # ' num2str(evNum) ' of type ' eventName]);
%     end
end

%% plotting
try
    if toPlot
        figure;
        if size(eventCa,2)>1
            %plotMeanSEM(eventCa, 'b');
            plotMeanSEM(eventCa); %, 'b'); %[-preEvSec postEvSec]);
        elseif size(eventCa,2)==1
            plot(eventCa);
        end
        %title([treadBehStruc.tdmlName ' on ' date]);
    end
catch
    %eventCa = [];
    disp(['No events within recording period']);
end
