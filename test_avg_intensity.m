% files = dir('C:\Users\lucassalazar12\Videos\DSP\Lombard_video_8k fps\');
files = {'FN004_naso', 'FN002', 'FN005' ,'FP010_naso2', 'FN003_naso', 'FN005_naso', 'FP016_naso'};

for i = 1:length(files)
%     if ~files(i).isdir
%         vidName = files(i).name;
%         vidName = vidName(1:end-4);
    if true
        vidName = files{i};
        fprintf('Video: %s\n', vidName);
        
        if contains(vidName,'pre') || contains(vidName,'lombard') || contains(vidName,'adapt')
            vidPath = 'C:\Users\lucassalazar12\Videos\DSP\Lombard_video_8k fps\';
        else
            vidPath = 'C:\Users\lucassalazar12\Videos\DSP\Fondecyt videos 10k fps\';
        end
        vidObj = VideoReader(strcat(vidPath, vidName, '.avi'));
        vidHeight = vidObj.Height;
        vidWidth = vidObj.Width;

        frames = 100;
        s = zeros(vidHeight,vidWidth,frames+1,'uint8');
        vidSize = [vidHeight vidWidth];

        k = 1;
        startTime = 0;
        vidObj.CurrentTime = startTime;
        endTime = startTime + frames/vidObj.FrameRate;
        while vidObj.CurrentTime <= endTime
            s(:,:,k) = rgb2gray(readFrame(vidObj));         % Cuadros del video (imagenes)
            k = k+1;
        end

        
        
        
        
        
        % Remove black areas on the edges of the video
        blackMask = im2bw(s(:,:,1), 15/255);
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
        
        
        intSum = 0;
        count = 0;
        for m = 1:vidHeight
            for n = 1:vidWidth
                if blackMask(m,n)
                    continue
                else
                    intSum = intSum + double(s(m,n,1));
                    count = count + 1;
                end
            end
        end
        intSum = intSum / count;

%         avgImgIntensity = mean(mean(s(:,:,1)));
        avgImgIntensity = intSum;
        varMinMaxImg = zeros(vidSize);
        varMinImg = zeros(vidSize);
        
        avgMask = zeros(vidSize);
        minMask = zeros(vidSize);
        maxMask = zeros(vidSize);
        for m = 1:vidHeight
            for n = 1:vidWidth
                pixIntensities = s(m,n,:);
                pixIntensities = double( reshape(pixIntensities, [length(pixIntensities) 1]) );
                
                meanCond = 1.0*mean(pixIntensities) >= avgImgIntensity;
                minCond = 1.3*min(pixIntensities) >= avgImgIntensity;
                maxCond = max(pixIntensities) >= 200;

                if meanCond
                    avgMask(m,n) = 0;
                else
                    avgMask(m,n) = 255;
                end
                
                if minCond
                    minMask(m,n) = 0;
                    varMinImg(m,n) = 0;
                else
                    minMask(m,n) = 255;
                    varMinImg(m,n) = var(pixIntensities);
                end
                
                if maxCond
                    maxMask(m,n) = 0;
                else
                    maxMask(m,n) = 255;
                end
                
                if minCond || maxCond
                    varMinMaxImg(m,n) = 0;
                else
                    varMinMaxImg(m,n) = var(pixIntensities);
                end

            end
        end

        varMinImg = uint8(varMinImg*255 / max(max(varMinImg)));
        varMinMaxImg = uint8(varMinMaxImg*255 / max(max(varMinMaxImg)));
        meanVar = mean(mean(double(varMinMaxImg)));
        fprintf('Mean varImg = %f\n', meanVar);
        
        thrVMImg = im2bw(varMinImg, 30/255);
        
        thrVMMImg = im2bw(varMinMaxImg, 30/255);
        thrVMMImgOrig = thrVMMImg;
        
        thrVMImg = imerode(thrVMImg, strel('disk', 1));
        thrVMImg = imdilate(thrVMImg, strel('disk', 2));
        thrVMMImg = imerode(thrVMMImg, strel('disk', 1));
        thrVMMImg = imdilate(thrVMMImg, strel('disk', 2));
        
        % Find largest object in VMMImg
        [labels, num] = bwlabel(thrVMMImg);
        maxSize = 0;
        idx = 0;
        for j = 1:num
            objMask = (labels == j);
            objBorder = bwboundaries(objMask);
            objBorder = fliplr(objBorder{1});
            
            if sum(sum(objMask & blackMask)) > 0 || check_out_of_bounds(objBorder, vidSize, 'image')
                thrVMMImg = thrVMMImg & ~objMask;
                continue
            end
            
            [r,c] = find(labels == j);
            if length(r) > maxSize
                maxSize = length(r);
                largestObjMask = objMask;
                idx = j;
                rg = r;
                cg = c;
            end
        end
        
        % Find same object in VMImg
        [labels, num] = bwlabel(thrVMImg);
        for j = 1:num
            objMask = (labels == j);
            
            if sum(sum( objMask & largestObjMask )) > 0 && sum(sum(objMask)) > sum(sum(largestObjMask))
                [r,c] = find(labels == j);
                maxSize = length(r);
                largestObjMask = objMask;
                idx = j;
                rg = r;
                cg = c;
                break;
            end
        end


        % Calcular ROI: Distancia Mahalanobis 4.5
        pixMean = [mean(rg) mean(cg)];
        pixCov = cov(rg,cg);
        [r,c] = find(labels ~= idx);
        roi = rangesearch([r c], pixMean, 5.5, 'Distance', 'mahalanobis', 'Cov', pixCov);
        roi = cell2mat(roi);
        rpts = [c(roi) r(roi)];     % Puntos dentro de la ROI, pero fuera de la glotis

        roiImg = false(vidSize);
        for j = 1:length(rpts)
            roiImg( rpts(j,2), rpts(j,1) ) = true;
        end
        roiImg = imfill(roiImg, 'holes');
        roiBorder = bwboundaries(roiImg);
        roiBorder = roiBorder{1};
        
        % Smaller ROI
        roi = rangesearch([r c], pixMean, 2.5, 'Distance', 'mahalanobis', 'Cov', pixCov);
        roi = cell2mat(roi);
        rpts = [c(roi) r(roi)];     % Puntos dentro de la ROI, pero fuera de la glotis

        roiImgSmall = false(vidSize);
        for j = 1:length(rpts)
            roiImgSmall( rpts(j,2), rpts(j,1) ) = true;
        end
        roiImgSmall = imfill(roiImgSmall, 'holes');
        roiBorderSmall = bwboundaries(roiImgSmall);
        roiBorderSmall = roiBorderSmall{1};

%         figure(8), imshow(imoverlay(s(:,:,1), largestObjMask, [0 1 0])), hold on
        figure(8), imshow(s(:,:,1)), hold on
        plot(roiBorder(:,2), roiBorder(:,1), 'y*', 'MarkerSize', 0.5)
        plot(roiBorderSmall(:,2), roiBorderSmall(:,1), 'c*', 'MarkerSize', 0.5), hold off
        
        figure(2)
        subplot(1,2,1), image(varMinMaxImg), title('Variance & MinC & MaxC')
        subplot(1,2,2), image(varMinImg), title('Variance & MinC')
        
        figure(3), subplot(3,2,1), image(minMask), colormap(gray(255)), title('Min < ImgAvg')
        subplot(3,2,2), image(avgMask), title('AvgPix < ImgAvg')
        subplot(3,2,3), image(thrVMMImgOrig*255), title('Original threshold')
        subplot(3,2,4), image(255*thrVMMImg), title('Threshold')
        subplot(3,2,5), image(255*blackMask), title('black mask')
        subplot(3,2,6), image(255*maxMask), title('max mask')
        
        waitforbuttonpress
    end
end