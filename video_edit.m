%% Get ROI
vidObj = VideoReader('C:\Users\lucassalazar12\Videos\DSP\Validación - artificiales\edit_crop 2kPa, 0.02 shim.avi');

frameToShow = 10;
vidObj.CurrentTime = (frameToShow - 1) / vidObj.FrameRate;
img = readFrame( vidObj );

figure(1)
imshow(img);
roi = round(wait(imrect));
xRange = roi(1) : roi(1)+roi(3);
yRange = roi(2) : roi(2)+roi(4);
roiWidth = roi(3) + 1;
roiHeight = roi(4) + 1;


%% Read and edit video

brightFactor = 255;

contrastFactor = 3;
contrastMatrix = ( (1:roiHeight)' - 1 ) / ( roiHeight - 1 );
contrastMatrix = contrastMatrix * ( contrastFactor - 1 ) + 1;
contrastMatrix = repmat( contrastMatrix, 1, roiWidth );

s = struct('cdata', zeros( 256, 256, 3, 'uint8'), 'colormap', []);

k = 1;
vidObj.CurrentTime = 0;
while hasFrame(vidObj)
    s(k).cdata = readFrame(vidObj);         % Cuadros del video (imagenes)
    
    s(k).cdata( yRange, xRange, 1) = double( s(k).cdata( yRange, xRange, 1) + brightFactor ) .* contrastMatrix;
    s(k).cdata( yRange, xRange, 2) = double( s(k).cdata( yRange, xRange, 2) + brightFactor ) .* contrastMatrix;
    s(k).cdata( yRange, xRange, 3) = double( s(k).cdata( yRange, xRange, 3) + brightFactor ) .* contrastMatrix;
    
%     imshow(s(k).cdata)
%     pause(0.02)
    
    k = k+1;
end


%% Write

myVideo = VideoWriter( ['C:\Users\lucassalazar12\Videos\DSP\Validación - artificiales\edit_' ...
                        vidObj.Name ], 'Uncompressed AVI');
myVideo.FrameRate = vidObj.FrameRate;
open(myVideo);
for i = 1:length(s)
    writeVideo(myVideo, s(i).cdata);
end
close(myVideo);
