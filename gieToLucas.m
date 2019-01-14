%% Read segmentation data from text file

addpath('./functions');

id = '2kPa - 0,02 shim';
vidName = [ id '.avi' ];
vidPath = '~/Videos/';
textFileName = ['GIE_segdata/' id '.txt'];
text_file = fopen( textFileName, 'r' );
lines = textscan(text_file, '%s', 'delimiter', '\n');
lines = lines{1};
fclose(text_file);

gieContours = {};

for i = 2:2:length(lines)
    if i == length(lines)
        continue
    end

    leftSide = str2num(lines{i})';
    rightSide = str2num(lines{i+1})';

    contour = [];

    % format: [x,y]
    for k = 1:256
        if leftSide(k) ~= 0
            contour(end+1,:) = [leftSide(k) k];
        end
    end
    for k = 256:-1:1
        if rightSide(k) ~= 0
            contour(end+1,:) = [rightSide(k) k];
        end
    end


    % Contour needs to be closed
    closedContour = [];

    for k = 1:length(contour)
        if ~isempty(closedContour) && ( abs(closedContour(end,1) - contour(k,1)) > 1 || abs(closedContour(end,2) - contour(k,2)) > 1 )
            [xb,yb] = bresenham(closedContour(end,1), closedContour(end,2), contour(k,1), contour(k,2));
            closedContour = [closedContour; [xb yb]];
        else
            closedContour(end+1,:) = [contour(k,1) contour(k,2)];
        end
    end

    % Join last point with first point
    if ~isempty(closedContour) && ( abs(closedContour(end,1) - closedContour(1,1)) > 1 || abs(closedContour(end,2) - closedContour(1,2)) > 1 )
        [xb,yb] = bresenham(closedContour(end,1), closedContour(end,2), closedContour(1,1), closedContour(1,2));
        closedContour = [closedContour; [xb yb]];
    end

    gieContours(end+1) = {closedContour};
        
end


%% Correct and reorder contours

% Also we calculate area
glottisAreas = zeros( length(gieContours), 1);

% Fill border
for i = 1:length( gieContours )
    currentBorder = gieContours{i};
    
    glottisBinImage = false( 256, 256 );
    for k = 1:length(currentBorder)
        cmm = max(currentBorder(k,2) + 1, 1);
        cmm = min(cmm, 256);
        cmn = max(currentBorder(k,1) + 1, 1);
        cmn = min(cmn, 256);
        glottisBinImage( cmm, cmn ) = true;
    end
    glottisBinImage = imfill(glottisBinImage, 'holes');
    
    glottisAreas(i) = sum(sum( glottisBinImage ));
    gieContours(i) = { bwboundaries( glottisBinImage ) };
end


outputContours = cell( length(gieContours), 1 );
for i = 1:length(gieContours)
    
    if ~isempty(gieContours{i})
        correctedBorders = {};
        
        if iscell( gieContours{i} )
            
            for j = 1:length( gieContours{i} )
                objectBorder = gieContours{i}{j};

                for k = 1:length(objectBorder)
                    objectBorder(k,1) = max(objectBorder(k,1), 1);
                    objectBorder(k,1) = min(objectBorder(k,1), 256);
                    objectBorder(k,2) = max(objectBorder(k,2), 1);
                    objectBorder(k,2) = min(objectBorder(k,2), 256);
                end

                correctedBorders(end+1) = { fliplr(objectBorder) };
            end
            
        else
            objectBorder = gieContours{i};

            for k = 1:length(objectBorder)
                objectBorder(k,1) = max(objectBorder(k,1), 1);
                objectBorder(k,1) = min(objectBorder(k,1), 256);
                objectBorder(k,2) = max(objectBorder(k,2), 1);
                objectBorder(k,2) = min(objectBorder(k,2), 256);
            end

            correctedBorders(end+1) = { fliplr(objectBorder) };
        end
        
        outputContours(i) = { correctedBorders };
    end
end


%% Save

vidMetaData = [];
vidMetaData.Height = 256;
vidMetaData.Width = 256;
vidMetaData.RealFrameRate = 10000;    % I actually don't know
vidMetaData.Name = vidName;
vidMetaData.Id = id;

vidObj = VideoReader( [vidPath vidName ] );

% Find frame with maximum glottal opening
[~,maxIdx] = max(glottisAreas);
vidObj.CurrentTime = (maxIdx - 1) / vidObj.FrameRate;
vidMetaData.ReferenceFrame = readFrame( vidObj );

%Save GIE contours in their own folder
if exist('GIE_contours/', 'dir') ~= 7
    mkdir('GIE_contours')
end

save(strcat('GIE_contours/', id, '.mat'), 'outputContours', 'glottisAreas', 'vidMetaData');

