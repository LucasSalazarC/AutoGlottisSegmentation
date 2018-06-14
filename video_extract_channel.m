vidPath = 'C:\Users\lucassalazar12\Videos\DSP\Resized videos\rsz_';
vidList = {'FN003', 'FN007', 'FP007', 'FP016', 'FN003_naso', 'FP005_naso', 'FP011_naso', 'FD003_pre', 'FN003_lombard', 'MN003_adapt'};

channel = 3;

if channel == 1
    color = 'red';
elseif channel == 2
    color = 'blue';
elseif channel == 3
    color = 'green';
end

for j = 1:length(vidList)
    vidName = cell2mat(vidList(j));
    fprintf('Processing video %s...\n', vidName);
    
    % Open and read video data
    vidObj = VideoReader(strcat(vidPath, vidName, '.avi'));
    vidHeight = vidObj.Height;
    vidWidth = vidObj.Width;
    s = struct('cdata',zeros(vidHeight,vidWidth,3,'uint8'),'colormap',[]);
    
    frames = round(vidObj.Duration * vidObj.FrameRate);

    k = 1;
    vidObj.CurrentTime = 0;
    while k <= frames
        s(k).cdata = readFrame(vidObj);         % Cuadros del video (imagenes)
        k = k+1;
    end
    
    singleChannelVideo = VideoWriter(strcat('C:\Users\lucassalazar12\Videos\DSP\Resized videos\', color, '_', vidName, '.avi'), 'Uncompressed AVI');
    singleChannelVideo.FrameRate = 30;
    open(singleChannelVideo);
    for i = 1:length(s)
        writeVideo(singleChannelVideo, s(i).cdata(:,:,channel));
    end
    close(singleChannelVideo);
    
end