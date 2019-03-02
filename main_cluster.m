clear
close all

addpath('./functions');

% Load training data
load('training_data/trained_data.mat');
trainingData.FDmatrix = FDmatrix;
trainingData.gndhisto = gndhisto;
trainingData.xaxis = xaxis;
trainingData.yaxis = yaxis;
trainingData.coef = coef;

% findVideopaths function
addpath( '../Border Processing - Lucas/functions/' )
videoPaths = findVideoPaths( ['//run/user/1000/gvfs/smb-share:server=vplab-storage.local,share=voicelab/Users/'...
                                'U00 - Common/Current Project/P003- P1151077/Data'] );
parfor i = 1:length(videoPaths)
    
    % there are lots of duplicates of this video for some reason...
    if contains( videoPaths{i,2}, 'FP005_Naso_i_loud' ) && ~contains( videoPaths{i,3}, 'FP005' )
        continue
    end
    
%     % Ignore cut videos
%     if contains( videoPaths{i,2}, 'cut' )
%         continue
%     end
    
    
    config = [];
    
    % This is used as an ID for the video, and is saved in vidMetaData in the .mat
    [~, fname, ~] = fileparts(videoPaths{i,2});
    config.saveName = fname;
    
    % Skip already segmented videos
    if exist( ['./Output_contours/',  fname, '.mat'], 'file' ) == 2
        disp( [ fname, ' already exists' ] )
        continue
    end
            
        
    
    config.vidName = videoPaths{i,2};
    config.vidPath = [videoPaths{i,3}, filesep];
    config.frames = -1;          % Number of frames to process. -1 is whole video

    % Whether to save a copy of the video with the segmented boder drawn on top
    config.saveVideo = false;

    % Main segmentation function. Result is saved as a .mat in ./Output_contours/
    tic
    [outputContours, glottisAreas, vidMetaData] = Segmentation(trainingData, config);
    toc;
        
        
    % Get LR boders too
    saveLRData( outputContours, glottisAreas, vidMetaData, config.saveName );
end