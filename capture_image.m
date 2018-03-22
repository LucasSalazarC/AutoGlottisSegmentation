%% Open and read video data
vidObj = VideoReader('C:\Users\lucassalazar12\Videos\DSP\MN001.avi');
vidHeight = vidObj.Height;
vidWidth = vidObj.Width;
s = struct('cdata',zeros(vidHeight,vidWidth,3,'uint8'),'colormap',[]);

k = 1;
startTime = 0;
vidObj.CurrentTime = startTime;
while vidObj.CurrentTime <= 1
    s(k).cdata = readFrame(vidObj);         % Cuadros del video (imagenes)
    k = k+1;
end

%%

for i = 1:length(s)
    figure(1)
    image(s(i).cdata)
    axis image
    
    fprintf('Frame %d, T = %f seg\n', i, startTime + (i-1) / vidObj.FrameRate);
    
    waitforbuttonpress
end
fprintf('\n');



