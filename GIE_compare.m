vidList = {'FN003', 'FN007', 'FP007', 'FP016', 'FN003_naso', 'FP005_naso', 'FP011_naso', 'FD003_pre', 'FN003_lombard', 'MN003_adapt'};

channel = 'green';

evaluationData = cell(length(vidList),3);

for j = 1:length(vidList)
    vidName = cell2mat(vidList(j));
    evaluationData(j,1) = {vidName};

    % Load manual segmentation data for comparison
    load(strcat('manual_segmentation\',vidName,'.mat'));
    
    % Load video resize data
    % name, scale_factor, padTop, padLeft, vidSize
    load(strcat('GIE_segdata\', vidName, '_resizedata.mat'));
    scaleFactor = resizeData{2};
    padTop = resizeData{3};
    padLeft = resizeData{4};
    vidSize = resizeData{5};
    
    % Read segmentation data from text file
    if isempty(channel)
        text_file = fopen( sprintf('GIE_segdata\\%s_segdata.txt', vidName), 'r' );
    else
        text_file = fopen( sprintf('GIE_segdata\\%s_%s_segdata.txt', channel, vidName), 'r' );
    end
    lines = textscan(text_file, '%s', 'delimiter', '\n');
    lines = lines{1};
    fclose(text_file);
    
    gieContours = {};
    
    for i = 2:2:length(lines)
        if i == length(lines)
            continue
        end
        
        leftSide = str2num(lines{i})';
        rightSide = str2num(lines{i+1})';
        
        contour = [];
        
        % format: [x,y]
        for k = 1:256
            if leftSide(k) ~= 0
                contour(end+1,:) = [leftSide(k) k];
            end
        end
        for k = 256:-1:1
            if rightSide(k) ~= 0
                contour(end+1,:) = [rightSide(k) k];
            end
        end
        
        if ~isempty(contour)          
            % Return contour to original size
            contour = round(contour / scaleFactor);
            if padTop
                contour(:,2) = contour(:,2) - padTop + 1;
            end
            if padLeft
                contour(:,1) = contour(:,1) - padLeft + 1;
            end
        end
        
        
        % Contour needs to be closed
        closedContour = [];
        
        for k = 1:length(contour)
            if ~isempty(closedContour) && ( abs(closedContour(end,1) - contour(k,1)) > 1 || abs(closedContour(end,2) - contour(k,2)) > 1 )
                [xb,yb] = bresenham(closedContour(end,1), closedContour(end,2), contour(k,1), contour(k,2));
                closedContour = [closedContour; [xb yb]];
            else
                closedContour(end+1,:) = [contour(k,1) contour(k,2)];
            end
        end
        
        % Join last point with first point
        if ~isempty(closedContour) && ( abs(closedContour(end,1) - closedContour(1,1)) > 1 || abs(closedContour(end,2) - closedContour(1,2)) > 1 )
            [xb,yb] = bresenham(closedContour(end,1), closedContour(end,2), closedContour(1,1), closedContour(1,2));
            closedContour = [closedContour; [xb yb]];
        end
        
        gieContours(end+1) = {closedContour};
        
%         plot(closedContour(:,1), closedContour(:,2), '*'), axis ij, axis equal
%         waitforbuttonpress
        
    end

    dice_arr = [];
    areaerror_arr = [];
    for i = 1:size(correctBorders,1)
        correctBorder = cell2mat(correctBorders(i,1));
        frame_idx = cell2mat(correctBorders(i,2));
        
        gieBorder = gieContours{frame_idx};

        [dice,area_error] = compare_borders(correctBorder, gieBorder, vidSize); 
        dice_arr(end+1) = dice;
        areaerror_arr(end+1) = area_error;
        
%         hold off
%         plot(correctBorder(:,1), correctBorder(:,2), 'r*'), hold on, axis equal, axis ij
%         if ~isempty(gieBorder)
%             plot(gieBorder(:,1), gieBorder(:,2), 'b*')
%         else
%             fprintf('WARNING: Empty border\n');
%         end
%         
%         dice
%         a = 0;
    end

    evaluationData(j,2) = {dice_arr};
    evaluationData(j,3) = {areaerror_arr};

    fprintf('Video: %s\n', vidName);
    fprintf('Mean Dice Coefficient = %f\n', mean(dice_arr));
    fprintf('Mean Area Error = %f\n', mean(areaerror_arr));
end

if isempty(channel)
    fileID = fopen('GIE_segdata\\GIE_results.txt', 'w');
else
    fileID = fopen(sprintf('GIE_segdata\\GIE_%s_results.txt', channel), 'w');
end

fprintf('----------------------------------------------------------------------------------------\n\n');
fprintf('Dice coefficients and Area Error. Format:\n');
fprintf('Type: Mean   Median StdDev || Values for each frame\n\n');
fprintf(fileID, 'Dice coefficients and Area Error. Format:\n');
fprintf(fileID, 'Type: Mean   Median StdDev || Values for each frame\n\n');
for i = 1:size(evaluationData,1)
    name = cell2mat(evaluationData(i,1));
    fprintf('%s\n', name);
    fprintf(fileID, '%s\n', name);
    
    diceCoefs = cell2mat(evaluationData(i,2));
    fprintf('Dice: %0.4f %0.4f %0.4f || ', mean(diceCoefs), median(diceCoefs), std(diceCoefs));
    fprintf(fileID, 'Dice: %0.4f %0.4f %0.4f || ', mean(diceCoefs), median(diceCoefs), std(diceCoefs));
    for j = 1:length(diceCoefs)
        fprintf('%0.4f ', diceCoefs(j));
        fprintf(fileID, '%0.4f ', diceCoefs(j));
    end
    fprintf('\n');
    fprintf(fileID, '\n');
    
    areaErrors = cell2mat(evaluationData(i,3));
    fprintf('Area: %0.4f %0.4f %0.4f || ', mean(areaErrors), median(areaErrors), std(areaErrors));
    fprintf(fileID, 'Area: %0.4f %0.4f %0.4f || ', mean(areaErrors), median(areaErrors), std(areaErrors));
    for j = 1:length(areaErrors)
        fprintf('%0.4f ', areaErrors(j));
        fprintf(fileID, '%0.4f ', areaErrors(j));
    end
    fprintf('\n\n\n');
    fprintf(fileID, '\n\n\n');
end

fclose(fileID);