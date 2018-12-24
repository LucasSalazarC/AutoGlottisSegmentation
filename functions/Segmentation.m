function [outputContours, glottisAreas, vidMetaData] =  Segmentation(trainingData, config)

% Inputs:
%   config.vidName -> Video name, with extension
%   config.vidPath -> Path to video, with slash at the end
%   config.frames -> Numero of frames to process
%   config.realFrameRate -> Original HSV framerate
%   config.saveVideo -> Bool to indicate if we want to save a copy of the
%                       video with the contour drawed on it 
%   config.saveName -> Name of the output .mat containing the segmented
%                      border to be saved in ./Output_contours/
%   trainingData.FDmatrix -> Each row is a fourier descriptor
%   trainingData.gndhisto -> 2D GND Histogram
%   trainingData.xaxis -> Histogram x axis (first component)
%   trainingData.yaxis -> Histogram y axis (second component)
%   trainingData.coef -> PCA coefficients to reduce GND dimensionality


%% Open and read video data
vidObj = VideoReader( [config.vidPath  config.vidName] );
vidHeight = vidObj.Height;
vidWidth = vidObj.Width;
s = struct('cdata',zeros(vidHeight,vidWidth,3,'uint8'),'colormap',[]);

vidMetaData = [vidHeight vidWidth];

k = 1;
startTime = 0;
vidObj.CurrentTime = startTime;
endTime = startTime + config.frames/vidObj.FrameRate;
while vidObj.CurrentTime <= endTime
    s(k).cdata = readFrame(vidObj);
    k = k+1;
end

% waitforbuttonpress

%% Processing: Recognition part

[nImages,~] = size(trainingData.FDmatrix);       % Number of training images

fdthresh = 6;        % Fourier Descriptor Dissimilarity threshold
gndthresh = 0.4;        % GND threshold
roithresh = 0.6;

% Find maximum x-value for probability > gndthresh
for i = size(trainingData.gndhisto,2):-1:1
    colmax = max(trainingData.gndhisto(:,i));
    
    if colmax >= 0.99
        break
    end
end

gnd_max_x = trainingData.xaxis(i);

% Cell to save recognized glottis borders
recGlottis = {};

waitsm = 0;
waitlg = 0;
waitseg = 0;

% To save initial ROI
roiToSave = [];


for i = 1:length(s)
    fprintf('\n-----------------------------------------------\n----------------------------------------------\n');
    fprintf('Analyzing frame %d\n', i);
    
    % To save potential glottis border index
    thrindex = 0;
    bestDsim = inf;
    
    
    % Get ROI based on pixel variance over 100 frames. Recalculate every 100 frames
    if i == 1 || ( mod(i,100) == 1 && length(s) - i > 99 )
        [tempInitialRoiMask, tempInitialRoiBorder, tempRoiObj] = variance_roi(s, i);

        if tempRoiObj == -1
            if i == 1
                fprintf('ROI calculation Failed\n');
                recGlottis = [];
                break
            end
            % If roi calculation fails but a ROI was already calculated previously, use the previous one
        else
            initialRoiMask = tempInitialRoiMask;
            initialRoiBorder = tempInitialRoiBorder;
            roiObj = tempRoiObj;
            notInRoi = imcomplement(initialRoiMask);
            
            % Save ROI
            if i == 1
                % format [y,x]
                roiMinTemp = min(initialRoiBorder);
                roiMaxTemp = max(initialRoiBorder);
                
                roiToSave.yRange = [ roiMinTemp(1) roiMaxTemp(1) ];
                roiToSave.xRange = [ roiMinTemp(2) roiMaxTemp(2) ];
                
            end
        end

        figure(9), imshow(imoverlay(s(1).cdata, roiObj, [0 1 0])), hold on
        plot(initialRoiBorder(:,2), initialRoiBorder(:,1), 'y*', 'MarkerSize', 1), hold off

    end
    
    
    % Remove black areas on the edges of the video
    blackMask = im2bw(s(i).cdata, 15/255);
    blackMask = imcomplement(blackMask);

    se = strel('disk', 1);
    blackMask = imdilate(blackMask, se);

    allBorders = bwboundaries(blackMask);
    for k = 1:length(allBorders)
        B = allBorders{k};              % Clockwise order
        B = fliplr(B);                  % x -> columna 1, y -> columna 2

        % Filter shapes not touching the edge of the image
        if check_out_of_bounds(B, vidMetaData, 'image')
            continue
        end

        objectMask = false(vidMetaData);
        for j = 1:length(B)
            objectMask( B(j,2), B(j,1) ) = true;
        end
        objectMask = imfill(objectMask, 'holes');

        blackMask = blackMask & ~objectMask;
    end
    
