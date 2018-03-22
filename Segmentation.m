tic

%% Open and read video data
%vidObj = VideoReader('/home/lucas/Videos/DSP/MN002.avi');
vidObj = VideoReader('C:\Users\lucassalazar12\Videos\DSP\MN002.avi');
vidHeight = vidObj.Height;
vidWidth = vidObj.Width;
s = struct('cdata',zeros(vidHeight,vidWidth,3,'uint8'),'colormap',[]);

k = 1;
vidObj.CurrentTime = 0;
while vidObj.CurrentTime <= 3
    s(k).cdata = readFrame(vidObj);         % Cuadros del video (imagenes)
    k = k+1;
end

waitforbuttonpress

%% Processing: Recognition part

% Carga:
%   FDmatrix -> Cada fila es un descriptor de fourier.
%   gndhisto -> Histograma 2D de GND
%   xaxis -> Eje x del histograma (primera componente)
%   yaxis -> Eje y del histograma (segunda componente)
%   coef -> Coeficientes PCA para reducir dimensionalidad de GND
load('training_data.mat')
[nImages,~] = size(FDmatrix);       % Number of training images

fdthresh = 0.2;        % Fourier Descriptor Dissimilarity threshold
gndthresh = 0.4;        % GND threshold

% Celda para guardar contornos reconocidos de glotis
recGlottis = {};

waitsm = 0;
waitlg = 0;

for i = 1:length(s)
    fprintf('\n-----------------------------------------------\n----------------------------------------------\n');
    fprintf('Analizando cuadro %d\n', i);
    
    % Para guardar indice del potencial borde de glotis
    thrindex = 0;
    bestDsim = inf;
    
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

            % Agregado por mi :D Filtra mucho mejor de esta forma...
            if length(B) < 50 || length(B) > 500
                continue
            end
         
            % Calcular descriptores de fourier
            [FD,idxlow,idxhigh] = fourierDescriptors(B,30);
            
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
            
            %fprintf('Threshold = %d; Borde %d: %f\n', j, k, normMean);
            if normMean < bestDsim
                thrindex = j;
                bestDsim = normMean;
                bestB = B;
            end
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
        image(s(i).cdata)
        axis image
        
        hold on
        plot(bestB(:,1), bestB(:,2), 'y*', 'MarkerSize', 0.5)
        pause(waitlg);
        
        % Aplicar algoritmo de ajuste de contorno
        fprintf('Ajustando contorno...\n');
        c = contourLGD(bestB, rgb2gray(s(i).cdata), 300);       % Variable c es el contorno
        plot(c(:,1), c(:,2), 'g*', 'MarkerSize', 0.5)
        
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
                binShape(round(c(j,2)), round(c(j,1))) = true;
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
                recGlottis(end+1,:) = {i, c, idxlow, idxhigh, binShape, normMean, prob};
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


fprintf('------------------------------------------\n');
fprintf('------------------------------------------\n');
fprintf('Regognition part is done! Proceeding with segmentation...\n\n');
pause(0)

%% Segmentation part

% To indicate wether a frame has been segmented or not
frameflag = false(length(s), 1);

% To save video frames
segvideo = cell(length(s),1);

% Sort by FD dissimilarity
recGlottis = sortrows(recGlottis, 6);

for i = 1:size(recGlottis,1)
    
    % Check if frame is already segmented
    if frameflag(cell2mat(recGlottis(i,1)))
        continue
    end
    
    
    
    % Datos de contorno con menor valor de disimilitud
    prevframe = cell2mat(recGlottis(i,1));
    border = round(cell2mat(recGlottis(i,2)));
    idxlow = cell2mat(recGlottis(i,3));
    idxhigh = cell2mat(recGlottis(i,4));
    shape = cell2mat(recGlottis(i,5));    % Glotis son ceros, el resto es 1
    
    % Starting frame is already segmented
    frameflag(prevframe) = true;
    
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
            % Need to calculate prevframe parameters again. Many variables
            % are defined later...
            
            % Use biggest segmented border as glottis region
            % NEED TO FIX THIS LATER
            % What if there is more than one object?
            bmax = 0;
            for j = 1:N
                temp = glotborders{j};
                if length(temp) > bmax
                    border = temp;
                    bmax = length(temp);
                end
            end
            border = flipud(border);
            border = fliplr(border);
            
            [idxlow, idxhigh] = maxpointdistance(border);
            
            shape = imcomplement(pseg); 
        end
    
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%% ROI: REGION OF INTEREST %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%         figure(1)
%         hold off
%         image(s(curframe).cdata)
%         axis image
%         pause(waitsm)


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

