vidName = 'FN003_naso';
if contains(vidName,'pre') || contains(vidName,'lombard') || contains(vidName,'adapt')
    vidPath = 'C:\Users\lucassalazar12\Videos\DSP\Lombard_video_8k fps\';
else
    vidPath = 'C:\Users\lucassalazar12\Videos\DSP\Fondecyt videos 10k fps\';
end
vidObj = VideoReader(strcat(vidPath, vidName, '.avi'));
vidHeight = vidObj.Height;
vidWidth = vidObj.Width;
s = struct('cdata',zeros(vidHeight,vidWidth,3,'uint8'),'colormap',[]);

vidSize = [vidHeight vidWidth];

frames = 10;

k = 1;
startTime = 0;
vidObj.CurrentTime = startTime;
endTime = startTime + frames/vidObj.FrameRate;
while vidObj.CurrentTime <= endTime
    s(k).cdata = readFrame(vidObj);         % Cuadros del video (imagenes)
    k = k+1;
end


% normFrame = normalizeimg(s(1).cdata);
normFrame = s(1).cdata;
blackMask = im2bw(normFrame, 15/255);
blackMask = imcomplement(blackMask);

se = strel('disk', 1);
blackMask = imdilate(blackMask, se);

close
figure(1)
subplot(1,2,1), imshow(blackMask), hold on

% Bordes
allBorders = bwboundaries(blackMask);
for k = 1:length(allBorders)
    B = allBorders{k};              % Clockwise order
    B = fliplr(B);                  % x -> columna 1, y -> columna 2
    
    plot(B(:,1), B(:,2), 'y*', 'Markersize', 0.5) 

    % Filter shapes not touching the edge of the image
    if check_out_of_bounds(B, vidSize, 'image')
        unplot
        continue
    end
    
    objectMask = false(vidSize);
    for i = 1:length(B)
        objectMask( B(i,2), B(i,1) ) = true;
    end
    objectMask = imfill(objectMask, 'holes');
    
    blackMask = blackMask & ~objectMask;
    
end


subplot(1,2,2), imshow(blackMask);
