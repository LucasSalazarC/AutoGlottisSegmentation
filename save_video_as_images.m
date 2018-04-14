%% Open and read video data
vidName = "MN002";
vidPath = "C:\Users\lucassalazar12\Videos\DSP\";
vidObj = VideoReader(char(vidPath + vidName + ".avi"));
%vidObj = VideoReader('C:\Users\lucassalazar12\Dropbox\USM\2017_2\IPD414 - Seminario DSP\Proyecto\Videos segmentados\Mal\seg_FN003.avi');
vidHeight = vidObj.Height;
vidWidth = vidObj.Width;
s = struct('cdata',zeros(vidHeight,vidWidth,3,'uint8'),'colormap',[]);

mkdir(char(vidPath + vidName));

k = 1;
vidObj.CurrentTime = 0;
while k <= 100
    s(k).cdata = readFrame(vidObj);         % Cuadros del video (imagenes)
    
    filename = char(vidPath + vidName + "\" + vidName + "_" + num2str(k) + ".jpg");
    imwrite(s(k).cdata, filename, 'jpg')
    
    k = k+1;
end
 

% figure(1)
% imshow(s(1).cdata)
