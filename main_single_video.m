
% Load training data
load('training_data/trained_data.mat');

config.vidName = '2kPa, 0.01 shim.mp4';
config.vidPath = '/run/user/1000/gvfs/smb-share:server=vplab-storage.local,share=voicelab/Users/U00 - Common/Current Project/P010- HSV Clarkson/Contact Stress/';
config.frames = 88;
config.saveVideo = false;
config.saveName = 'FN001 - R14';
config.graySource = 'gray';

trainingData.FDmatrix = FDmatrix;
trainingData.gndhisto = gndhisto;
trainingData.xaxis = xaxis;
trainingData.yaxis = yaxis;
trainingData.coef = coef;

% tic
% [outputContours,vidSize] =  Segmentation(vidName, vidPath, 88, FDmatrix, gndhisto, xaxis, yaxis, coef, graySourceList{k});
% toc

vid = VideoReader([vidPath vidName]);