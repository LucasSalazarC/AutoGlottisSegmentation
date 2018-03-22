
imgList =  ["fn1.jpg", "fn1_crop.png"; ...
            "fn2.jpg", "fn2_crop.png"; ...
            "fn4.jpg", "fn4_crop.jpg"; ...
            "fn5.jpg", "fn5_crop.png"; ...
            "fp2.jpg", "fp2_crop.png"; ...
            "fp3.jpg", "fp3_crop.png"; ...
            "fp5.jpg", "fp5_crop.png";];
        
N = 30;
FDmatrix = zeros(length(imgList),N);
GNDmatrix = zeros(length(imgList),8);

for i = 1:length(imgList)
    % Imagen completa
    I = imread(char(imgList(i,1)));
    
    % Leer y binarizar imagen segmentada
    Iseg = imread(char(imgList(i,2)));
    Iseg = rgb2gray(Iseg);
    thr = graythresh(Iseg);
    Ibin = im2bw(Iseg, thr);
    
    
    %% DESCRIPTORES DE FOURIER
    
    % Bordes
    B = bwboundaries(Ibin);
    B = B{2};                       % Clockwise order
    B = flipud(B);                  % Counterclockwise
    B = fliplr(B);                  % x -> columna 1, y -> columna 2

    % Calcular y guardar Descriptores de Fourier. Los indices idxlow e
    % idxhigh se usaran en el GND
    [FD,idxlow,idxhigh] = fourierDescriptors(B,N);
    FDmatrix(i,:) = FD;
    Brec = ifft(FD);

    figure(1)
    plot(real(Brec),imag(Brec))
    hold on
    axis ij
    axis equal
    
    % hold on
    % plot(B(k,1), B(k,2), '*')
    % plot(B([i j],1), B([i j],2))
    % plot(Btr(:,1),Btr(:,2))
    
    
    %% GND: GLOTTAL NEIGHBORHOOD DESCRIPTOR
    GND = getGND(I, Ibin, B, idxlow, idxhigh);
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
extend = [300 300];
xi = round(min(decomp(:,1)) - extend(1));
xf = round(max(decomp(:,1)) + extend(1));
yi = round(min(decomp(:,2)) - extend(2));
yf = round(max(decomp(:,2)) + extend(2));
step = 2;
xaxis = xi:step:xf;
yaxis = yi:step:yf;

xbw = 60;
ybw = 90;


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

% Se guardan los descriptores de Fourier. Respecto a los GND, se guarda el
% histograma generado (ejes + valores en z) y  los coeficientes pca para
% poder proyectar las muestras.

save('training_data.mat', 'FDmatrix', 'xaxis', 'yaxis', 'gndhisto', 'coef');




