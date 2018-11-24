vidName = 'FN001';
% vidPath = 'C:\Users\lucassalazar12\Videos\DSP\all_videos\';
vidPath = '/run/user/1000/gvfs/smb-share:server=vplab-storage.local,share=voicelab/Users/U00 - Common/Current Project/P003- P1151077/Data/FN001/L.E01/S01.Pro/R03- Naso i/';

% Load training data
load('training_data/trained_data.mat');

frames = 88;
saveVideo = false;
saveName = 'FN001 - R03';

tic
[outputContours,vidSize] =  Segmentation(vidName, vidPath, frames, FDmatrix, gndhisto, xaxis, yaxis, coef, saveVideo, saveName);
toc;