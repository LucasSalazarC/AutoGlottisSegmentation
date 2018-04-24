clear

% Suppress JavaFrame warning
id = 'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame';
warning('off', id);

% Open and read video data
vidName = "MN002";
vidPath = "C:\Users\lucassalazar12\Videos\DSP\";
vidObj = VideoReader(char(vidPath + vidName + ".avi"));
%vidObj = VideoReader('C:\Users\lucassalazar12\Dropbox\USM\2017_2\IPD414 - Seminario DSP\Proyecto\Videos segmentados\Mal\seg_FN003.avi');
vidHeight = vidObj.Height;
vidWidth = vidObj.Width;
s = struct('cdata',zeros(vidHeight,vidWidth,3,'uint8'),'colormap',[]);

%mkdir(char(vidPath + vidName));
correctBorders = {};


% States
sDrawing = 1;
sEditing = 2;
sAdding = 3;

% Button ascii
spacebar = 32;
wkey = 119;
skey = 115;
rkey = 114;
ckey = 99;
ekey = 101;
dkey = 100;
akey = 97;
key1 = 49;
key2 = 50;
lclick = 1;
rclick = 3;
enterkey = -1;

% Persistent variables:

% This array contains all drawn points in format (x,y). The third column is 1 if the point is a 
% starting point. Otherwise it is 0. It can persist from one frame to the next.
points(1,1) = pPoint;

% Cell to save border segments. Can persist between frames.
lines(1,1) = pLine;

% Stores pressed keys
button = NaN;

% Plot zoom level
zlevel = 1;

