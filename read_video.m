%% Open and read video data
vidObj = VideoReader('C:\Users\lucassalazar12\Videos\DSP\Lombard_video_8k fps\FN003_lombard.avi');
%vidObj = VideoReader('C:\Users\lucassalazar12\Dropbox\USM\2017_2\IPD414 - Seminario DSP\Proyecto\Videos segmentados\Mal\seg_FN003.avi');
vidHeight = vidObj.Height;
vidWidth = vidObj.Width;
s = struct('cdata',zeros(vidHeight,vidWidth,3,'uint8'),'colormap',[]);

k = 1;
vidObj.CurrentTime = 0;
while vidObj.CurrentTime <= 5
    s(k).cdata = readFrame(vidObj);         % Cuadros del video (imagenes)
    k = k+1;
end

%% 

i = 1
figure(1)
while true
    imshow(s(i).cdata)
    waitforbuttonpress
    i = i + 1
end