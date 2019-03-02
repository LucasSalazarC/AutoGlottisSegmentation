clear
close all

addpath('./functions');

% Load training data
load('training_data/trained_data.mat');

config.vidName = 'FN001_comfortable_resize.avi';
config.vidPath = [ '/run/user/1000/gvfs/smb-share:server=vplab-storage.local,share=voicelab/Users/U00 - Common/'...
                   'Current Project/P003- P1151077/Data/Force/' ];
config.frames = 100;          % Number of frames to process

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



%% Get LR boders too
saveLRData( outputContours, glottisAreas, vidMetaData, config.saveName );