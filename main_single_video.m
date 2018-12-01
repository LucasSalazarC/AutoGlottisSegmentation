% vidName = 'FN001';
% vidPath = '/run/user/1000/gvfs/smb-share:server=vplab-storage.local,share=voicelab/Users/U00 - Common/Current Project/P003- P1151077/Data/FN001/L.E01/S01.Pro/R03- Naso i/';

vidName = '2kPa, 0.01 shim.mp4';
vidPath = '/run/user/1000/gvfs/smb-share:server=vplab-storage.local,share=voicelab/Users/U00 - Common/Current Project/P010- HSV Clarkson/Contact Stress/';

% Load training data
load('training_data/trained_data.mat');

frames = 88;
saveVideo = false;
saveName = '2kPa, 0.01 shim';

tic
[outputContours,vidSize] =  Segmentation(vidName, vidPath, frames, FDmatrix, gndhisto, xaxis, yaxis, coef, saveVideo, saveName);
toc;