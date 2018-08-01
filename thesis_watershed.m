%% Open and read video data
vidObj = VideoReader('C:\Users\lucassalazar12\Videos\DSP\all_videos\FN001_pre.avi');
s = struct('cdata',zeros(vidObj.Height,vidObj.Width,3,'uint8'),'colormap',[]);

k = 1;
vidObj.CurrentTime = 0;
while vidObj.CurrentTime <= 1
    s(k).cdata = readFrame(vidObj);         % Cuadros del video (imagenes)
    k = k+1;
end

frame = 20;
I = rgb2gray(s(frame).cdata);
figure(1), imshow(I)
% f = getframe;
% imwrite(f.cdata, 'C:\Users\lucassalazar12\Dropbox\USM\2018_1\Memoria\Latex\images\watershed_ex_src.png')

% Gradient
hy = fspecial('sobel');
hx = hy';
Iy = imfilter(double(I), hy, 'replicate');
Ix = imfilter(double(I), hx, 'replicate');
gradmag = sqrt(Ix.^2 + Iy.^2);
figure(2), imshow(gradmag,[])
% f = getframe;
% imwrite(f.cdata, 'C:\Users\lucassalazar12\Dropbox\USM\2018_1\Memoria\Latex\images\watershed_ex_sobel.png')

% Bad attempt
L = watershed(gradmag);
Lrgb = label2rgb(L);
figure(3), imshow(Lrgb)
% f = getframe;
% imwrite(f.cdata, 'C:\Users\lucassalazar12\Dropbox\USM\2018_1\Memoria\Latex\images\watershed_ex_bad.png')

% Opening by reconstruction
se = strel('disk', 7);
Ie = imerode(I, se);
Iobr = imreconstruct(Ie, I);

% Closing by reconstruction
Iobrd = imdilate(Iobr, se);
Iobrcbr = imreconstruct(imcomplement(Iobrd), imcomplement(Iobr));
Iobrcbr = imcomplement(Iobrcbr);

figure(4), imshow(Iobrcbr)
% f = getframe;
% imwrite(f.cdata, 'C:\Users\lucassalazar12\Dropbox\USM\2018_1\Memoria\Latex\images\watershed_ex_opclose.png')

% Regional minumum
fgm = imregionalmin(Iobrcbr);

% Close and erode to eliminate noise
se2 = strel(ones(5,5));
fgm2 = imclose(fgm, se2);
fgm3 = imerode(fgm2, se2);
fgm4 = bwareaopen(fgm3, 20);
figure(5), imshow(fgm4), title('Reg. minimum')
% f = getframe;
% imwrite(f.cdata, 'C:\Users\lucassalazar12\Dropbox\USM\2018_1\Memoria\Latex\images\watershed_ex_regmin.png')

% Calculate background markers
bw = imbinarize(Iobrcbr, 100/255);
bw = imcomplement(bw);
figure(6), imshow(bw), title('Threshold')
% f = getframe;
% imwrite(f.cdata, 'C:\Users\lucassalazar12\Dropbox\USM\2018_1\Memoria\Latex\images\watershed_ex_bg.png')

% Ridge lines
D = bwdist(bw);
DL = watershed(D);
bgm = DL == 0;
figure(7), imshow(bgm), title('Watershed ridge lines (bgm)')
% f = getframe;
% imwrite(f.cdata, 'C:\Users\lucassalazar12\Dropbox\USM\2018_1\Memoria\Latex\images\watershed_ex_ridge.png')

% Watershed
gradmag2 = imimposemin(gradmag, bgm | fgm4);
figure(9), imshow(gradmag2,[])
f = getframe;
imwrite(f.cdata, 'C:\Users\lucassalazar12\Dropbox\USM\2018_1\Memoria\Latex\images\watershed_ex_gradmin.png')

L = watershed(gradmag2);
Lrgb = label2rgb(L);
figure(8), imshow(Lrgb)
f = getframe;
imwrite(f.cdata, 'C:\Users\lucassalazar12\Dropbox\USM\2018_1\Memoria\Latex\images\watershed_ex_result.png')







