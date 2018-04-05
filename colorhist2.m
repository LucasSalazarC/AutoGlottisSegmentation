function [histos, glotprobs, bgcell, glotcell, testing] = colorhist2(I, shape, border, roimask, vecmap, L, filtsize)
% [histos, step] = colorhist(I, shape, border, roimask, idxlow, idxhigh)
% 
%  I: Imagen a color
%  shape: Imagen binaria indicando zona de la glotis. 0 -> dentro de la
%   glotis, 1 -> Fuera de la glotis
%  border: Puntos del contorno de la glotis (matriz de 2 columnas)
%  roimask: Vector de puntos que estan dentro de la ROI
%  vecmap: Mapeo de colores desde [0,255] a otro intervalo
%  L: Numero de puntos de referencia en el borde de la glotis
%  filtsize: tamaño del filtro suavizador
%
% Retorna:
%  histos: Arreglo de celdas. Cada fila contiene: Un punto, un histograma
%  3D de colores de pixeles dentro de la glotis y otro histograma para
%  pixeles fuera de la glotis.

bgcell = 0;
glotcell = 0;
testing = 0;

histos = cell(L,3);
bpoints = linspace(1, length(border), L+1);
bpoints = round(bpoints(1:end-1));

% Calculo de Color medio ponderado por distancia
sigma  = 30;
wsize = 2;

% Matriz (casi) gaussiana
[xf,yf] = meshgrid(-wsize*sigma:wsize*sigma, -wsize*sigma:wsize*sigma);
gmatrix = exp(-1*(xf.^2 + yf.^2) / (2*sigma^2) );

% 3d histogram variables
N = vecmap(end,2) + 1;
histobg = zeros(N,N,N);
histoglot = zeros(N,N,N);

glotprobs = zeros(length(bpoints), 1);

% % For scatter plot
% bgcell = cell(length(bpoints), 1);
% glotcell = cell(length(bpoints), 1);
% 
% testing = cell(length(bpoints), 1);

for j = 1:length(bpoints)
    bgcount = 0;
    glotcount = 0;
%     % For scatter plot
%     bgdata = double.empty(0,4);
%     glotdata = double.empty(0,4);
%     testdata = double.empty(0,4);
    
    % Evaluar color solo en puntos dentro de un area cuadrada en torno al
    % punto base
    p = border(bpoints(j),:);    % x -> columna 1, y -> columna 2
    pini = p - wsize*sigma;
    pfin = p + wsize*sigma;

    % Corregir indices fuera de rango
    inicorr = [0 0];
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
        pfin(1) = c;
    end
    if pfin(2) > x
        pfin(2) = x;
    end
    
    ycorr = 1 - pini(2) + inicorr(2);
    xcorr = 1 - pini(1) + inicorr(1);
    

    % Almacenar colores medios ponderados por distancia en bines, para
    % pixeles en la glotis y fuera de ella (background)
    for n = pini(1):pfin(1)
        for m = pini(2):pfin(2)
            if roimask(m,n)
                color = double(reshape(I(m,n,:),1,3)) + 1;
                r = vecmap(color(1), 2) + 1;
                g = vecmap(color(2), 2) + 1;
                b = vecmap(color(3), 2) + 1;
                weight = gmatrix(m + ycorr, n + xcorr);

                if shape(m,n)    % Outside glottis  
                    histobg(r,g,b) = histobg(r,g,b) + weight;
                    bgcount = bgcount + 1;
                    
%                     % For scatter plot
%                     [exists, idx] = ismember([r g b], bgdata(:,1:3), 'rows');
%                     if exists
%                         bgdata(idx,4) = bgdata(idx,4) + weight;
%                     else
%                         bgdata(end+1,:) = [color weight];
%                     end
%                     
%                     testdata(end+1,:) = [color weight];
                else            % Inside glottis
                    histoglot(r,g,b) = histoglot(r,g,b) + weight;
                    glotcount = glotcount + 1;
                    
%                     % For scatter plot
%                     [exists, idx] = ismember(color, glotdata(:,1:3), 'rows');
%                     if exists
%                         glotdata(idx,4) = glotdata(idx,4) + weight;
%                     else
%                         glotdata(end+1,:) = [color weight];
%                     end
                end
            end
        end
    end
    
    glotprobs(j) = glotcount / (bgcount+glotcount);
    
    histobg = imgaussfilt3(histobg, [filtsize filtsize filtsize]);
    histoglot = imgaussfilt3(histoglot, [filtsize filtsize filtsize]);%*glotprobs(j);
    
%     histobg = histobg / max(max(max(histobg)));
%     histoglot = histoglot / max(max(max(histoglot)));
    
    histos(j,:) = {p, histobg, histoglot};
    
%     bgcell(j) = {bgdata};
%     glotcell(j) = {glotdata};
%     testing(j) = {testdata};
end

end