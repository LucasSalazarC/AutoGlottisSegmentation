function [outputContours,vidSize] =  Segmentation(vidName, vidPath, frames, FDmatrix, gndhisto, xaxis, yaxis, coef)

% Inputs:
%   frames -> Numero de cuadros a segmentar
%   FDmatrix -> Cada fila es un descriptor de fourier.
%   gndhisto -> Histograma 2D de GND
%   xaxis -> Eje x del histograma (primera componente)
%   yaxis -> Eje y del histograma (segunda componente)
%   coef -> Coeficientes PCA para reducir dimensionalidad de GND


%% Open and read video data
% vidName = 'FN002_adapt';
% vidPath = 'C:\Users\lucassalazar12\Videos\DSP\Lombard_video_8k fps\';
vidObj = VideoReader(strcat(vidPath, vidName, '.avi'));
vidHeight = vidObj.Height;
vidWidth = vidObj.Width;
s = struct('cdata',zeros(vidHeight,vidWidth,3,'uint8'),'colormap',[]);

vidSize = [vidHeight vidWidth];

k = 1;
startTime = 0;
vidObj.CurrentTime = startTime;
endTime = startTime + frames/vidObj.FrameRate;
while vidObj.CurrentTime <= endTime
    s(k).cdata = readFrame(vidObj);         % Cuadros del video (imagenes)
    k = k+1;
end

% waitforbuttonpress

%% Processing: Recognition part

[nImages,~] = size(FDmatrix);       % Number of training images

fdthresh = 0.32;        % Fourier Descriptor Dissimilarity threshold
gndthresh = 0.7;        % GND threshold

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
    
%     % For testing purposes
%     figure(20)
%     image(s(i).cdata)
%     hold on
    
    % Umbral aumenta de 1 hasta 80. Se buscan figuras con forma de glotis
    for j = 1:80
        threshframe = im2bw(s(i).cdata, j/255);
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

            % Filter shapes too small
            if length(B) < 30 
                continue
            end

            % Calcular descriptores de fourier
            [FD,~,~] = fourierDescriptors(B,30);
            
%             Brec = ifft(FD);
%             plot(real(Brec),imag(Brec))
%             hold on
%             axis ij
%             axis equal
            
            % Comparar con los FD de entrenamiento (norma de la diferencia
            % al cuadrado)
            normMean = 0;
            for p = 1:nImages
                normMean = normMean + norm(FD.' - FDmatrix(p,:))^2;
            end
            normMean = normMean / nImages;
            
            if normMean < bestDsim && normMean < fdthresh
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
        if thrindex ~= 0
            fprintf('Potencial borde de glotis encontrado!\n');
            break
        end
    end
    
    if thrindex(1) == 0
        fprintf('No se encontraron potenciales bordes de glotis en este cuadro\n\n');
    else      
        fprintf('Potencial borde de glotis encontrado!\n');
        fprintf('Threshold = %d, Dissimilarity = %f\n', thrindex, bestDsim);
     
        figure(1)
        hold off
        imshow(s(i).cdata)
        axis image
        
        hold on
        plot(bestB(:,1), bestB(:,2), 'y*', 'MarkerSize', 0.5)
        pause(waitlg);
        
%         % Testing purposes
%         save('test\lgd_testdata2.mat');
        
        % Aplicar algoritmo de ajuste de contorno
        fprintf('Ajustando contorno...\n');
        c = contourLGD(bestB, rgb2gray(s(i).cdata), 350);       % Variable c es el contorno
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
                cm = max(round(c(j,2)), 1);
                cm = min(cm, vidHeight);
                cn = max(round(c(j,1)), 1);
                cn = min(cn, vidWidth);
                binShape(cm, cn) = true;
            end
            binShape = imfill(binShape, 'holes');
            binShape = imcomplement(binShape);
            
            % Calcular y descomponer GND con coeficientes PCA del
            % entrenamiento. Luego mapear a histograma
            GND = getGND(s(i).cdata, binShape, round(c), idxlow, idxhigh);
            decomp = GND * coef;
            
            [~,xindex] = min(abs(xaxis-decomp(1)));
            [~,yindex] = min(abs(yaxis-decomp(2)));
            prob = gndhisto(yindex,xindex);
            
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
        m = max(border(j,2), 1);
        m = min(m, vidHeight);
        n = max(border(j,1), 1);
        n = min(n, vidWidth);

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
        
        if prevframe ~= cell2mat(recGlottis(i,1))

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

        roimask = ~shape;    % S�lo dentro de la glotis
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
        rpts = [rpts; [cg rg]];    % Ahora s� es la ROI entera, incluyendo glotis
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
        pseg = lucas_chenvese(pimage, pbinimg, 150, false, 1*255^2, 6);
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
        for j = 1:num
            [objr, objc] = find(labels == j);
            horproj = [objr objc] * normaxis;

            outofrange = (min(horproj) > pmax) | (max(horproj) < pmin);

            if outofrange
                fprintf('GRA %d: Out of range\n', j);
                obj = (labels == j);
                pseg = pseg & ~obj;
            end
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
        % outputContour format: [x,y]
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
myVideo = VideoWriter(strcat('Output_videos\original_seg_', vidObj.Name), 'Uncompressed AVI');
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

save(strcat('Output_contours\original_', vidName, '.mat'), 'outputContours');


end

    
    
    