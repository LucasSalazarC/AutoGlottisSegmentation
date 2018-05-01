files = dir('training_data');

borderData = {};
for i = 1:length(files)
    i
    if ~files(i).isdir && contains(files(i).name,'.mat') && ~isequal(files(i).name, 'borders_and_images.mat') && ~isequal(files(i).name, 'trained_data.mat')
        load(strcat('training_data\', files(i).name));
        
        vidName = strsplit(files(i).name, '.');
        vidName = cell2mat(vidName(1));
        if contains(vidName,'pre') || contains(vidName,'lombard') || contains(vidName,'adapt')
            vidPath = 'C:\Users\lucassalazar12\Videos\DSP\Lombard_video_8k fps\';
        else
            vidPath = 'C:\Users\lucassalazar12\Videos\DSP\Fondecyt videos 10k fps\';
        end
        
        vidObj = VideoReader(strcat(vidPath, vidName, '.avi'));
        s = struct('cdata', zeros(vidObj.Height, vidObj.Width, 3, 'uint8'), 'colormap', []);

        vidObj.CurrentTime = 0;
        for k = 1:cell2mat(correctBorders(1,2))
            s(k).cdata = readFrame(vidObj);         % Cuadros del video (imagenes)
        end
        
        borderData(end+1,1) = { cell2mat(correctBorders(1,1))};
        borderData(end,2) = { s(k).cdata };
        borderData(end,3) = { vidName };
        clear correctBorders
    end
end

save('training_data\borders_and_images.mat', 'borderData');