vidPath = 'C:\Users\lucassalazar12\Videos\DSP\all_videos\';
files = dir(vidPath);
frames = 88;

for j = 1:length(files)
    if ~files(j).isdir && contains(files(j).name,'.avi')

        vidName = files(j).name;
        vidName = vidName(1:end-4);
        fprintf('Processing video %s...\n', vidName);

        % Open and read video data
        vidObj = VideoReader(strcat(vidPath, vidName, '.avi'));
        vidHeight = vidObj.Height;
        vidWidth = vidObj.Width;
        s = struct('cdata',zeros(vidHeight,vidWidth,3,'uint8'),'colormap',[]);

        k = 1;
        vidObj.CurrentTime = 0;
        endTime = frames/vidObj.FrameRate;
        while vidObj.CurrentTime <= endTime
            s(k).cdata = readFrame(vidObj);         % Cuadros del video (imagenes)
            k = k+1;
        end

        padRight = 0;
        padLeft = 0;
        padTop = 0;
        padBottom = 0;

        if vidHeight > vidWidth
            totalPadding = vidHeight - vidWidth;
            padLeft = floor(totalPadding/2);
            padRight = ceil(totalPadding/2);
            sizeAfterPad = vidHeight;
        elseif vidWidth > vidHeight
            totalPadding = vidWidth - vidHeight;
            padTop = floor(totalPadding/2);
            padBottom = ceil(totalPadding/2);
            sizeAfterPad = vidWidth;
        else
            % Equal height and width
            sizeAfterPad = vidHeight;
        end

        mStart = padTop + 1;
        mEnd = mStart + vidHeight - 1;
        nStart = padLeft + 1;
        nEnd = nStart + vidWidth - 1;

        resizeScale = 256 / sizeAfterPad;

        % Save resize data to compare segmentation of the resized video with the original
        resizeData = cell(1,5);
        resizeData(1) = {vidName};
        resizeData(2) = {resizeScale};
        resizeData(3) = {padTop};
        resizeData(4) = {padLeft};
        resizeData(5) = {[vidHeight vidWidth]};
        save(strcat('GIE_segdata\', vidName, '_resizedata.mat'), 'resizeData');


        % To save video frames
        resizedVideoFrames = cell(length(s),1);

        for i = 1:length(s)
            newFrame = zeros(sizeAfterPad, sizeAfterPad, 3, 'uint8');
            newFrame(mStart:mEnd, nStart:nEnd, :) = s(i).cdata;
            newFrame = imresize(newFrame, [256 256]);

    %         subplot(1,2,1), imshow(s(i).cdata), title('Original');
    %         subplot(1,2,2), imshow(newFrame), title('Resized');

            resizedVideoFrames(i) = {newFrame};
        end

        resizedVideo = VideoWriter(strcat('C:\Users\lucassalazar12\Videos\DSP\Resized videos\rsz_', vidObj.Name), 'Uncompressed AVI');
        resizedVideo.FrameRate = 30;
        open(resizedVideo);
        for i = 1:length(resizedVideoFrames)
            writeVideo(resizedVideo, resizedVideoFrames{i});
        end
        close(resizedVideo);
    end
    
end













