
load('training_data\trained_data.mat');

% Inputs:
%   frames -> Numero de cuadros a segmentar
%   FDmatrix -> Cada fila es un descriptor de fourier.
%   gndhisto -> Histograma 2D de GND
%   xaxis -> Eje x del histograma (primera componente)
%   yaxis -> Eje y del histograma (segunda componente)
%   coef -> Coeficientes PCA para reducir dimensionalidad de GND


%% Open and read video data
vidName = 'FN001';
if contains(vidName,'pre') || contains(vidName,'lombard') || contains(vidName,'adapt')
    vidPath = 'C:\Users\lucassalazar12\Videos\DSP\Lombard_video_8k fps\';
else
    vidPath = 'C:\Users\lucassalazar12\Videos\DSP\Fondecyt videos 10k fps\';
end
vidObj = VideoReader(strcat(vidPath, vidName, '.avi'));
vidHeight = vidObj.Height;
vidWidth = vidObj.Width;
s = struct('cdata',zeros(vidHeight,vidWidth,3,'uint8'),'colormap',[]);

vidSize = [vidHeight vidWidth];

frames = 44;

k = 1;
startTime = 0;
vidObj.CurrentTime = startTime;
endTime = startTime + + frames/vidObj.FrameRate;
while vidObj.CurrentTime <= endTime
    s(k).cdata = readFrame(vidObj);         % Cuadros del video (imagenes)
    k = k+1;
end

% waitforbuttonpress

%% Processing: Recognition part

[nImages,~] = size(FDmatrix);       % Number of training images

fdthresh = 6;        % Fourier Descriptor Dissimilarity threshold
gndthresh = 0.4;        % GND threshold
roithresh = 0.6;

% Find maximum x-value for probability > gndthresh
for i = size(gndhisto,2):-1:1
    colmax = max(gndhisto(:,i));
    
    if colmax >= 0.99
        break
    end
end

gnd_max_x = xaxis(i);

% Celda para guardar contornos reconocidos de glotis
recGlottis = {};

waitsm = 0;
waitlg = 0;
waitseg = 0;


