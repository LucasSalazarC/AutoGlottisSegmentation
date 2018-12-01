load('Output_contours/2kPa, 0.01 shim.mat');

vidName = '2kPa, 0.01 shim.mp4';
vidPath = '/run/user/1000/gvfs/smb-share:server=vplab-storage.local,share=voicelab/Users/U00 - Common/Current Project/P010- HSV Clarkson/Contact Stress/';
frames = 87;

vidObj = VideoReader( [vidPath vidName ]);
vidHeight = vidObj.Height;
vidWidth = vidObj.Width;
s = struct('cdata',zeros(vidHeight,vidWidth,3,'uint8'),'colormap',[]);

vidSize = [vidHeight vidWidth];

k = 1;
startTime = 0;
vidObj.CurrentTime = startTime;
endTime = startTime + frames/vidObj.FrameRate;
while vidObj.CurrentTime <= endTime
    s(k).cdata = readFrame(vidObj);         % Cuadros del video (imagenes)
    
    ctr = outputContours{k};
    for j = 1:length(ctr)
        m = max(ctr(j,1), 1);
        m = min(m, vidHeight);
        n = max(ctr(j,2), 1);
        n = min(n, vidWidth);

        s(k).cdata(n,m,1) = 0;
        s(k).cdata(n,m,2) = 255;
        s(k).cdata(n,m,3) = 0;
    end
    
    imshow(s(k).cdata)
    pause(0.02)
            
    k = k+1;
end