%     % For testing purposes
%     figure(21)
%     image(s(i).cdata)
%     hold on
    
    % Threshold increases from 1 to 80. Search for glottis-like figures
    for j = 1:80
        threshframe = im2bw(s(i).cdata, j/255);
        threshframe = imcomplement(threshframe);

        % Opening
        se = strel('disk',1);
        openedframe = imopen(threshframe,se);
        
        % Borders
        allBorders = bwboundaries(openedframe, 'noholes');
        for k = 1:length(allBorders)
            B = allBorders{k};              % Clockwise order
            B = flipud(B);                  % Counterclockwise
            B = fliplr(B);                  % x -> columna 1, y -> columna 2
            
%             % For testing purposes
%             fprintf('L = %d\n', length(B));

            % Filter shapes too small, too big, or touching the edge of the image
            if length(B) < 30 || length(B) > 500 || check_out_of_bounds(B, size(openedframe), 'image')
                continue
            end

            
            objectMask = false(vidMetaData);
            for n = 1:length(B)
                objectMask( B(n,2), B(n,1) ) = true;
            end
            objectMask = imfill(objectMask, 'holes');
            
%             % Object centroid
%             [objR, objC] = find(objectMask == 1);
%             objCentroid = round(mean([objR objC]));
            
            objOverlap = sum(sum( roiObj & objectMask ));
            newObjSize = sum(sum(objectMask));

