vidName = 'FN007';
vidPath = 'C:\Users\lucassalazar12\Videos\DSP\all_videos\';

% Load training data
load('training_data\trained_data.mat');

tic
[outputContours,vidSize] =  Segmentation(vidName, vidPath, 44, FDmatrix, gndhisto, xaxis, yaxis, coef, true);
toc;