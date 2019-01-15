%% Open and read video data

vidName = 'FP010 - R14.avi';
vidPath = [ '/run/user/1000/gvfs/smb-share:server=vplab-storage.local,share=voicelab/Users/U00 - Common/'...
                   'Current Project/P003- P1151077/Data/FP010/L.E01/S01.Pro/R14 - Rigido  i/' ];
               
vidObj = VideoReader( [ vidPath vidName ] );
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