load('training_data\trained_data.mat');
[nImages,~] = size(FDmatrix);       % Number of training images

vidName = 'FN004_naso';
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

frames = 10;

k = 1;
startTime = 0.0;
vidObj.CurrentTime = startTime;
endTime = startTime + frames/vidObj.FrameRate;
while vidObj.CurrentTime <= endTime
    s(k).cdata = readFrame(vidObj);         % Cuadros del video (imagenes)
    k = k+1;
end


i = 1;
lclick = 1;
rclick = 3;

bestDsim = inf;
bestErrorSim = inf;
bestB = [];
bestBeforeError = [];
firstError = [];
bestError = [];

fprintf('\n-----------------------------------------------\n----------------------------------------------\n');
fprintf('Analizando cuadro %d\n', i);


% Remove black areas on the edges of the video
blackMask = im2bw(s(i).cdata, 15/255);
blackMask = imcomplement(blackMask);

se = strel('disk', 1);
blackMask = imdilate(blackMask, se);

% Bordes
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

% Normalize image
normFrame = normalizeimg(s(i).cdata);

% For testing purposes
figure(20)
image(normFrame)
hold on

% Umbral aumenta de 1 hasta 80. Se buscan figuras con forma de glotis
for j = 1:80
    threshframe = im2bw(normFrame, j/255);
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

        % Filter shapes too small, too big, or touching the edge of the image
        if length(B) < 30 || length(B) > 500 || check_out_of_bounds(B, size(openedframe), 'image')
            continue
        end

        objectMask = false(vidSize);
        for n = 1:length(B)
            objectMask( B(n,2), B(n,1) ) = true;
        end
        objectMask = imfill(objectMask, 'holes');

        % Filter shapes touching the black area at the edge of the image
        if sum(sum( blackMask & objectMask )) > 0
            continue
        end


        % Calcular descriptores de fourier
        [FD,idxlow,idxhigh] = fourierDescriptors(B,30);

        % Comparar con los FD de entrenamiento (norma de la diferencia
        % al cuadrado)
        normMean = 0;
        for p = 1:nImages
            normMean = normMean + norm(FD.' - FDmatrix(p,:))^2;
        end
        normMean = normMean / nImages;

        % For testing purposes
        fprintf('T = %d; B %d; FDsim = %f; L = %d, Polycw = %d\n', j, k, normMean, length(B), ispolycw(B(:,1), B(:,2)) );
        plot(B(:,1), B(:,2), 'y*', 'Markersize', 0.5)

        while true
            [x,y,button] = ginput(1);
            if button == lclick
                if normMean < bestDsim
                    bestB = [j normMean];
                    bestDsim = normMean;
                    if isempty(firstError)
                        bestBeforeError = [j normMean];
                    end
                end
                break
            elseif button == rclick
                if normMean < bestErrorSim
                    bestError = [j normMean];
                    bestErrorSim = normMean;
                    if isempty(firstError)
                        firstError = [j normMean];
                    end
                end
                break
            end
        end
        unplot
    end

end

save(strcat('test\', vidName, '_fdsim.mat'), 'bestB', 'bestBeforeError', 'firstError', 'bestError');

if isempty(bestBeforeError)
    fprintf('Best = %f\n', bestB(2));
else
    fprintf('Best = %f, Before Error = %f\n', bestB(2), bestBeforeError(2));
end
fprintf('Error = %f, First Error = %f\n', bestError(2), firstError(2));



