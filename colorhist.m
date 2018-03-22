function [histos, step] = colorhist(I, shape, border, roimask, idxlow, idxhigh)
% [histos, step] = colorhist(I, shape, border, roimask, idxlow, idxhigh)
% 
%  I: Imagen a color
%  shape: Imagen binaria indicando zona de la glotis. 0 -> dentro de la
%   glotis, 1 -> Fuera de la glotis
%  border: Puntos del contorno de la glotis (matriz de 2 columnas)
%  roimask: Vector de puntos que estan dentro de la ROI
%  idxlow: Punto mas bajo de eje de la glotis
%  idxhigh: Punto mas alto del eje de la glotis
%
% Retorna:
%  histos: Arreglo de celdas. Cada fila contiene: Un punto, un histograma
%  3D de colores de pixeles dentro de la glotis y otro histograma para
%  pixeles fuera de la glotis.
%  step: Ancho de cada bin del histograma. Recordar que el histograma es de
%  colores RGB; parte en 0 y termina en 255.

%border = round(border);


% N° de puntos a cada costado
if idxhigh < idxlow
    nleft = idxlow - idxhigh - 1;
    nright = idxhigh - 1 + length(border) - idxlow;
else
    nleft = idxlow - 1 + length(border) - idxhigh;
    nright = idxhigh - idxlow - 1;
end

L = 8;
histos = cell(L,3);
bpoints = zeros(L,1);
for j = 1:L
    if j < L/2+1
        bpoints(j) = mod(idxhigh + (j-1)*nleft*2/L, length(border));
    else
        bpoints(j) = mod(idxlow + (j-L/2-1)*nright*2/L, length(border));
    end
end

bpoints = round(bpoints);
for j = 1:length(bpoints)
    if bpoints(j) == 0
        bpoints(j) = 1;
    end
end

% Calculo de Color medio ponderado por distancia
sigma  = 40;
wsize = 2;

% Matriz (casi) gaussiana
[xf,yf] = meshgrid(-wsize*sigma:wsize*sigma, -wsize*sigma:wsize*sigma);
gmatrix = exp(-1*(xf.^2 + yf.^2) / (10*sigma^2) );

% 3d histogram variables
step = 16;
[R,G,B] = meshgrid(0:step:255, 0:step:255, 0:step:255);
histobg = zeros(size(R));
histoglot = zeros(size(R));
rbw = 100;
gbw = rbw/2.7;
bbw = 1000;

bins = 30;
cc = 255/bins/2 : 255/bins : 255;        % Centro de cada bin

for j = 1:length(bpoints)
    bgcount = zeros(bins,bins,bins);
    glotcount = zeros(bins,bins,bins);
    
    % Evaluar color solo en puntos dentro de un area cuadrada en torno al
    % punto base
    p = border(bpoints(j),:);    % x -> columna 1, y -> columna 2
    pini = p - wsize*sigma;
    pfin = p + wsize*sigma;

    % Corregir indices fuera de rango
    inicorr = [0 0];
    %fincorr = [0 0];
    if pini(1) < 1
        inicorr(1) = 1 - pini(1);
        pini(1) = 1;
    end
    if pini(2) < 1
        inicorr(2) = 1 - pini(2);
        pini(2) = 1;
    end
    [x,c] = size(shape);
    if pfin(1) > c
        %fincorr(1) = pfin(1) - c;
        pfin(1) = c;
    end
    if pfin(2) > x
        %fincorr(2) = pfin(2) - r;
        pfin(2) = x;
    end
    
    ycorr = 1 - pini(2) + inicorr(2);
    xcorr = 1 - pini(1) + inicorr(1);

    % Almacenar colores medios ponderados por distancia en bines, para
    % pixeles en la glotis y fuera de ella (background)
    for n = pini(1):pfin(1)
        for m = pini(2):pfin(2)
            if roimask(m,n)
                color = double(reshape(I(m,n,:),1,3));
                weight = gmatrix(m + ycorr, n + xcorr);
                
                [~,ri] = min(abs(cc - color(1)));
                [~,gi] = min(abs(cc - color(2)));
                [~,bi] = min(abs(cc - color(3)));

                if shape(m,n)    % Outside glottis  
                    bgcount(ri, gi, bi) = bgcount(ri, gi, bi) + weight;
                else            % Inside glottis
                    glotcount(ri, gi, bi) = glotcount(ri, gi, bi) + weight;
                end
            end
        end
    end
    
    % Smoothing con kernel gaussiano
    [xf,yf,zf] = size(bgcount);
    for x = 1:xf
        for y = 1:yf
            for z = 1:zf
                if bgcount(x,y,z) ~= 0
                    histobg = histobg  +  bgcount(x,y,z) * exp(-1*( (R-cc(x)-1).^2/(2*rbw^2) + (G-cc(y)-1).^2/(2*gbw^2) + (B-cc(z)-1).^2/(2*bbw^2) ) );
                end       
                if glotcount(x,y,z) ~= 0
                    histoglot = histoglot  +  glotcount(x,y,z) * exp(-1*( (R-cc(x)-1).^2/(2*rbw^2) + (G-cc(y)-1).^2/(2*gbw^2) + (B-cc(z)-1).^2/(2*bbw^2) ) );
                end
            end
        end
    end

    histobg = histobg / max(max(max(histobg)));
    histoglot = histoglot / max(max(max(histoglot)));
    
    histos(j,:) = {p, histobg, histoglot};
end

end