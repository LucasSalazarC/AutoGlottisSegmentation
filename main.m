vidList = {'FN003', 'FN007', 'FP007', 'FP016', 'FN003_naso', 'FP005_naso', 'FP011_naso', 'FD003_pre', 'FN003_lombard', 'MN003_adapt'};

evaluationData = cell(length(vidList),3);

for j = 1:length(vidList)
    vidName = cell2mat(vidList(j));
    evaluationData(j,1) = {vidName};
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
    [outputContours,vidSize] =  Segmentation(vidName, vidPath, frames, FDmatrix, gndhisto, xaxis, yaxis, coef);

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

    evaluationData(j,2) = {dice_arr};
    evaluationData(j,3) = {areaerror_arr};

    fprintf('Video: %s\n', vidName);
    fprintf('Mean Dice Coefficient = %f\n', mean(dice_arr));
    fprintf('Mean Area Error = %f\n', mean(areaerror_arr));
end

currDateTime = datestr(datetime);
currDateTime(regexp(currDateTime,'[:]')) = [];
save(strcat('Output_contours\', currDateTime, '.mat'), 'evaluationData');

%% Pretty Print

fprintf('----------------------------------------------------------------------------------------\n\n');
fprintf('Dice coefficients and Area Error:\n\n');
for i = 1:size(evaluationData,1)
    name = cell2mat(evaluationData(i,1));
    fprintf('%s\n', name);
    
    diceCoefs = cell2mat(evaluationData(i,2));
    fprintf('Dice: %0.4f || ', mean(diceCoefs));
    for j = 1:length(diceCoefs)
        fprintf('%0.4f ', diceCoefs(j));
    end
    fprintf('\n');
    
    areaErrors = cell2mat(evaluationData(i,3));
    fprintf('Area: %0.4f || ', mean(areaErrors));
    for j = 1:length(areaErrors)
        fprintf('%0.4f ', areaErrors(j));
    end
    fprintf('\n\n');
end





















