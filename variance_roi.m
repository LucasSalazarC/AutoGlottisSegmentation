function [ roiImg, roiBorder, roiObj ] = variance_roi( vidStruct )

% Returns a binary image where 1 is inside the ROI

L = 100;
if L > length(vidStruct)
    L = length(vidStruct);
end

for k = 1:L
    s(:,:,k) = rgb2gray(vidStruct(k).cdata);         % Cuadros del video (imagenes)
end

vidSize = size(s(:,:,1));
vidHeight = vidSize(1);
vidWidth = vidSize(2);


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


% Get average image intensity, not counting pixels on the black edges
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

avgImgIntensity = intSum / count;
varMinMaxImg = zeros(vidSize);
varMinImg = zeros(vidSize);

for m = 1:vidHeight
    for n = 1:vidWidth
        pixIntensities = s(m,n,:);
        pixIntensities = double( reshape(pixIntensities, [length(pixIntensities) 1]) );
        
        minCond = 1.3*min(pixIntensities) >= avgImgIntensity;
        maxCond = max(pixIntensities) >= 200;

        if minCond
            varMinImg(m,n) = 0;
        else
            varMinImg(m,n) = var(pixIntensities);
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

thrVMImg = im2bw(varMinImg, 30/255);
thrVMMImg = im2bw(varMinMaxImg, 30/255);

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
        roiObj = objMask;
        idx = j;
        rg = r;
        cg = c;
    end
end

% Find same object in VMImg
[labels, num] = bwlabel(thrVMImg);
for j = 1:num
    objMask = (labels == j);

    if sum(sum( objMask & roiObj )) > 0 && sum(sum(objMask)) > sum(sum(roiObj))
        [r,c] = find(labels == j);
        roiObj = objMask;
        idx = j;
        rg = r;
        cg = c;
        break;
    end
end


% Calcular ROI: Distancia Mahalanobis
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


end