%             fprintf('NewObj overlap = %f, RoiObj overlap = %f\n', objOverlap/newObjSize, objOverlap/roiObjSize);

            % Filter objects not completely inside ROI mask or whose overlap with ROI
            % object is not high
            if objOverlap / newObjSize < roithresh || sum(sum( notInRoi & objectMask )) > 0
                continue
            end
            
            % Filter shapes touching the black area at the edge of the image
            if sum(sum( blackMask & objectMask )) > 0
                continue
            end
         
            % Calculate Fourier descriptors
            [FD,~,~] = fourierDescriptors(B,30);
            
            % Compare with training FD (squared norm)
            normMean = 0;
            for p = 1:nImages
                normMean = normMean + norm(FD.' - trainingData.FDmatrix(p,:))^2;
            end
            normMean = normMean / nImages;
            
            if normMean < bestDsim
                thrindex = j;
                bestDsim = normMean;
                bestB = B;
            end
            
%             % For testing purposes
%             fprintf('T = %d; B %d; FDsim = %f; L = %d\n', j, k, normMean, length(B));
%             plot(B(:,1), B(:,2), 'y*', 'Markersize', 0.5)
%             waitforbuttonpress
%             unplot
        end
        
        % Evaluate potantial borders, if there are any
%         if bindex ~= 0
%             fprintf('Potencial borde de glotis encontrado!\n');
%             break
%         end
    end
    
    if thrindex(1) == 0 || bestDsim > fdthresh
        fprintf('No potential glottis borders were found in this frame\n\n');
    else      
        fprintf('Potential glottis border found!\n');
        fprintf('Threshold = %d, Dissimilarity = %f\n', thrindex, bestDsim);
        
        figure(1)
        hold off
        image(s(i).cdata)
        axis image
        
        hold on
        plot(bestB(:,1), bestB(:,2), 'y*', 'MarkerSize', 0.5)
        pause(waitlg);
        
%         % Testing purposes
%         save('test\lgd_testdata2.mat');
        
        % format [y,x]
        roiMinCoord = min(initialRoiBorder);
        roiMaxCoord = max(initialRoiBorder);

        origImage = rgb2gray(s(i).cdata);
        
        % Crop image to ROI
        lgdImage = origImage(roiMinCoord(1):roiMaxCoord(1),roiMinCoord(2):roiMaxCoord(2));

        % Change coordinates to cropped image
        bestB(:,1) = bestB(:,1) - roiMinCoord(2) + 1;
        bestB(:,2) = bestB(:,2) - roiMinCoord(1) + 1;
        
        
        %%% TESTING
        %save('test\lgd_testdata2', 'bestB', 'lgdImage');
        
        % Apply contour adjusting algorithm
        fprintf('Adjusting contour...\n');
        c = contourLGD(bestB, lgdImage, 350);       % Variable c es el contorno
        
        % Return to original coordinates
        c(:,1) = c(:,1) + roiMinCoord(2) - 1;
        c(:,2) = c(:,2) + roiMinCoord(1) - 1;
        
        % Fitler out of bounds
        if check_out_of_bounds(c, size(lgdImage), 'image')
            fprintf('Not in ROI; Out of bounds. False Region\n');
            continue
        end
        
%         % Apply contour adjusting algorithm
%         fprintf('Ajustando contorno...\n');
%         c = contourLGD(bestB, rgb2gray(s(i).cdata), 350);       % Variable c es el contorno
        
        plot(c(:,1), c(:,2), 'g*', 'MarkerSize', 0.5)
        
        % Border must be in counterclockwise order. Y axis is inverted, so we negate the output of
        % ispolycw function.
        if ~ispolycw(c(:,1), c(:,2))
            c = flipud(c);
        end
        
        % Need at least 30 values for FD
        if length(c) < 30
            fprintf('False Region. Algorithm continues...\n\n');
            pause(waitsm);
            continue
        end
        
        objectMask = false(vidMetaData);
        cRound = round(c);
        for n = 1:length(cRound)
            cm = max(cRound(n,2), 1);
            cm = min(cm, vidHeight);
            cn = max(cRound(n,1), 1);
            cn = min(cn, vidWidth);
            objectMask( cm, cn ) = true;
        end
        objectMask = imfill(objectMask, 'holes');
        
        objOverlap = sum(sum( roiObj & objectMask ));
        newObjSize = sum(sum(objectMask));

        % Filter objects not completely inside ROI mask or whose overlap with ROI
        % object is not high
        if objOverlap / newObjSize < roithresh || sum(sum( notInRoi & objectMask )) > 0
            fprintf('Not in ROI. False Region\n');
            continue
        end
        
        
        % Calculate and evaluate Fourier descriptors again
        [FD,idxlow,idxhigh] = fourierDescriptors(c,30);
        normMean = 0;
        for p = 1:nImages
            normMean = normMean + norm(FD.' - trainingData.FDmatrix(p,:))^2;
        end
        normMean = normMean / nImages;

        fprintf('Dissimilarity: %f\n', normMean);
        pause(waitlg);
        if normMean < fdthresh
            fprintf('Frame %d: Glottis shape confirmed! Evaluating GND...\n\n', i);
            pause(waitsm);
            
            % Generate binary image from the contour
            binShape = false(size(threshframe));
            for j = 1:length(c)
                cm = max(round(c(j,2)), 1);
                cm = min(cm, vidHeight);
                cn = max(round(c(j,1)), 1);
                cn = min(cn, vidWidth);
                binShape(cm, cn) = true;
            end
            binShape = imfill(binShape, 'holes');
            binShape = imcomplement(binShape);
            
            % Calculate and reduce GND with training PCA coefficients.
            % Then, map to histogram
            GND = getGND(s(i).cdata, binShape, round(c), idxlow, idxhigh);
            decomp = GND * trainingData.coef
            
            % decomp(1) is approximately the norm of average intensity difference between the inside
            % and outside of the contour. If it is high enough, we can just skip comparisons and
            % mark it as a glottis.
            if decomp(1) > gnd_max_x
                prob = 0.99;
                normMean = 0.01 + normMean/100;
            else
                [~,xindex] = min(abs(trainingData.xaxis-decomp(1)));
                [~,yindex] = min(abs(trainingData.yaxis-decomp(2)));
                prob = trainingData.gndhisto(yindex,xindex);
            end
            
            g = sprintf('%f ', GND);
            fprintf('GND %d: %s\n', i, g);
            fprintf('Glottis probability = %f\n\n', prob);
            
            if prob > gndthresh
                fprintf('Glottis confirmed!\n\n');
                recGlottis(end+1,:) = {i, c, binShape, normMean, prob};
                pause(waitlg);
            else
                fprintf('False Region. Algorithm continues...\n\n');
            end
        else
            fprintf('False Region. Algorithm continues...\n\n');
            pause(waitsm);
        end
    end
end

if isempty(recGlottis)
    fprintf('Algorithm failed. No glottis found\n');
    outputContours = cell(config.frames,1);
    return
end


fprintf('------------------------------------------\n');
fprintf('------------------------------------------\n');
fprintf('Regognition part is done! Proceeding with segmentation...\n\n');
pause(waitseg)

%% Segmentation part

% To indicate wether a frame has been segmented or not
frameflag = false(length(s), 1);

% To save video frames
if config.saveVideo 
    segvideo = cell(length(s),1);
end
outputContours = cell(config.frames,1);

% This one will contain an array of cells for each frame with sub-borders
% in case the glottis is split
separatedContours = cell(config.frames,1);

% To save areas, and find frame with maximum glottal opening
glottisAreas = zeros(config.frames, 1);

% Sort by FD dissimilarity
recGlottis = sortrows(recGlottis, 4);

for i = 1:size(recGlottis,1)
    
    % Check if frame is already segmented
    if frameflag(cell2mat(recGlottis(i,1)))
        continue
    end
    
    % To keep track of segmented frames in each cycle
    cycleFrames = [];   
    
    % Data of the border with the lowest dissimilarity
    prevframe = cell2mat(recGlottis(i,1));
    border = round(cell2mat(recGlottis(i,2)));
    shape = cell2mat(recGlottis(i,3));    % Glottis are 0s, the rest is 1
    
    % Starting frame is already segmented
    frameflag(prevframe) = true;
    cycleFrames(end+1) = prevframe;
    
    % Save starting frame
    vidFrame = s(prevframe).cdata;
    for j = 1:length(border)
        m = max(border(j,2), 1);
        m = min(m, vidHeight);
        n = max(border(j,1), 1);
        n = min(n, vidWidth);

        vidFrame(m,n,1) = 0;
        vidFrame(m,n,2) = 255;
        vidFrame(m,n,3) = 0;
    end
    if config.saveVideo
        segvideo(prevframe) = {vidFrame};
    end
    outputContours(prevframe) = { border };
    separatedContours(prevframe) = { fliplr(border) };
    glottisAreas(prevframe) = sum(sum( ~shape ));
    
    fprintf('\nBeginning with frame %d...\n', prevframe);
    
    % Begin in backwards time direction, unless we're at the beginning of
    % the video
    if prevframe == 1
        direction = 1;
    else
        direction  = -1;
    end
    
    curframe = prevframe + direction;
    
    % Loop until no glottis frames are left in the current vibration cycle
    while direction ~= 0
        
        % Length of border segmented for this frame
        N = 0;
        
        % If frame is already segmented we have a collision and we need to resolve it.
        if frameflag(curframe)
            % curBorder format: (x,y)
            curBorder = cell2mat(outputContours(curframe));
            curMask = false(size(shape));
            for j = 1:length(curBorder)
                cmm = max(curBorder(j,2), 1);
                cmm = min(cmm, vidHeight);
                cmn = max(curBorder(j,1), 1);
                cmn = min(cmn, vidWidth);
                curMask( cmm, cmn ) = true;
            end
            curMask = imfill(curMask, 'holes');
            
            intersection = curMask & ~shape;
            
            % If intersection is empty, the segmentations don't match. We assume the first
            % segmentation was correct and discard our progress in the current cycle.
            if sum(sum(intersection)) == 0
                for j = 1:length(cycleFrames)
                    
                    outputContours(cycleFrames(j)) = {[]};
                    separatedContours(cycleFrames(j)) = {[]};
                    glottisAreas(cycleFrames(j)) = 0;
                    
                    if config.saveVideo
                        segvideo(cycleFrames(j)) = {s(cycleFrames(j)).cdata};
                    end
                end
                fprintf('Collision detected. Erasing progress of this cycle...\n\n');
                break
            end
                
            % If the segmentations match, we skip to the end marking no glottis detected (when
            % actually there is one that was previously segmented). This tells the algorithm we
            % reached the end of the cycle in the current direction.
                  
        % No collisions. Proceed normally.
        else
            if prevframe ~= cell2mat(recGlottis(i,1))
                % Need to calculate prevframe parameters again. Many variables
                % are defined later...

                % Use biggest segmented border as glottis region
                % NEED TO FIX THIS LATER
                % What if there is more than one object?
%                 bmax = 0;
%                 for j = 1:length(glotborders)
%                     temp = glotborders{j};
%                     if length(temp) > bmax
%                         border = temp;
%                         bmax = length(temp);
%                     end
%                 end
%                 border = fliplr(border);
                
                % border is in format (x,y)
                border = ctr;
                if ~ispolycw(border(:,1), border(:,2))
                    border = flipud(border);
                end

                shape = imcomplement(pseg); 
            end


            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%% ROI: REGION OF INTEREST %%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%             figure(1)
%             hold off
%             image(s(curframe).cdata)
%             axis image
%             pause(waitsm)


            % Puntos dentro de la glotis
            [rg,cg] = find(shape == false);
            pixMean = [mean(rg) mean(cg)];
            pixCov = cov(rg,cg);

            if ~all(eig(pixCov) > eps)    % pixCov not positive-definite. Calculate roi by hand
                rini = min(rg) - 7;
                rfin = max(rg) + 7;
                cini = min(cg) - 4;
                cfin = max(cg) + 4;

                % Don't go beyond the image boundaries
                if rini < 1
                    rini = 1;
                end
                if cini < 1
                    cini = 1;
                end
                [maxr,maxc] = size(shape);
                if rfin > maxr
                    rfin = maxr;
                end
                if cfin > maxc
                    cfin = maxc;
                end

                % rpts: points inside the roi, but outside the glottis
                roilen = (rfin-rini+1) * (cfin-cini+1) - length(rg);
                rpts = zeros(roilen,2);

                tempglot = [cg rg];
                j = 1;
                for r = rini:rfin
                    for c = cini:cfin
                        if ~ismember([c r], tempglot, 'rows')
                            rpts(j,:) = [c r];
                            j = j+1;
                        end
                    end
                end
            else
                [r,c] = find(shape == true);

                % Calculate ROI: Mahalanobis distance 4.5
                roi = rangesearch([r c], pixMean, 4.5, 'Distance', 'mahalanobis', 'Cov', pixCov);
                roi = cell2mat(roi);
                rpts = [c(roi) r(roi)];     % Points inside the ROI, but outside the glottis
            end

            roimask = ~shape;   % Only inside the glottis
            for j = 1:length(rpts)
                roimask(rpts(j,2), rpts(j,1)) = true;
            end

%             figure(4)
%             hold off
%             image(s(prevframe).cdata)
%             hold on
%             plot(border(:,1), border(:,2), 'g*', 'MarkerSize', 0.5)
%             plot(c(roi), r(roi), 'y*', 'MarkerSize', 0.5)
%             %image(roimask)
%             %colormap(gray(2))





            %%%%%%%%%%%%%%%%%%%%%%%%%
            %%%% PROBABILITY IMAGE %%
            %%%%%%%%%%%%%%%%%%%%%%%%%

%             % Save data for further testing
%             save(char("test\pimage_testdata_new_" + vidName + ".mat"));

            % Calculate 3D hsitogram for N points in the border
            % Mapping to quantize colors
            quantize = 2;
            vecmap = 0:255;
            vecmap = vecmap';
            vecmap(:,2) = floor(vecmap(:,1)/quantize);

            npoints = 6;
            filtsigma = 3;
            [histos, ~, ~,~,~] = colorhist2(s(prevframe).cdata, shape, border, roimask, vecmap, npoints, filtsigma);
            bpoints = cell2mat(histos(:,1));

            % Closest base points for each ROI point
            rpts = [rpts; [cg rg]];    % Now it's the entire ROI, including the glottis
            idxs = dsearchn(bpoints, rpts);

            % Calculate probability image
            I = s(curframe).cdata;
            pimage = zeros(size(shape));
            for j = 1:length(rpts)
                color = double(reshape(I(rpts(j,2),rpts(j,1),:),1,3))/quantize;
                idx = idxs(j);

                histobg = cell2mat(histos(idx,2));
                histoglot = cell2mat(histos(idx,3));

                if quantize == 1
                    color = color + 1;
                    bglike = histobg(color(1), color(2), color(3));
                    glotlike = histoglot(color(1), color(2), color(3));
                else
                    bglike = trilinear_interp2(color, histobg, vecmap);
                    glotlike = trilinear_interp2(color, histoglot, vecmap);
                end

                if bglike < 0
                    bglike = 0;
                end

                pglot = 0.4;
                pbg = 0.6;

                postprob = glotlike*pglot / (bglike*pbg + glotlike*pglot);
                if postprob < 0
                    pimage(rpts(j,2), rpts(j,1)) = 0;
                else
                    pimage(rpts(j,2), rpts(j,1)) = postprob * 255;
                end
            end

            pimage = uint8(pimage);
%             figure(10)
%             image(pimage); title('Probability Image'); colormap(gray(255));





            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%% LEVEL-SET SEGMENTATION %%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            pbinimg = im2bw(pimage, 220/255);
            se = strel('disk',1);
            pbinimg = imopen(pbinimg,se);


            % Level-set segmentation
            pseg = lucas_chenvese(pimage, pbinimg, 300, false, 1*255^2, 6);
            pseg = imfill(pseg, 'holes');


            % Plot
            figure(5)
            subplot(2,3,1); imshow(I); title('Frame')
            subplot(2,3,3); imshow(pimage); title('Probability Image')
            subplot(2,3,4); imshow(pbinimg); title('Threshold')
            subplot(2,3,5); imshow(pseg); title('Level-set segmentation')

%             imshow(pseg)
%             pause(waitsm)




            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%% GLOTTAL RECTANGULAR AREA %%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            % Remember that [rg,cg] contains coordinates of glottis points in previous
            % frame
            gcoef = pca([rg cg]);
            gaxis = gcoef(:,1);
            normaxis = gcoef(:,2);

            % Project previous frame points onto normal glottal axis
            prevproj = [rg cg] * normaxis;
            pmax = max(prevproj);
            pmin = min(prevproj);

            % Label objects in new segmented image, then get their projections. Objects
            % whose projections don't overlap with the previous frame projection are
            % removed.
            % EDIT: Added other criteria
            [labels, num] = bwlabel(pseg);
            newproj = cell(num,3);
            for j = 1:num
                [objr, objc] = find(labels == j);
                horproj = [objr objc] * normaxis;
                vertproj = [objr objc] * gaxis;

                prevwidth = pmax - pmin;
                objwidth = max(horproj) - min(horproj);
                objheight = max(vertproj) - min(vertproj);
                objctr = mean(horproj);

                roiborder = bwboundaries(roimask);
                roiborder = cell2mat(roiborder(1));
                touches_roi = check_out_of_bounds([objr objc], roiborder, 'roi');

                outofrange = (objctr > pmax - prevwidth*0.15) | (objctr < pmin + prevwidth*0.15);
                toobig = (objwidth > objheight) && (objwidth > prevwidth);
                toosmall = (length(objr) < 10);
                toowide = objwidth > 2*objheight;

                val = outofrange || toosmall || toobig || touches_roi || toowide;
                if val
                    obj = (labels == j);
                    pseg = pseg & ~obj;
                end

                if touches_roi
                    fprintf('GRA %d: Roi collision\n', j);
                end
                if outofrange
                    fprintf('GRA %d: Out of range\n', j);
                end
                if toosmall 
                    fprintf('GRA %d: Too small\n', j);
                end
                if toobig 
                    fprintf('GRA %d: Too big\n', j);
                end
                if toowide
                    fprintf('GRA %d: Too wide\n', j);
                end

                newproj(j,:) = {horproj, vertproj, ~val};
            end



            subplot(2,3,6); imshow(pseg); title('GRA correction')
            % Make sure everything is inside the ROI
            %pseg = pseg & roimask;

            %waitforbuttonpress



            %%%%%%%%%%%%%%%%%%%
            %%%% SAVE DATA %%%%
            %%%%%%%%%%%%%%%%%%%

            glotborders = bwboundaries(pseg);

            ctr = double.empty(0,2);
            vidFrame = s(curframe).cdata;

            for j = 1:length(glotborders)
                ctr = [ctr; glotborders{j}];
            end
            for j = 1:length(ctr)
                m = max(ctr(j,1), 1);
                m = min(m, vidHeight);
                n = max(ctr(j,2), 1);
                n = min(n, vidWidth);

                vidFrame(m,n,1) = 0;
                vidFrame(m,n,2) = 255;
                vidFrame(m,n,3) = 0;
            end
            
            ctr = fliplr(ctr);

            % ctr format: Col1 -> y, Col2 -> x. Apply fliplr
            outputContours(curframe) = {ctr};
            separatedContours(curframe) = {glotborders};
            glottisAreas(curframe) = sum(sum( pseg ));
            
            if config.saveVideo
                segvideo(curframe) = {vidFrame};
            end







            %%%%%%%%%%%%%
            %%%% END %%%%
            %%%%%%%%%%%%%

            fprintf('Frame %d has been segmented\n', curframe);

            % Check how many objects are in final segmented image
            N = length(glotborders);
            
            if N > 0
                % Mark frame as segmented
                frameflag(curframe) = true;
                cycleFrames(end+1) = curframe;
            end
        
        end
        
        
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%% CHOOSE NEXT FRAME %%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
        % No glottis detected (end of cycle was reached)
        if N == 0
            if direction == -1
                % Return to beginning and change direction
                direction = 1;
                prevframe = cell2mat(recGlottis(i,1));
                border = round(cell2mat(recGlottis(i,2)));
                shape = cell2mat(recGlottis(i,3));
                
                % Check if we're at the end of the video
                if prevframe == length(s)
                    direction = 0;
                    fprintf('No glottis detected. Reached end of video. Choosing next frame...\n\n');
                else
                    fprintf('No glottis detected. Reached end of left side. Changing direction. Next frame is %d\n\n', prevframe+1);
                    curframe = prevframe + direction;
                end
            else
                % End while loop. Choose next non-visited frame with
                % highest dissimilarity
                direction  = 0;
                fprintf('No glottis detected. Reached end of right side. Choosing next frame...\n\n');
            end
        % Glottis detected, keep advancing
        else
            % Check if we're at the edges of the video
            if prevframe == 2 && direction == -1
                % Return to beginning and change direction
                direction = 1;
                prevframe = cell2mat(recGlottis(i,1));
                border = round(cell2mat(recGlottis(i,2)));
                shape = cell2mat(recGlottis(i,3));
                 
                fprintf('Glottis detected! Reached beginning of video. Changing direction.\n');
                
                % Check if we're at the end of the video
                if prevframe == length(s)
                    direction = 0;
                    fprintf('Reached end of video. Choosing next frame...\n\n');
                else
                    fprintf('Next frame is %d\n\n', prevframe+1);
                    curframe = prevframe + direction;
                end
                
            elseif prevframe == length(s)-1 && direction == 1
                % End while loop. Choose next non-visited frame with
                % highest dissimilarity
                direction  = 0;
                fprintf('Glottis detected! Reached end of video. Choosing next frame...\n\n');
            else
                % Update previous frame and mark as segmented
                prevframe = prevframe + direction;
                fprintf('Glottis detected! Advancing... Next frame is %d\n\n', prevframe+direction);
                curframe = prevframe + direction;
            end
        end
        
        
        
        
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%
        % Plot various data...
        %%%%%%%%%%%%%%%%%%%%%%%%%%

%         figure(5)
%         subplot(2,2,4); imshow(pseg); title('Remove non-GRA')
% 
% 
%         figure(9)
%         subplot 121
%         hold off
%         histogram(prevproj,20)
%         legend('Previous frame')
%         hold on
%         for j = 1:num
%             histogram(cell2mat(newproj(j,1)),20)
%         end
% 
%         subplot 122
%         hold off
%         for j = 1:num
%             histogram(cell2mat(newproj(j,2)),20)
%             hold on
%         end
%         legend('show')
% 
%         figure(1)
%         hold on
%         contour(pseg, [0.5 0.5], 'g', 'LineWidth', 1.3);
%         
%         waitforbuttonpress
        
    end
end

fprintf('Finished!\n\n');



%% POST-PROCESSING (?)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Correct and reorder outputContours %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

outputContours = separatedContours;
borderArray = cell( length(outputContours), 1 );
for i = 1:length(outputContours)
    
    if ~isempty(outputContours{i})
        correctedBorders = {};
        
        if iscell( outputContours{i} )
            
            for j = 1:length( outputContours{i} )
                objectBorder = outputContours{i}{j};

                for k = 1:length(objectBorder)
                    objectBorder(k,1) = max(objectBorder(k,1), 1);
                    objectBorder(k,1) = min(objectBorder(k,1), vidHeight);
                    objectBorder(k,2) = max(objectBorder(k,2), 1);
                    objectBorder(k,2) = min(objectBorder(k,2), vidWidth);
                end

                correctedBorders(end+1) = { fliplr(objectBorder) };
            end
            
        else
            objectBorder = outputContours{i};

            for k = 1:length(objectBorder)
                objectBorder(k,1) = max(objectBorder(k,1), 1);
                objectBorder(k,1) = min(objectBorder(k,1), vidHeight);
                objectBorder(k,2) = max(objectBorder(k,2), 1);
                objectBorder(k,2) = min(objectBorder(k,2), vidWidth);
            end

            correctedBorders(end+1) = { fliplr(objectBorder) };
        end
        
        borderArray(i) = { correctedBorders };
    end
end

outputContours = borderArray;



%%%%%%%%%%%%%%%%%%%%%
% Save metadata (?) %
%%%%%%%%%%%%%%%%%%%%%
vidMetaData = [];
vidMetaData.Height = vidHeight;
vidMetaData.Width = vidWidth;
vidMetaData.RealFrameRate = config.realFrameRate;
vidMetaData.Name = config.vidName;
vidMetaData.Path = config.vidPath;
vidMetaData.Tag = config.saveName;
vidMetaData.Roi = roiToSave;

% Find frame with maximum glottal opening
[~,maxIdx] = max(glottisAreas);
vidMetaData.ReferenceFrame = s(maxIdx).cdata;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get main glottal axis from frame with maximum glottal opening %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

glottisBinImage = false( vidMetaData.Height, vidMetaData.Width );

% Fill border
for j = 1:length( outputContours{maxIdx} )
    currentBorder = outputContours{maxIdx}{j};

    for k = 1:length(currentBorder)
        glottisBinImage( currentBorder(k,2), currentBorder(k,1) ) = true;
    end
end
glottisBinImage = imfill(glottisBinImage, 'holes');

% Coordinates of all pixels inside the glottis
[pixelRows,pixelColumns] = find(glottisBinImage == true);

% Get main and normal axis with pca
gcoef = pca([pixelRows pixelColumns]);
gaxis = gcoef(:,1);

% (x,y)
maxBorder = [];
for j = 1:length( outputContours{maxIdx} )
    maxBorder = [ maxBorder; outputContours{maxIdx}{j} ];
end

center = mean(maxBorder);
slope = gaxis(1) / gaxis(2);

lineErrors = maxBorder - round(center);
lineErrors = lineErrors(:,2) - slope * lineErrors(:,1);

% We try to find the border points that intersect the main glottal axis.
% These points will have lineError close to zero. To find them, we find the
% indexes where LineErrors changes sign

% We start checking the index with maximum error. This point will never be
% on the line so it's safe to start here
[maxVal, currentIdx] = max(lineErrors);
currentSign = sign( maxVal );

linePoints = [];
for i = 1:length(lineErrors)
    
    nextIdx = inc( currentIdx, length(lineErrors) );
    
    % Map 0 to 1, so that we can only have 1 or -1
    nextSign = sign( lineErrors(nextIdx) );
    if nextSign == 0
        nextSign = 1;
    end
    
    % Sign change! we found a line point
    if nextSign ~= currentSign
        % We have two options: the current point and the next. We add the
        % one closest to zero
        
        if abs( lineErrors(currentIdx) ) < abs( lineErrors(nextIdx) )
            linePoints(end+1,:) = maxBorder(currentIdx, :);
        else
            linePoints(end+1,:) = maxBorder(nextIdx, :);
        end
    end
    
    currentIdx = nextIdx;
    currentSign = nextSign;
end

% Find line points with highest and lowest y-axis value. Remember y-axis is
% inverted in the image
[~, highPointIdx] = min(linePoints(:,2));
[~, lowPointIdx] = max(linePoints(:,2));

axisPoints.high = linePoints(highPointIdx,:);
axisPoints.low = linePoints(lowPointIdx,:);

vidMetaData.AxisPoints = axisPoints;


%% SAVE DATA

if config.saveVideo
    myVideo = VideoWriter(strcat('Output_videos\variance_roi_crop_seg_', vidObj.Name), 'Uncompressed AVI');
    myVideo.FrameRate = 30;
    open(myVideo);
    for i = 1:length(segvideo)
        if length(segvideo{i}) == 0
            writeVideo(myVideo, s(i).cdata);
        else
            writeVideo(myVideo, segvideo{i});
        end
    end
    close(myVideo);
end

save(strcat('Output_contours/', config.saveName, '.mat'), 'outputContours', 'glottisAreas', 'vidMetaData');

% save log
currDateTime = datestr(datetime);
currDateTime(regexp(currDateTime,'[:]')) = [];
save( [ 'Output_contours/log_' config.saveName '_' currDateTime '.mat' ], 'outputContours', 'glottisAreas', 'vidMetaData' );


end

    
    
    