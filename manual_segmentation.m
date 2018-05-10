%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%    REMEMBER THAT BORDERS ARE SAVED IN COUNTERCLOCKWISE ORDER    %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear

% Suppress JavaFrame warning
id = 'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame';
warning('off', id);

% Open and read video data
vidName = 'FN003';
if contains(vidName,'pre') || contains(vidName,'lombard') || contains(vidName,'adapt')
    vidPath = 'C:\Users\lucassalazar12\Videos\DSP\Lombard_video_8k fps\';
else
    vidPath = 'C:\Users\lucassalazar12\Videos\DSP\Fondecyt videos 10k fps\';
end
vidObj = VideoReader(strcat(vidPath, vidName, '.avi'));
vidHeight = vidObj.Height;
vidWidth = vidObj.Width;
s = struct('cdata',zeros(vidHeight,vidWidth,3,'uint8'),'colormap',[]);

% Folder to save segmentation data
destFolder = 'manual_segmentation\';

% Check if segmentation data already exists
if exist( strcat(destFolder, vidName, '.mat'), 'file' ) == 2
    load( strcat(destFolder, vidName, '.mat') );
    correctBorders
else
    % To save final segmentation data
    correctBorders = {};
end



% States
sDrawing = 1;
sEditing = 2;
sAdding = 3;

% Button ascii
wkey = 119;
skey = 115;
rkey = 114;
ckey = 99;
ekey = 101;
dkey = 100;
akey = 97;
gkey = 103;
bkey = 98;
key1 = 49;
key9 = 57;
lclick = 1;
rclick = 3;
enterkey = -1;

% Stores pressed keys
button = NaN;

% Plot zoom level
zlevel = 1;

% Read video data
k = 1;
vidObj.CurrentTime = 0;
while vidObj.CurrentTime <= 10
    s(k).cdata = readFrame(vidObj);
    k = k+1;
end

k = 1;
while true
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
    
    % Clear arrays
    clear points lines
    points(1,1) = pPoint;
    lines(1,1) = pLine;

    % This array contains all drawn points in format (x,y). The third column is 1 if the point is a 
    % starting point. Otherwise it is 0. It can persist from one frame to the next.
    points(1,1) = pPoint;

    % Cell to save border segments. Can persist between frames.
    lines(1,1) = pLine;
    
    % Only one starting point for each closed border. Resets when a border
    % is closed, and is set when a new border begins.
    startingPoint = [];
    
    % activePoint is set to last drawn point, unless said point is the
    % startingPoint. It resets when a border is closed.
    activePoint = [];
    
    % Only for editing mode. It is reset each time editing mode is enabled.
    editingPoint = [];
    
    % Indicates whether to save current frame or not
    saveFlag = false;
    
    % Sets direction in which to advance. Forward by default
    backFlag = false;
    
    % Initial state
    state = sDrawing;
    
    % Reset zoom variables
    zoom_scale = 1.5;
    zlevel = 1;
    
    % Check if currect frame has already been segmented
    alreadySegmented = false;
    if ~isempty(correctBorders)
        frameIdxs = cell2mat(correctBorders(:,2));
        idxInArray = find(frameIdxs == k);
        
        % Draw boder if it exists
        if ~isempty(idxInArray)
            alreadySegmented = true;
            currBorder = cell2mat(correctBorders(idxInArray,1));
            if ~isempty(currBorder)
                plot(currBorder(:,1), currBorder(:,2), 'y*', 'MarkerSize', 4*zlevel)
            end
        end
    end

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
        if button == enterkey || (button >= key1 && button <= key9)
            if borderNotClosed
                [xb,yb] = bresenham(activePoint.XData, activePoint.YData, startingPoint.XData, startingPoint.YData);
                plot(xb,yb, 'y*', 'MarkerSize', 1.5*zlevel)
                
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
        
        % Change save flag
        elseif button == gkey
            saveFlag = ~saveFlag;
            if saveFlag
                fprintf('Save flag set!\n');
            else
                fprintf('Save flag unset!\n');
            end
        
        % Backwards flag
        elseif button == bkey
            backFlag = ~backFlag;
            if backFlag
                fprintf('Going backwards!\n');
            else
                fprintf('Going forward!\n');
            end
        end
            
        
        
        % State actions
        
        if state == sDrawing
            
            % Close current border. Begin new border in same figure
            if button == ckey
                if borderNotClosed
                    [xb,yb] = bresenham(activePoint.XData, activePoint.YData, startingPoint.XData, startingPoint.YData);
                    plot(xb,yb, 'y*', 'MarkerSize', 1.5*zlevel)
                    
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
                    plot(x, y, 'co', 'MarkerSize', 3*zlevel)
                    c = get(gca,'children');
                    startingPoint = pPoint(c(1), true);
                    if length(points) == 1
                        points(1) = startingPoint;
                    else
                        points(end+1) = startingPoint;
                    end
                else
                    [xb,yb] = bresenham(points(end).XData, points(end).YData, x, y);
                    plot(xb,yb, 'y*', 'MarkerSize', 1.5*zlevel)
                    plot(x, y, 'go', 'MarkerSize', 3*zlevel)
                    
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
                    plot(x, y, 'go', 'MarkerSize', 3*zlevel)
                    c = get(gca,'children');
                    
                    % Add new point. The line over wich the point was drawn is set as the trailing
                    % line for the point.
                    editingLine = lines(lineIdx);
                    newPoint = pPoint(c(1), false, editingLine.trailingPoint, editingLine);
                    points(end+1) = newPoint;
                    
                    % Add new line
                    [xb,yb] = bresenham(newPoint.XData, newPoint.YData, ...
                                editingLine.followingPoint.XData, editingLine.followingPoint.YData);
                    plot(xb,yb, 'y*', 'MarkerSize', 1.5*zlevel)
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
        