k = 1;
vidObj.CurrentTime = 0;
s(k).cdata = readFrame(vidObj);         % Video frames
while k <= 10
    figure(1); image(s(k).cdata); axis image; hold on
    pause(0.1);
    
    % Maximize image
    fig = gcf;
    jFrame = get(handle(fig), 'JavaFrame');
    jFrame.setMaximized(1);

    % Variables needed for zoom
    ax = gca;
    outerpos = ax.OuterPosition;
    ti = ax.TightInset; 
    bottom = outerpos(2) + ti(2);
    ax_height = outerpos(4) - ti(2) - ti(4);
    ax.Position = [outerpos(1) bottom outerpos(3) ax_height];

    
    
    
    % Only one starting point for each closed border. Resets when a border
    % is closed, and is set when a new border begins.
    startingPoint = [];
    
    % activePoint is set to last drawn point, unless said point is the
    % startingPoint. It resets when a border is closed.
    activePoint = [];
    
    % Only for editing mode. It is reset each time editing mode is enabled.
    editingPoint = [];
    
    % Initial state
    state = sDrawing;
    
    % Draw points and lines from previous image, if they were kept.
    if button == key1 || button == key2
        for i = 1:length(points)
            if points(i).isStartingPoint
                plot(points(i).XData, points(i).YData, 'co', 'MarkerSize', 4*zlevel)
            else
                plot(points(i).XData, points(i).YData, 'go', 'MarkerSize', 4*zlevel)
            end
            c = get(gca,'children');
            points(i).point = c(1);
        end
        for i = 1:length(lines)
            plot(lines(i).XData, lines(i).YData, 'y*', 'MarkerSize', 2*zlevel)
            c = get(gca,'children');
            lines(i).line = c(1);
        end
    end
    
    % Reset zoom variables
    zoom_scale = 1.5;
    zlevel = 1;

    while true
        [x,y,button] = ginput(1);
        x = round(x); y = round(y);
        if isempty(button) % Enter key
            button = enterkey;
        end
        
        %borderNotClosed = ~isempty(activePoint) && ( abs(activePoint.XData-startingPoint.XData) > 1 || abs(activePoint.YData-startingPoint.YData) > 1 );
        borderNotClosed = ~isempty(activePoint) && ( isempty(activePoint.followingLine) || ~isvalid(activePoint.followingLine) );
        
        % The following actions are independent of state
        
        % Continue to next image. Close border
        if button == spacebar || button == enterkey || button == key1 || button == key2
            if borderNotClosed
                [xb,yb] = bresenham(activePoint.XData, activePoint.YData, startingPoint.XData, startingPoint.YData);
                plot(xb,yb, 'y*', 'MarkerSize', 2*zlevel)
                
                % FIX THIS. Save all points and lines.
                c = get(gca,'children');
                lines(end+1) = pLine(c(1), activePoint, startingPoint);
                
                % Assign trailing and following points/lines
                points(end).followingLine = lines(end);
                points(end).followingPoint = startingPoint;
                points(end).isEndingPoint = true;
                startingPoint.trailingLine = lines(end);
                startingPoint.trailingPoint = points(end);
            end
            
            activePoint = [];
            startingPoint = [];
            break
            
        % Redo image. Discard borders
        elseif button == rkey  
            break
            
        % Zoom out
        elseif button == skey
            ax = axis; width=ax(2)-ax(1); height=ax(4)-ax(3);
            axis([x-width/2 x+width/2 y-height/2 y+height/2]);
            zoom(1/zoom_scale);
            zlevel = zlevel / zoom_scale;

        % Zoom in
        elseif button == wkey
            ax = axis; width=ax(2)-ax(1); height=ax(4)-ax(3);
            axis([x-width/2 x+width/2 y-height/2 y+height/2]);
            zoom(zoom_scale);  
            zlevel = zlevel * zoom_scale;
        end
        
        
        % State actions
        
        if state == sDrawing
            
            % Close current border. Begin new border in same figure
            if button == ckey
                if borderNotClosed
                    [xb,yb] = bresenham(activePoint.XData, activePoint.YData, startingPoint.XData, startingPoint.YData);
                    plot(xb,yb, 'y*', 'MarkerSize', 2*zlevel)
                    
                    c = get(gca,'children');
                    lines(end+1) = pLine(c(1), activePoint, startingPoint); 
                    
                    % Assign trailing and following points/lines
                    points(end).followingLine = lines(end);
                    points(end).followingPoint = startingPoint;
                    points(end).isEndingPoint = true;
                    startingPoint.trailingLine = lines(end);
                    startingPoint.trailingPoint = points(end);
                end
                startingPoint = [];
                activePoint = [];

            % Draw line to next vertex. Starting points in cyan, the rest in green
            elseif button == lclick  
                if isempty(startingPoint)
                    plot(x, y, 'co', 'MarkerSize', 4*zlevel)
                    c = get(gca,'children');
                    startingPoint = pPoint(c(1), true);
                    if length(points) == 1
                        points(1) = startingPoint;
                    else
                        points(end+1) = startingPoint;
                    end
                else
                    [xb,yb] = bresenham(points(end).XData, points(end).YData, x, y);
                    plot(xb,yb, 'y*', 'MarkerSize', 2*zlevel)
                    plot(x, y, 'go', 'MarkerSize', 4*zlevel)
                    
                    c = get(gca,'children');
                    
                    activePoint = pPoint(c(1), false);
                    
                    if length(points) == 1
                        lines(1) = pLine(c(2), points(end), activePoint);
                    else
                        lines(end+1) = pLine(c(2), points(end), activePoint);
                    end
                    
                    % Assign following and trailing points/lines
                    activePoint.trailingPoint = points(end);
                    activePoint.trailingLine = lines(end);
                    points(end).followingPoint = activePoint;
                    points(end).followingLine = lines(end);
                    points(end+1) = activePoint;
                end


            % Delete last point and line    
            elseif button == rclick
                if points(end).isStartingPoint
                    % Active point should be already empty
                    startingPoint = [];

                    delete(points(end));
                    points = points(1:end-1);
                    unplot
                elseif length(points) > 1
                    % We just closed a border, or just deleted a starting point.
                    if isempty(startingPoint)
                        % Reassign startingPoint to previous starting point
                        for n = length(points)-1:-1:1
                            if points(n).isStartingPoint
                                startingPoint = points(n);
                                break
                            end
                        end    

                        % If border was closed by a point
                        if isempty(points(end).followingLine) || ~isvalid(points(end).followingLine)
                            % Delete a point and a line
                            delete(points(end));
                            points = points(1:end-1);
                            delete(lines(end));
                            lines = lines(1:end-1);
                            unplot(2);
                        % If border was closed by a line
                        else
                            % Delete a line only
                            delete(lines(end));
                            lines = lines(1:end-1);
                            unplot;
                        end
                        
                        activePoint = points(end);
                    else
                        % If next point is an active point
                        if points(end-1).isStartingPoint
                            activePoint = [];
                        % If not, reassign active point.
                        else
                            activePoint = points(end-1);
                        end
                        
                        % Delete a point and a line
                        delete(points(end));
                        points = points(1:end-1);
                        delete(lines(end));
                        lines = lines(1:end-1);
                        unplot(2)
                    end
                end
            end
            
        elseif state == sEditing
            if button == lclick
                % Select a point
                if isempty(editingPoint)
                    pointIdx = findPoint(points, x, y);
                    if pointIdx ~= 0
                        editingPoint = points(pointIdx);
                        set(editingPoint.point, 'Color', 'magenta');
                    end
                % Move point
                else                
                    editingPoint.movePoint(x,y);
                    
                    if editingPoint.isStartingPoint
                        set(editingPoint.point, 'Color', 'cyan');
                    else
                        set(editingPoint.point, 'Color', 'green');
                    end
                    
                    % Check if trailing line exists; if it does, change it.
                    if ~isempty(editingPoint.trailingLine) && isvalid(editingPoint.trailingLine)
                        [xb,yb] = bresenham(editingPoint.trailingPoint.XData, editingPoint.trailingPoint.YData, ...
                                    editingPoint.XData, editingPoint.YData);
                        editingPoint.trailingLine.moveLine(xb, yb);
                    end
                    % Same for following line
                    if ~isempty(editingPoint.followingLine) && isvalid(editingPoint.followingLine)
                        [xb,yb] = bresenham(editingPoint.XData, editingPoint.YData, ...
                                     editingPoint.followingPoint.XData, editingPoint.followingPoint.YData);
                        editingPoint.followingLine.moveLine(xb, yb);
                    end
                    
                    editingPoint = [];
                end
            end
            
        elseif state == sAdding
            if button == lclick
                % Only add points over existing lines
                lineIdx = findLine(lines, x, y);
                if lineIdx ~= 0
                    plot(x, y, 'go', 'MarkerSize', 4*zlevel)
                    c = get(gca,'children');
                    
                    % Add new point. The line over wich the point was drawn is set as the trailing
                    % line for the point.
                    editingLine = lines(lineIdx);
                    newPoint = pPoint(c(1), false, editingLine.trailingPoint, editingLine);
                    points(end+1) = newPoint;
                    
                    % Add new line
                    [xb,yb] = bresenham(newPoint.XData, newPoint.YData, ...
                                editingLine.followingPoint.XData, editingLine.followingPoint.YData);
                    plot(xb,yb, 'y*', 'MarkerSize', 2*zlevel)
                    c = get(gca,'children');
                    newLine = pLine(c(1), newPoint, editingLine.followingPoint);
                    lines(end+1) = newLine;
                    
                    % Move editing line
                    [xb,yb] = bresenham(newPoint.trailingPoint.XData, newPoint.trailingPoint.YData, ...
                                newPoint.XData, newPoint.YData);
                    editingLine.moveLine(xb, yb);
                    
                    % Change references
                    newPoint.trailingPoint.followingPoint = newPoint;
                    editingLine.followingPoint = newPoint;
                    
                    newPoint.followingLine = newLine;
                    newPoint.followingPoint = newLine.followingPoint;
                    
                    newPoint.followingPoint.trailingPoint = newPoint;
                    newPoint.followingPoint.trailingLine = newLine;
                end
            end
        end
        
        fprintf('------------------------------\n');
        fprintf('Number of points = %d\n', length(points));
        fprintf('Number of lines = %d\n', length(lines));
        if ~isempty(startingPoint)
            fprintf('Starting point = [%d %d]\n', startingPoint.point.XData, startingPoint.point.YData);
        end
        if ~isempty(activePoint)
            fprintf('Active point   = [%d %d]\n', activePoint.point.XData, activePoint.point.YData);
        end
        
        % State transitions
        if state == sDrawing
            if button == ekey
                editingPoint = [];
                state = sEditing;
                fprintf('Changing to edit mode!\n');
            elseif button == akey
                state = sAdding;
                fprintf('Changing to add mode!\n');
            end
        elseif state == sEditing
            if button == dkey
                state = sDrawing;
                fprintf('Changing to draw mode!\n');
            elseif button == akey
                state = sAdding;
                fprintf('Changing to add mode!\n');
            end
        elseif state == sAdding
            if button == ekey
                editingPoint = [];
                state = sEditing;
                fprintf('Changing to edit mode!\n');
            elseif button == dkey
                state = sDrawing;
                fprintf('Changing to draw mode!\n');
            end
        end
    end
    
    close
    
    if button == rkey  % Redo image
        fprintf('Redoing image %d\n', k);
        
        % Clear arrays
        clear points lines
        points(1,1) = pPoint;
        lines(1,1) = pLine;
        
        continue
        
    else
        % Join all border segments
        fullborder = [];
        for i = 1:length(lines)
            segment = [];
            segment(:,1) = lines(i).XData';
            segment(:,2) = lines(i).YData';
            fullborder = [fullborder; segment];
        end
        
        correctBorders(k) = {fullborder};

        if button == spacebar       % Next image, clearing variables
            fprintf('Image %d finished. Variables cleared\n', k);
            
            % Clear arrays
            clear points lines
            points(1,1) = pPoint;
            lines(1,1) = pLine;
        
            k = k+1;
            s(k).cdata = readFrame(vidObj);
        elseif button == key1       % Next image, keep variables
            fprintf('Image %d finished. Keeping drawn points and lines\n', k);
            k = k+1;
            s(k).cdata = readFrame(vidObj);
        elseif button == enterkey   % End here
            fprintf('Segmentation ended by user. %d frames were saved\n\n', k);
            break
        end
    end
end

if button ~= enterkey
    fprintf('Finished segmenting video. %d frames were saved\n\n', k-1);
end

%save(char("manual_segmentation\" + vidName + ".mat"), 'correctBorders');

figure(2)
plot(fullborder(:,1), fullborder(:,2), 'b*')
axis ij
axis equal








%%%%%%%%%%%%%%%%%%%%
% HELPER FUNCTIONS %
%%%%%%%%%%%%%%%%%%%%

function unplot(n, mode)
c = get(gca,'children');
if nargin < 1
    n = 1;
    delete( c(1:min(n,length(c))) );
elseif nargin == 1
    delete( c(1:min(n,length(c))) );
else
    if mode == 'abs' && n <= length(c)
        delete( c(end-n+1) );
    end
end
end

function idx = findPoint(points, x, y)
for i = length(points):-1:1
    if isequal([points(i).XData points(i).YData], [x y])
        idx = i;
        return
    end
end
idx = 0;
end

function idx = findLine(lines, x, y)
for i = length(lines):-1:1
    for j = 1:length(lines(i).XData)
        if isequal([x y], [lines(i).XData(j) lines(i).YData(j)])
            idx = i;
            return
        end
    end
end
idx = 0;
end








