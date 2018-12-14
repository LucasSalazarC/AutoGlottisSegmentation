% Load training data
load('training_data/trained_data.mat');

config.vidName = 'FN001.avi';
config.vidPath = [ '/run/user/1000/gvfs/smb-share:server=vplab-storage.local,share=voicelab/Users/U00 - Common/'...
                   'Current Project/P003- P1151077/Data/FN001/L.E01/S01.Pro/R14 - Rigido  i/' ];
config.realFrameRate = 10000;

config.frames = 500;
config.saveVideo = false;
config.saveName = 'FN001 - R14';

trainingData.FDmatrix = FDmatrix;
trainingData.gndhisto = gndhisto;
trainingData.xaxis = xaxis;
trainingData.yaxis = yaxis;
trainingData.coef = coef;

tic
[outputContours,vidSize] =  Segmentation(trainingData, config);
toc;