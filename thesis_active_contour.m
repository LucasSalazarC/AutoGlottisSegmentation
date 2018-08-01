%% Open and read video data
vidObj = VideoReader('C:\Users\lucassalazar12\Videos\DSP\all_videos\FP007.avi');
s = struct('cdata',zeros(vidObj.Height,vidObj.Width,3,'uint8'),'colormap',[]);

k = 1;
vidObj.CurrentTime = 0;
while vidObj.CurrentTime <= 2
    s(k).cdata = readFrame(vidObj);         % Cuadros del video (imagenes)
    k = k+1;
end

frame = 20;
figure(1), imshow(s(frame).cdata), hold on

thresh_image = im2bw(s(frame).cdata, 30/255);
thresh_image = imcomplement(thresh_image);
% figure(2), imshow(thresh_image)



obj = bwboundaries(thresh_image);
obj = obj{2};
obj = flipud(obj);  
obj = fliplr(obj);  
plot(obj(:,1), obj(:,2), 'g', 'LineWidth', 1.2), hold off
f = getframe;
imwrite(f.cdata, 'C:\Users\lucassalazar12\Dropbox\USM\2018_1\Memoria\Latex\images\acontour_example_src.png')


c = contourLGD(obj, rgb2gray(s(frame).cdata), 350);
figure(2), imshow(s(frame).cdata), hold on
plot(c(:,1), c(:,2), 'g', 'LineWidth', 1.2), hold off
f = getframe;
imwrite(f.cdata, 'C:\Users\lucassalazar12\Dropbox\USM\2018_1\Memoria\Latex\images\acontour_example_result.png')