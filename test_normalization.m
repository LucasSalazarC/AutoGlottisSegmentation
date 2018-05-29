vidName = 'FN004_naso';
if contains(vidName,'pre') || contains(vidName,'lombard') || contains(vidName,'adapt')
    vidPath = 'C:\Users\lucassalazar12\Videos\DSP\Lombard_video_8k fps\';
else
    vidPath = 'C:\Users\lucassalazar12\Videos\DSP\Fondecyt videos 10k fps\';
end

% Load correctBorders
load(strcat('training_data\', vidName, '.mat'));

% Video frame index
idx = correctBorders{1,2};

% Read video frames
vidObj = VideoReader(strcat(vidPath, vidName, '.avi'));
s = struct('cdata',zeros(vidObj.Height,vidObj.Width,3,'uint8'),'colormap',[]);
k = 1;
vidObj.CurrentTime = 0;
while k <= idx
    s(k).cdata = readFrame(vidObj);         % Cuadros del video (imagenes)
    k = k+1;
end

img = s(idx).cdata;

% Convert to HSV
imghsv = rgb2hsv(img);
[valueHist, x] = imhist(imghsv(:,:,3));
hsv_h = imghsv(:,:,1);
hsv_s = imghsv(:,:,2);
hsv_v = imghsv(:,:,3);

% Convert to HSL
imghsl = rgb2hsl(double(img)./255);
[lightnessHist, x] = imhist(imghsl(:,:,3));
hsl_h = imghsl(:,:,1);
hsl_s = imghsl(:,:,2);
hsl_l = imghsl(:,:,3);

% Equalize V and L channels
[eqValue, eqValueHist] = histeq(hsv_v);
[eqLightness, eqLightnessHist] = histeq(hsl_l);

% Make sure range is 0 to 1
eqValue = eqValue - min(min(eqValue));
eqValue = eqValue ./ max(max(eqValue));
eqLightness = eqLightness - min(min(eqLightness));
eqLightness = eqLightness ./ max(max(eqLightness));

% Rebuild HSV and HSL images
eqImgHsv = cat(3, hsv_h, hsv_s, eqValue);
eqImgHsl = cat(3, hsl_h, hsl_s, eqLightness);

% Back to RGB
normImg1 = uint8(hsv2rgb(eqImgHsv)*255);
normImg2 = uint8(hsl2rgb(eqImgHsl)*255);

% Calculate GND
border = correctBorders{1,1};
[~,idxlow,idxhigh] = fourierDescriptors(border,30);
sz = size(img);
Ibin = false(sz(1:2));
for j = 1:size(border,1)
    Ibin( border(j,2), border(j,1) ) = true;
end
Ibin = imfill(Ibin, 'holes');

GND = getGND(img, Ibin, border, idxlow, idxhigh);
g = sprintf('%f ', GND);
fprintf('GND Old: %s\n', g);
GND = getGND(normImg1, Ibin, border, idxlow, idxhigh);
g = sprintf('%f ', GND);
fprintf('GND New: %s\n', g);




% Plot data
figure(1)
subplot(1,3,1); image(img); axis image;
subplot(1,3,2); image(normImg1); axis image;
subplot(1,3,3); image(normImg2); axis image;

figure(2)
subplot(2,1,1);
plot(x, valueHist), hold on;
plot(x, lightnessHist)
subplot(2,1,2);
imhist(eqValue), hold on
imhist(eqLightness)