for i = 1:length(s)
    fprintf('\n-----------------------------------------------\n----------------------------------------------\n');
    fprintf('Analizando cuadro %d\n', i);
    
    % Para guardar indice del potencial borde de glotis
    thrindex = 0;
    bestDsim = inf;
    
    grayFrame = rgb2gray(s(i).cdata);
    
    
    % Get ROI based on pixel variance over 100 frames. Recalculate every 100 frames
    if i == 1 || ( mod(i,100) == 1 && length(s) - i > 99 )
        [initialRoiMask, initialRoiBorder, roiObj] = variance_roi(s, 1);
        notInRoi = imcomplement(initialRoiMask);

        figure(9), imshow(imoverlay(grayFrame, roiObj, [0 1 0])), hold on
        plot(initialRoiBorder(:,2), initialRoiBorder(:,1), 'y*', 'MarkerSize', 1), hold off
    end
    
    
    
    
    % Remove black areas on the edges of the video
    blackMask = im2bw(grayFrame, 15/255);
    blackMask = imcomplement(blackMask);

    se = strel('disk', 1);
    blackMask = imdilate(blackMask, se);

    allBorders = bwboundaries(blackMask);
    for k = 1:length(allBorders)
        B = allBorders{k};              % Clockwise order
        B = fliplr(B);                  % x -> columna 1, y -> columna 2

        % Filter shapes not touching the edge of the image
        if check_out_of_bounds(B, vidSize, 'image')
            continue
        end

        objectMask = false(vidSize);
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
    
    % Umbral aumenta de 1 hasta 80. Se buscan figuras con forma de glotis
    for j = 1:80
        threshframe = im2bw(grayFrame, j/255);
        threshframe = imcomplement(threshframe);

        % Apertura
        se = strel('disk',1);
        openedframe = imopen(threshframe,se);
        
        % Bordes
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

            
            objectMask = false(vidSize);
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
         
            % Calcular descriptores de fourier
            [FD,~,~] = fourierDescriptors(B,30);
            
            % Comparar con los FD de entrenamiento (norma de la diferencia
            % al cuadrado)
            normMean = 0;
            for p = 1:nImages
                normMean = normMean + norm(FD.' - FDmatrix(p,:))^2;
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
        
        % Evaluar potenciales bordes, si es que hay
%         if bindex ~= 0
%             fprintf('Potencial borde de glotis encontrado!\n');
%             break
%         end
    end
    
    if thrindex(1) == 0 || bestDsim > fdthresh
        fprintf('No se encontraron potenciales bordes de glotis en este cuadro\n\n');
    else      
        fprintf('Potencial borde de glotis encontrado!\n');
        fprintf('Threshold = %d, Dissimilarity = %f\n', thrindex, bestDsim);
        
        figure(1)
        hold off
        image(grayFrame), colormap(gray(255))
        axis image
        
        hold on
        plot(bestB(:,1), bestB(:,2), 'y*', 'MarkerSize', 0.5)
        pause(waitlg);
        
%         % Testing purposes
%         save('test\lgd_testdata2.mat');
        
%         % format [y,x]
%         roiMinCoord = min(initialRoiBorder);
%         roiMaxCoord = max(initialRoiBorder);
% 
%         origImage = rgb2gray(s(i).cdata);
%         
%         % Crop image to ROI
%         lgdImage = origImage(roiMinCoord(1):roiMaxCoord(1),roiMinCoord(2):roiMaxCoord(2));
% 
%         % Change coordinates to cropped image
%         bestB(:,1) = bestB(:,1) - roiMinCoord(2) + 1;
%         bestB(:,2) = bestB(:,2) - roiMinCoord(1) + 1;
%         
%         % Apply contour adjusting algorithm
%         fprintf('Ajustando contorno...\n');
%         c = contourLGD(bestB, lgdImage, 350);       % Variable c es el contorno
%         
%         % Return to original coordinates
%         c(:,1) = c(:,1) + roiMinCoord(2) - 1;
%         c(:,2) = c(:,2) + roiMinCoord(1) - 1;
%         
%         % Fitler out of bounds
%         if check_out_of_bounds(c, size(lgdImage), 'image')
%             fprintf('Not in ROI; Out of bounds. False Region\n');
%             continue
%         end
        
        % Apply contour adjusting algorithm
        fprintf('Ajustando contorno...\n');
        c = contourLGD(bestB, grayFrame, 350);       % Variable c es el contorno
        
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
        
        objectMask = false(vidSize);
        cRound = round(c);
        for n = 1:length(cRound)
            objectMask( cRound(n,2), cRound(n,1) ) = true;
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
        
        
        % Calcular y evaluar de nuevo Descriptores de Fourier
        [FD,idxlow,idxhigh] = fourierDescriptors(c,30);
        normMean = 0;
        for p = 1:nImages
            normMean = normMean + norm(FD.' - FDmatrix(p,:))^2;
        end
        normMean = normMean / nImages;

        fprintf('Dissimilarity: %f\n', normMean);
        pause(waitlg);
        if normMean < fdthresh
            fprintf('Cuadro %d: Forma de glotis confirmada! Evaluando GND...\n\n', i);
            pause(waitsm);
            
            % Generar imagen binaria con el contorno
            binShape = false(size(threshframe));
            for j = 1:length(c)
                binShape(round(c(j,2)), round(c(j,1))) = true;
            end
            binShape = imfill(binShape, 'holes');
            binShape = imcomplement(binShape);
            
            % Calcular y descomponer GND con coeficientes PCA del
            % entrenamiento. Luego mapear a histograma
            GND = getGND(grayFrame, binShape, round(c), idxlow, idxhigh);
            decomp = GND * coef
            
            % decomp(1) is approximately the norm of average intensity difference between the inside
            % and outside of the contour. If it is high enough, we can just skip comparisons and
            % mark it as a glottis.
            if decomp(1) > gnd_max_x
                prob = 0.99;
                normMean = 0.01 + normMean/100;
            else
                [~,xindex] = min(abs(xaxis-decomp(1)));
                [~,yindex] = min(abs(yaxis-decomp(2)));
                prob = gndhisto(yindex,xindex);
            end
            
            g = sprintf('%f ', GND);
            fprintf('GND %d: %s\n', i, g);
            fprintf('Probabilidad de glotis = %f\n\n', prob);
            
            if prob > gndthresh
                fprintf('Glotis confirmada!\n\n');
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
    outputContours = cell(frames,1);
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
segvideo = cell(length(s),1);
outputContours = cell(frames,1);

% Sort by FD dissimilarity
recGlottis = sortrows(recGlottis, 4);

for i = 1:size(recGlottis,1)
    
    % Check if frame is already segmented
    if frameflag(cell2mat(recGlottis(i,1)))
        continue
    end
    
    % To keep track of segmented frames in each cycle
    cycleFrames = [];   
    
    % Datos de contorno con menor valor de disimilitud
    prevframe = cell2mat(recGlottis(i,1));
    border = round(cell2mat(recGlottis(i,2)));
    shape = cell2mat(recGlottis(i,3));    % Glotis son ceros, el resto es 1
    
    % Starting frame is already segmented
    frameflag(prevframe) = true;
    cycleFrames(end+1) = prevframe;
    
    % Save starting frame
    vidFrame = s(prevframe).cdata;
    for j = 1:length(border)
        m = border(j,2);
        n = border(j,1);

        vidFrame(m,n,1) = 0;
        vidFrame(m,n,2) = 255;
        vidFrame(m,n,3) = 0;
    end
    segvideo(prevframe) = {vidFrame};
    outputContours(prevframe) = {border};
    
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
                curMask( curBorder(j,2), curBorder(j,1) ) = true;
            end
            curMask = imfill(curMask, 'holes');
            
            intersection = curMask & ~shape;
            
            % If intersection is empty, the segmentations don't match. We assume the first
            % segmentation was correct and discard our progress in the current cycle.
            if sum(sum(intersection)) == 0
                for j = 1:length(cycleFrames)
                    outputContours(cycleFrames(j)) = {[]};
                    segvideo(cycleFrames(j)) = {s(cycleFrames(j)).cdata};
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

                % Que no se pasen de los bordes de la imagen
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

                % rpts: puntos dentro de la roi, pero fuera de la glotis
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

                % Calcular ROI: Distancia Mahalanobis 4.5
                roi = rangesearch([r c], pixMean, 4.5, 'Distance', 'mahalanobis', 'Cov', pixCov);
                roi = cell2mat(roi);
                rpts = [c(roi) r(roi)];     % Puntos dentro de la ROI, pero fuera de la glotis
            end

            roimask = ~shape;    % Sólo dentro de la glotis
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

            % Calcular histograma 3d para 8 puntos en el borde

            npoints = 15;
            filtsigma = 3;
            [histos, ~, ~,~,~] = colorhist2(rgb2gray(s(prevframe).cdata), shape, border, roimask, npoints, filtsigma);
            bpoints = cell2mat(histos(:,1));
            
%             figure(76)
%             plot(histos{1,2}), hold on
%             plot(histos{1,3})
%             waitforbuttonpress

            % Closest base points for each ROI point
            rpts = [rpts; [cg rg]];    % Ahora sí es la ROI entera, incluyendo glotis
            idxs = dsearchn(bpoints, rpts);

            % Calculate probability image
            I = rgb2gray(s(curframe).cdata);
            pimage = zeros(size(shape));
            for j = 1:length(rpts)
                pixInt = double( I(rpts(j,2),rpts(j,1)) ) + 1;
                idx = idxs(j);

                histobg = cell2mat(histos(idx,2));
                histoglot = cell2mat(histos(idx,3));

                bglike = histobg(pixInt);
                glotlike = histoglot(pixInt);

                if bglike < 0
                    bglike = 0;
                end

                pglot = 0.4;
                pbg = 1 - pglot;

                postprob = glotlike*pglot / (bglike*pbg + glotlike*pglot);
                if postprob < 0
                    pimage(rpts(j,2), rpts(j,1)) = 0;
                else
                    pimage(rpts(j,2), rpts(j,1)) = postprob * 255;
                end
            end

%             pimage = uint8(pimage);
%             figure(10)
%             image(pimage); title('Probability Image'); colormap(gray(255));
% 
%             waitforbuttonpress



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
                m = ctr(j,1);
                n = ctr(j,2);

                vidFrame(m,n,1) = 0;
                vidFrame(m,n,2) = 255;
                vidFrame(m,n,3) = 0;
            end
            
            ctr = fliplr(ctr);

            % ctr format: Col1 -> y, Col2 -> x. Apply fliplr
            outputContours(curframe) = {ctr};
            segvideo(curframe) = {vidFrame};







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




%% WRITE VIDEO


%myVideo = VideoWriter(strcat('home/lucas/Downloads/seg_', vidObj.Name), 'Uncompressed AVI');
myVideo = VideoWriter(strcat('Output_videos\roi_nocolor_seg_', vidObj.Name), 'Uncompressed AVI');
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

save(strcat('Output_contours\roi_nocolor_', vidName, '.mat'), 'outputContours');


    
    
    