%         fprintf('------------------------------\n');
%         fprintf('Number of points = %d\n', length(points));
%         fprintf('Number of lines = %d\n', length(lines));
%         if ~isempty(startingPoint)
%             fprintf('Starting point = [%d %d]\n', startingPoint.point.XData, startingPoint.point.YData);
%         end
%         if ~isempty(activePoint)
%             fprintf('Active point   = [%d %d]\n', activePoint.point.XData, activePoint.point.YData);
%         end
        
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
        fprintf('Redoing frame %d\n', k);
        
        % Erase border if it exists
        if alreadySegmented
            correctBorders(idxInArray,:) = [];
        end
        continue
        
    else
        % Join all border segments
        fullborder = [];
        if length(points) > 1
            for i = 1:length(lines)
                segment = [];
                segment(:,1) = lines(i).XData';
                segment(:,2) = lines(i).YData';
                fullborder = [fullborder; segment];
            end
        end
        
        if saveFlag
            correctBorders(end+1,:) = {fullborder, k};
        end
        

        if button >= key1 && button <= key9     % Skip N images
            % Convert to number value
            button = button - key1 + 1;
            L = size(correctBorders,1);
            if ~backFlag
                if saveFlag
                    fprintf('Frame %d saved; %d in total. Advancing %d frames to frame %d\n', k, L, button, k+button);
                else
                    fprintf('Frame %d skipped; %d in total. Advancing %d frames to frame %d\n', k, L, button, k+button);
                end
            
                k = k + button;
            else
                if saveFlag
                    fprintf('Frame %d saved; %d in total. Going back %d frames to frame %d\n', k, L, min([button k-1]), max([k-button 1]));
                else
                    fprintf('Frame %d skipped; %d in total. Going back %d frames to frame %d\n', k, L, min([button k-1]), max([k-button 1]));
                end
                
                k = k - button;
                if k < 1
                    k = 1;
                end
            end
            
        elseif button == enterkey   % End here
            fprintf('Segmentation ended by user. %d frames were saved\n\n', L);
            break
        end
    end
end

if button ~= enterkey
    fprintf('Finished segmenting video. %d frames were saved\n\n', k-1);
end

if ~isempty(correctBorders)
    correctBorders = sortrows(correctBorders, 2)
    save(strcat(destFolder, vidName, '.mat'), 'correctBorders');
end

% if exist('fullborder', 'var')
%     figure(2)
%     plot(fullborder(:,1), fullborder(:,2), 'b*')
%     axis ij
%     axis equal
% end







%%%%%%%%%%%%%%%%%%%%
% HELPER FUNCTIONS %
%%%%%%%%%%%%%%%%%%%%

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








