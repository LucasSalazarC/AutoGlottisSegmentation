vidPath = 'C:\Users\lucassalazar12\Videos\DSP\all_videos\';
files = dir(vidPath);

graySourceList = {'green', 'rgb2gray'};


for k = 1:length(graySourceList)
    build_training_dataset( graySourceList{k} );
    
    for i = 1:length(files)
        if ~files(i).isdir && contains(files(i).name,'.avi')

            vidName = files(i).name;
            vidName = vidName(1:end-4);

            % Train without video we are processing
            [coef, FDmatrix, gndhisto, xaxis, yaxis] = Training( string(vidName) );

            tic
            [outputContours,vidSize] =  Segmentation(vidName, vidPath, 88, FDmatrix, gndhisto, xaxis, yaxis, coef, graySourceList{k});
            time = toc;

            fprintf('Elapsed Time = %0.4f seconds; Per frame = %0.4f seconds\n', time, time/500);
        end
    end
end






















