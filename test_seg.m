%% Simpler case

vidName = 'FP007';

if contains(vidName,'pre') || contains(vidName,'lombard') || contains(vidName,'adapt')
    vidPath = 'C:\Users\lucassalazar12\Videos\DSP\Lombard_video_8k fps\';
else
    vidPath = 'C:\Users\lucassalazar12\Videos\DSP\Fondecyt videos 10k fps\';
end

% Load training data
load('training_data\trained_data.mat');

tic
[outputContours,vidSize] =  Segmentation(vidName, vidPath, 44, FDmatrix, gndhisto, xaxis, yaxis, coef, 'red');
toc;

%% Complex case, with evaluation
vidName = 'FD003_pre';

if contains(vidName,'pre') || contains(vidName,'lombard') || contains(vidName,'adapt')
    vidPath = 'C:\Users\lucassalazar12\Videos\DSP\Lombard_video_8k fps\';
else
    vidPath = 'C:\Users\lucassalazar12\Videos\DSP\Fondecyt videos 10k fps\';
end

% Load training data
load('training_data\trained_data.mat');

% Load manual segmentation data for evaluation
load(strcat('manual_segmentation\',vidName,'.mat'));

frames = cell2mat(correctBorders(end,2)) + 44;
tic
[outputContours,vidSize] =  Segmentation(vidName, vidPath, frames, FDmatrix, gndhisto, xaxis, yaxis, coef);
time = toc;

dice_arr = [];
areaerror_arr = [];
for i = 1:size(correctBorders,1)
    correctBorder = cell2mat(correctBorders(i,1));
    frame_idx = cell2mat(correctBorders(i,2));

    segmentedBorder = cell2mat(outputContours(frame_idx));

    [dice,area_error] = compare_borders(correctBorder, segmentedBorder, vidSize); 
    dice_arr(end+1) = dice;
    areaerror_arr(end+1) = area_error;
end

% Pretty Print

fprintf('\n\n----------------------------------------------------------------------------------------\n\n');
fprintf('Dice coefficients and Area Error:\n\n');

fprintf('%s\n', vidName);

fprintf('Dice: %0.4f || ', mean(dice_arr));
for j = 1:length(dice_arr)
    fprintf('%0.4f ', dice_arr(j));
end
fprintf('\n');

fprintf('Area: %0.4f || ', mean(areaerror_arr));
for j = 1:length(areaerror_arr)
    fprintf('%0.4f ', areaerror_arr(j));
end
fprintf('\n');

fprintf('Elapsed Time = %0.4f seconds; Per frame = %0.4 seconds\n', time, time/frames);
fprintf('\n\n');
    
    
    
    
    
    
    