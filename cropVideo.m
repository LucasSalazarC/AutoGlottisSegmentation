vidObj = VideoReader('C:\Users\lucassalazar12\Videos\DSP\Validación - artificiales\2kPa, 0.015 shim.avi');
vidObj.CurrentTime = 0;
firstFrame = readFrame(vidObj); 

lclick = 1;
enterkey = -1;

figure(1); image( firstFrame ); axis image; hold on
rect = [1 1 256 256];
plot( rect(1), rect(2), 'g*')
plot( rect(1), rect(4), 'g*')
plot( rect(3), rect(2), 'g*')
plot( rect(3), rect(4), 'g*')

while true
    
    [x,y,button] = ginput(1);
    x = round(x); y = round(y);
    
    if isempty(button)
        break
    elseif button == lclick
        if x + 255 <= vidObj.Width && y + 255 <= vidObj.Height
            unplot(4)
            rect = [x y x+255 y+255];
            plot( rect(1), rect(2), 'g*')
            plot( rect(1), rect(4), 'g*')
            plot( rect(3), rect(2), 'g*')
            plot( rect(3), rect(4), 'g*')
        end
    end
    
end



% Read cropped part
s = struct('cdata', zeros( 256, 256, 3, 'uint8'), 'colormap', []);

k = 1;
vidObj.CurrentTime = 0;
while hasFrame(vidObj)
    frame = readFrame(vidObj);         % Cuadros del video (imagenes)
    
    s(k).cdata(:,:,1) = imrotate( frame( rect(2):rect(4), rect(1):rect(3), 1 ), 90 );
    s(k).cdata(:,:,2) = imrotate( frame( rect(2):rect(4), rect(1):rect(3), 2 ), 90 );
    s(k).cdata(:,:,3) = imrotate( frame( rect(2):rect(4), rect(1):rect(3), 3 ), 90 );
    
    k = k+1;
end

myVideo = VideoWriter( ['C:\Users\lucassalazar12\Videos\DSP\Validación - artificiales\copy_' ...
                        vidObj.Name ], 'Uncompressed AVI');
myVideo.FrameRate = vidObj.FrameRate;
open(myVideo);
for i = 1:length(s)
    writeVideo(myVideo, s(i).cdata);
end
close(myVideo);