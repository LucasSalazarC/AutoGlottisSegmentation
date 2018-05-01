
filename = 'FP014_naso.mat';
load(strcat('training_data\', filename));

correctBorders(1,1) = { flipud( cell2mat(correctBorders(1,1)) ) };

save(strcat('training_data\', filename), 'correctBorders');