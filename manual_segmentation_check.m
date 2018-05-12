vidName = 'FD003_pre';
if contains(vidName,'pre') || contains(vidName,'lombard') || contains(vidName,'adapt')
    vidPath = 'C:\Users\lucassalazar12\Videos\DSP\Lombard_video_8k fps\';
else
    vidPath = 'C:\Users\lucassalazar12\Videos\DSP\Fondecyt videos 10k fps\';
end

% Load correctBorders
load(strcat('manual_segmentation\', vidName, '.mat'));

% Last video frame needed
frames = correctBorders{end,2};

% Read video frames
vidObj = VideoReader(strcat(vidPath, vidName, '.avi'));
s = struct('cdata',zeros(vidObj.Height,vidObj.Width,3,'uint8'),'colormap',[]);
k = 1;
vidObj.CurrentTime = 0;
while k <= frames
    s(k).cdata = readFrame(vidObj);         % Cuadros del video (imagenes)
    k = k+1;
end

close all
figure(1)
for i = 1:size(correctBorders,1)
    idx = correctBorders{i,2};
    subplot(1,2,1); image(s(idx).cdata); axis image;
    subplot(1,2,2); image(s(idx).cdata); axis image; hold on;
    b = correctBorders{i,1};
    plot(b(:,1), b(:,2), 'g*', 'MarkerSize', 1)

    waitforbuttonpress
end

close