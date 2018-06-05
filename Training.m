
% Loads borderData. 
% Col 1 -> Border in counterclockwise order. First column is x, second column is y.
% Col 2 -> Image
% Col 3 -> Video name
load('training_data\borders_and_images.mat');
        
N = 30;
FDmatrix = zeros(size(borderData,1),N);
GNDmatrix = zeros(size(borderData,1),8);

figure(1)
hold off
for i = 1:length(borderData(:,1))
    
    %% DESCRIPTORES DE FOURIER

    border = cell2mat(borderData(i,1));

    % Calcular y guardar Descriptores de Fourier. Los indices idxlow e
    % idxhigh se usaran en el GND
    [FD,idxlow,idxhigh] = fourierDescriptors(border,N);
    FDmatrix(i,:) = FD;
    Brec = ifft(FD);

    
    plot(real(Brec),imag(Brec))
    hold on
    axis ij
    axis equal
    
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
    
    GND = getGND(I, Ibin, border, idxlow, idxhigh);
    g = sprintf('%f ', GND);
    fprintf('GND %d: %s\n', i, g);
    GNDmatrix(i,:) = GND;
    
    fprintf('Imagen %d lista\n\n', i);
    
end


%% PCA para reducir dimensionalidad de GND

% 'coef' son los valores por los que se multiplica para reducir
% dimensionalidad
[coef,scores,variances,~,percent_explained] = pca(GNDmatrix, 'NumComponents', 2);

%  Se utilizan solo las primeras dos componentes principales (>95% de
%  informacion en este caso).
coef = coef(:,1:2);
decomp = (GNDmatrix * coef);

% Histograma con gaussian kernel smoothing
extend = [150 150];
xi = round(min(decomp(:,1)) - extend(1));
xf = round(max(decomp(:,1)) + extend(1));
yi = round(min(decomp(:,2)) - extend(2));
yf = round(max(decomp(:,2)) + extend(2));
step = 2;
xaxis = xi:step:xf;
yaxis = yi:step:yf;

xbw = 80;
ybw = 180;

tic
[X,Y] = meshgrid(xaxis, yaxis);
gndhisto = zeros(size(X));
for i = 1:length(decomp)
    kernel = exp(-1*( (X-decomp(i,1)).^2/(2*xbw^2) + (Y-decomp(i,2)).^2/(2*ybw^2) ));
    gndhisto = gndhisto + kernel;
end

% Normalizar y graficar
gndhisto = gndhisto / max(max(gndhisto));
figure(2)
mesh(X,Y,gndhisto)
axis normal
xlabel('X: Componente 1')
ylabel('Y: Componente 2')
toc

% tic
% Attempt to use ksdensity function
% figure(4)
% points = combvec(xaxis,yaxis)';
% [f,xi] = ksdensity(decomp, points);
% [r,c] = size(X);
% gndhisto = vec2mat(f,c);
% gndhisto = gndhisto / max(max(gndhisto));
% mesh(X,Y,gndhisto)
% title('ksdensity')
% toc

% Se guardan los descriptores de Fourier. Respecto a los GND, se guarda el
% histograma generado (ejes + valores en z) y  los coeficientes pca para
% poder proyectar las muestras.

save('training_data\trained_data.mat', 'FDmatrix', 'xaxis', 'yaxis', 'gndhisto', 'coef');




