
% blacklist is a string array with videos we don't want to use for training

% Loads borderData. 
% Col 1 -> Border in counterclockwise order. First column is x, second column is y.
% Col 2 -> Image
% Col 3 -> Video name
load('training_data\borders_and_images.mat');
        
N = 30;
FDmatrix = [];
GNDmatrix = [];

for i = 1:length(borderData(:,1))
    
    %% DESCRIPTORES DE FOURIER

    border = cell2mat(borderData(i,1));

    % Calcular y guardar Descriptores de Fourier. Los indices idxlow e
    % idxhigh se usaran en el GND
    [FD,idxlow,idxhigh] = fourierDescriptors(border,N);
    FDmatrix(end+1,:) = FD;
    Brec = ifft(FD);
    
    % hold on
    % plot(B(k,1), B(k,2), '*')
    % plot(B([i j],1), B([i j],2))
    % plot(Btr(:,1),Btr(:,2))
    
    
    %% GND: GLOTTAL NEIGHBORHOOD DESCRIPTOR
    
    % Full image
    I = cell2mat(borderData(i,2));
    
    % Create binary image
    sz = size(I);
    Ibin = false(sz(1:2));
    for j = 1:size(border,1)
        Ibin( border(j,2), border(j,1) ) = true;
    end
    Ibin = imfill(Ibin, 'holes');
    
%     GND = getGND(I, Ibin, border, idxlow, idxhigh);
    
    
    
    % N° de puntos a cada costado
    if idxhigh < idxlow
        nleft = idxlow - idxhigh - 1;
        nright = idxhigh - 1 + length(border) - idxlow;
    else
        nleft = idxlow - 1 + length(border) - idxhigh;
        nright = idxhigh - idxlow - 1;
    end

    bpoints = zeros(6,1);
    for j = 1:8
        if j < 5
            bpoints(j) = mod(idxhigh + (j-1)*nleft/4, length(border));
        else
            bpoints(j) = mod(idxlow + (j-5)*nright/4, length(border));
        end
        
        if bpoints(j) <= 0.5
            bpoints(j) = 1;
        end
    end
    bpoints = round(bpoints);
    
    figure(1), imshow(I), hold on
    plot(border(:,1), border(:,2), 'g', 'LineWidth', 1.5)
    plot( border(bpoints,1), border(bpoints,2), '*y', 'MarkerSize', 5)
    hold off
    
    fprintf('Imagen %d lista\n\n', i);
    
end