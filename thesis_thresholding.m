%% Open and read video data
vidObj = VideoReader('C:\Users\lucassalazar12\Videos\DSP\all_videos\FP013.avi');
s = struct('cdata',zeros(vidObj.Height,vidObj.Width,3,'uint8'),'colormap',[]);

k = 1;
vidObj.CurrentTime = 0;
while vidObj.CurrentTime <= 1
    s(k).cdata = readFrame(vidObj);         % Cuadros del video (imagenes)
    k = k+1;
end

frame = 10;

thresh_image = im2bw(s(frame).cdata, 40/255);
thresh_image = imcomplement(thresh_image);

% Apertura
se = strel('disk',1);
openedframe = imopen(thresh_image,se);

% Bordes
allBorders = bwboundaries(openedframe, 'noholes');
border = allBorders{2};

figure(1), imshow(s(frame).cdata)
f = getframe;
imwrite(f.cdata, 'C:\Users\lucassalazar12\Dropbox\USM\2018_1\Memoria\Latex\images\fd_thresh_ex_src.png')

figure(2), imshow(openedframe), hold on
plot(border(:,2), border(:,1), 'r'), hold off
f = getframe;
imwrite(f.cdata, 'C:\Users\lucassalazar12\Dropbox\USM\2018_1\Memoria\Latex\images\fd_thresh_ex.png')