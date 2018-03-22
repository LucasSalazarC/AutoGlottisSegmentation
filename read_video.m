%% Open and read video data
%vidObj = VideoReader('C:\Users\lucassalazar12\Videos\DSP\MN002.avi');
vidObj = VideoReader('C:\Users\lucassalazar12\Dropbox\USM\2017_2\IPD414 - Seminario DSP\Proyecto\Videos segmentados\Mal\seg_FN003.avi');
vidHeight = vidObj.Height;
vidWidth = vidObj.Width;
s = struct('cdata',zeros(vidHeight,vidWidth,3,'uint8'),'colormap',[]);

k = 1;
vidObj.CurrentTime = 0;
while vidObj.CurrentTime <= 3
    s(k).cdata = readFrame(vidObj);         % Cuadros del video (imagenes)
    k = k+1;
end

%% 

%figure(1)
imshow(s(53).cdata)