%         figure(4)
%         hold off
%         image(s(prevframe).cdata)
%         hold on
%         plot(border(:,1), border(:,2), 'g*', 'MarkerSize', 0.5)
%         plot(c(roi), r(roi), 'y*', 'MarkerSize', 0.5)
%         %image(roimask)
%         %colormap(gray(2))

        



        %%%%%%%%%%%%%%%%%%%%%%%%%
        %%%% PROBABILITY IMAGE %%
        %%%%%%%%%%%%%%%%%%%%%%%%%

        % Calcular histograma 3d para 8 puntos en el borde
        [histos, step] = colorhist(s(prevframe).cdata, shape, border, roimask, idxlow, idxhigh);
        bpoints = cell2mat(histos(:,1));

        % Closest base points for each ROI point
        rpts = [rpts; [cg rg]];    % Ahora sí es la ROI entera, incluyendo glotis
        idxs = dsearchn(bpoints, rpts);

        % Vector map and interpolate histogram
        ihist = cell(8,2);
        for j = 1:8
            ihist(j,:) = {interpn(cell2mat(histos(j,2)),1), interpn(cell2mat(histos(j,3)),1)};
        end
        L = length(cell2mat(ihist(1,1)));
        vecmap = 1:256;
        vecmap = floor(L*vecmap/256.01) + 1;

        % Calculate probability image
        I = s(curframe).cdata;
        pimage = zeros(size(shape));
        testpimage = zeros(size(shape));
        for j = 1:length(rpts)
            color = double(reshape(I(rpts(j,2),rpts(j,1),:),1,3)) + 1;
            idx = idxs(j);

            histobg = cell2mat(ihist(idx,1));
            histoglot = cell2mat(ihist(idx,2));

            r = vecmap(color(1));
            g = vecmap(color(2));
            b = vecmap(color(3));
            bglike = histobg(r,g,b);
            glotlike = histoglot(r,g,b);

            pglot = 0.5;
            pbg = 0.5;

            postprob = glotlike*pglot / (bglike*pbg + glotlike*pglot);
            
            if (r < 3 && g < 3 && b < 3) || r == 1  % Black areas, outside of camera
                pimage(rpts(j,2), rpts(j,1)) = 0;
            else
                pimage(rpts(j,2), rpts(j,1)) = postprob * 255;
            end
            
            if glotlike > bglike && r > 1
                testpimage(rpts(j,2), rpts(j,1)) = 255;
            end
        end
        




    
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%% LEVEL-SET SEGMENTATION %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Binarize by thresholding, then apply opening
%         pbinimg = uint8(pimage);
%         pbinimg = im2bw(pbinimg, 160/255);
        
        pbinimg = im2bw(testpimage, 160/255);
        se = strel('disk',1);
        pbinimg = imopen(pbinimg,se);

        % Level-set segmentation
        pseg = lucas_chenvese(pimage, pbinimg, 150, false, 0.18*255^2, 6);

        
        % Plot
        figure(5)
        subplot(2,3,1); imshow(I); title('Frame')
        subplot(2,3,2); imshow(uint8(testpimage)); title('Test Prob Image')
        subplot(2,3,3); imshow(uint8(pimage)); title('Probability Image')
        subplot(2,3,4); imshow(pbinimg); title('Threshold')
        subplot(2,3,5); imshow(pseg); title('Level-set segmentation')
         
%         %imshow(pseg)
%         %pause(waitsm)

    

        
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

            outofrange = (objctr > pmax - prevwidth*0.15) | (objctr < pmin + prevwidth*0.15);
            toobig = (objwidth > objheight) && (objwidth > prevwidth);
            toosmall = (length(objr) < 5) || (length(objr) < length(rg)/10);
            
            val = outofrange || toosmall || toobig;
            if val
                obj = (labels == j);
                pseg = pseg & ~obj;
            end

            newproj(j,:) = {horproj, vertproj, ~val};
        end
        
        
        
        subplot(2,3,6); imshow(pseg); title('GRA correction')
        % Make sure everything is inside the ROI
        %pseg = pseg & roimask;
       
        %waitforbuttonpress
        
        
        
        %%%%%%%%%%%%%%%%%
        %%%% SAVE DATA %%
        %%%%%%%%%%%%%%%%%
        
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
        
        segvideo(curframe) = {vidFrame};
        
        
        
        
        
        
        
        %%%%%%%%%%%%%
        %%%% END %%%%
        %%%%%%%%%%%%%
        
        fprintf('Frame %d has been segmented\n', curframe);
        
        % Check how many objects are in final segmented image
        N = length(glotborders);
        
        % Mark frame as segmented
        frameflag(curframe) = true;
        
        % No glottis detected (end of cycle was reached)
        if N == 0
            if direction == -1
                % Return to beginning and change direction
                direction = 1;
                prevframe = cell2mat(recGlottis(i,1));
                border = round(cell2mat(recGlottis(i,2)));
                idxlow = cell2mat(recGlottis(i,3));
                idxhigh = cell2mat(recGlottis(i,4));
                shape = cell2mat(recGlottis(i,5));
                
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
                idxlow = cell2mat(recGlottis(i,3));
                idxhigh = cell2mat(recGlottis(i,4));
                shape = cell2mat(recGlottis(i,5));
                 
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
myVideo = VideoWriter(strcat('C:\Users\lucassalazar12\Downloads\seg_', vidObj.Name), 'Uncompressed AVI');
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

toc

    
    
    