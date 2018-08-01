% %% Open and read video data
% vidObj = VideoReader('C:\Users\lucassalazar12\Videos\DSP\all_videos\FP010.avi');
% s = struct('cdata',zeros(vidObj.Height,vidObj.Width,3,'uint8'),'colormap',[]);
% 
% k = 1;
% vidObj.CurrentTime = 0;
% while vidObj.CurrentTime <= 1
%     s(k).cdata = readFrame(vidObj);         % Cuadros del video (imagenes)
%     k = k+1;
% end
% 
% frame = 10;

I = imread('C:\Users\lucassalazar12\Downloads\rgbwheel.png');

% rch = s(frame).cdata(:,:,1);
% gch = s(frame).cdata(:,:,2);
% bch = s(frame).cdata(:,:,3);

rch = I(:,:,1);
gch = I(:,:,2);
bch = I(:,:,3);


figure(1), imshow(I)
f = getframe;
imwrite(f.cdata, 'C:\Users\lucassalazar12\Dropbox\USM\2018_1\Memoria\Latex\images\rgb_ex_src.png')

figure(2), imshow(rch)
f = getframe;
imwrite(f.cdata, 'C:\Users\lucassalazar12\Dropbox\USM\2018_1\Memoria\Latex\images\rgb_ex_rch.png')

figure(3), imshow(gch)
f = getframe;
imwrite(f.cdata, 'C:\Users\lucassalazar12\Dropbox\USM\2018_1\Memoria\Latex\images\rgb_ex_gch.png')

figure(4), imshow(bch)
f = getframe;
imwrite(f.cdata, 'C:\Users\lucassalazar12\Dropbox\USM\2018_1\Memoria\Latex\images\rgb_ex_bch.png')

