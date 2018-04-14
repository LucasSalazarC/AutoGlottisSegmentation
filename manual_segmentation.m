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

% mkdir(char(vidPath + vidName));
correctBorders = {};

k = 1;
vidObj.CurrentTime = 0;
s(k).cdata = readFrame(vidObj);         % Video frames
while k <= 1
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

    % Buttons
    zoom_scale = 1.5;
    zlevel = 1;
    spacebar = 32;
    wkey = 119;
    skey = 115;
    rkey = 114;
    lclick = 1;
    rclick = 3;
    enterkey = -1;

    vertices = [];
    borders = {};

    while true
        [x,y,button] = ginput(1);
        if isempty(button) % Enter key
            button = enterkey;
        end
        
        if button == spacebar || button == rkey || button == enterkey
            break
        elseif button == skey  % zoom out
            ax = axis; width=ax(2)-ax(1); height=ax(4)-ax(3);
            axis([x-width/2 x+width/2 y-height/2 y+height/2]);
            zoom(1/zoom_scale);
            zlevel = zlevel / zoom_scale;
        elseif button == wkey  % zoom in
            ax = axis; width=ax(2)-ax(1); height=ax(4)-ax(3);
            axis([x-width/2 x+width/2 y-height/2 y+height/2]);
            zoom(zoom_scale);  
            zlevel = zlevel * zoom_scale;
        elseif button == lclick  % Draw line to next vertex
            vertices = [vertices; round([x y])];
            plot(x, y, 'go', 'MarkerSize', 4*zlevel)
            if length(vertices(:,1)) > 1
                [xb,yb] = bresenham(vertices(end-1,1), vertices(end-1,2), x, y);
                borders(end+1) = {[xb yb]};
                plot(xb,yb, 'y*', 'MarkerSize', 2*zlevel)
            end
        elseif button == rclick  % Delete last point and line
            if length(vertices(:,1)) == 1
                vertices = vertices(1:end-1, :);
                unplot
            elseif length(vertices(:,1)) > 1
                vertices = vertices(1:end-1, :);
                borders = borders(1:end-1);
                unplot(2)
            end
        end
    end
    
    close
    
    if button == rkey  % Redo image
        fprintf('Redoing image %d\n', k);
        continue
    else
        % Join all border segments
        fullborder = [];
        for i = 1:length(borders)
            segment = cell2mat(borders(i));
            if i == length(borders) && i > 1 && ~isequal(segment(end,:), fullborder(1,:))
                fullborder = [fullborder; segment];
            else
                fullborder = [fullborder; segment(1:end-1, :)];
            end
        end
        
        correctBorders(end+1) = {fullborder};

        if button == spacebar       % Next image
            fprintf('Image %d finished\n', k);
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

% save(char("manual_segmentation\" + vidName + ".mat"), 'correctBorders');






