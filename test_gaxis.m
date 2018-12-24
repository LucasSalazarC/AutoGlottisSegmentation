load('testdata_gaxis.mat')
img = s(maxIdx).cdata;

% (x,y)
maxBorder = [];
for j = 1:length( outputContours{maxIdx} )
    maxBorder = [ maxBorder; outputContours{maxIdx}{j} ];
end

center = mean(maxBorder);
slope = gaxis(1) / gaxis(2);

lineErrors = maxBorder - round(center);
lineErrors = lineErrors(:,2) - slope * lineErrors(:,1);

% We try to find the border points that intersect the main glottal axis.
% These points will have lineError close to zero. To find them, we find the
% indexes where LineErrors changes sign

% We start checking the index with maximum error. This point will never be
% on the line so it's safe to start here
[maxVal, currentIdx] = max(lineErrors);
currentSign = sign( maxVal );

linePoints = [];
for i = 1:length(lineErrors)
    
    nextIdx = inc( currentIdx, length(lineErrors) );
    
    % Map 0 to 1, so that we can only have 1 or -1
    nextSign = sign( lineErrors(nextIdx) );
    if nextSign == 0
        nextSign = 1;
    end
    
    % Sign change! we found a line point
    if nextSign ~= currentSign
        % We have two options: the current point and the next. We add the
        % one closest to zero
        
        if abs( lineErrors(currentIdx) ) < abs( lineErrors(nextIdx) )
            linePoints(end+1,:) = maxBorder(currentIdx, :);
        else
            linePoints(end+1,:) = maxBorder(nextIdx, :);
        end
    end
    
    currentIdx = nextIdx;
    currentSign = nextSign;
end

% Find line points with highest and lowest y-axis value. Remember y-axis is
% inverted in the image
[~, highPointIdx] = min(linePoints(:,2));
[~, lowPointIdx] = max(linePoints(:,2));

axisPoints.high = linePoints(highPointIdx,:);
axisPoints.low = linePoints(lowPointIdx,:);
