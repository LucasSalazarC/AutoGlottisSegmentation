addpath('./functions');

% Load training data
load('training_data/trained_data.mat');

config.vidName = 'FP010 - R14.avi';
config.vidPath = [ '/run/user/1000/gvfs/smb-share:server=vplab-storage.local,share=voicelab/Users/U00 - Common/'...
                   'Current Project/P003- P1151077/Data/FP010/L.E01/S01.Pro/R14 - Rigido  i/' ];
config.frames = 500;          % Number of frames to process

% Whether to save a copy of the video with the segmented boder drawn on top
config.saveVideo = false;     

% This is used as an ID for the video, and is saved in vidMetaData in the .mat
[~, fname, ~] = fileparts(config.vidName);
config.saveName = fname;

% Training data
trainingData.FDmatrix = FDmatrix;
trainingData.gndhisto = gndhisto;
trainingData.xaxis = xaxis;
trainingData.yaxis = yaxis;
trainingData.coef = coef;

tic
[outputContours, glottisAreas, vidMetaData] =  Segmentation(trainingData, config);
toc;