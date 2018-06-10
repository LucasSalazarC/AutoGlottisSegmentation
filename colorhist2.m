function [histos, glotprobs, bgcell, glotcell, testing] = colorhist2(I, shape, border, roimask, L, filtsigma)
% [histos, step] = colorhist(I, shape, border, roimask, idxlow, idxhigh)
% 
%  I: Grayscale image
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

N = 256;
histos = cell(L,3);
bpoints = linspace(1, length(border), L+1);
bpoints = round(bpoints(1:end-1));

% Calculo de Color medio ponderado por distancia
sigma  = 40;
wsize = 2;

% Matriz (casi) gaussiana
[xf,yf] = meshgrid(-wsize*sigma:wsize*sigma, -wsize*sigma:wsize*sigma);
gmatrix = exp(-1*(xf.^2 + yf.^2) / (2*sigma^2) );

glotprobs = zeros(length(bpoints), 1);


for j = 1:length(bpoints)
    histobg = zeros(N,1);
    histoglot = zeros(N,1);
    bgcount = 0;
    glotcount = 0;
    
    % Evaluar color solo en puntos dentro de un area cuadrada en torno al
    % punto base
    p = border(bpoints(j),:);    % x -> columna 1, y -> columna 2
    [rows,cols] = size(shape); 

    % Almacenar colores medios ponderados por distancia en bines, para
    % pixeles en la glotis y fuera de ella (background)
    for n = -wsize*sigma:wsize*sigma
        for m = -wsize*sigma:wsize*sigma
            n_im = n + p(1);
            m_im = m + p(2);
            if n_im > 0 && n_im <= cols && m_im > 0 && m_im <= rows
                if roimask(m_im,n_im)
                    pixInt = double(I(m_im,n_im)) + 1;
                    weight = gmatrix(m + wsize*sigma + 1, n + wsize*sigma + 1);

                    if shape(m_im,n_im)    % Outside glottis  
                        histobg(pixInt) = histobg(pixInt) + weight;
                        bgcount = bgcount + 1;
                    else            % Inside glottis
                        histoglot(pixInt) = histoglot(pixInt) + weight;
                        glotcount = glotcount + 1;
                    end
                end
            end
        end
    end
    
    glotprobs(j) = glotcount / (bgcount+glotcount);
    
    smoothBgHisto = zeros(N,1);
    smoothGlotHisto = zeros(N,1);
    bw = 5;
    X = transpose(1:N);
    for i = 1:N
        if histobg(i) == 0
            continue
        else
            kernel = exp( -1*( (X-i).^2/(2*bw^2) ) ) * histobg(i);
            smoothBgHisto = smoothBgHisto + kernel;
        end
    end
    for i = 1:N
        if histoglot(i) == 0
            continue
        else
            kernel = exp( -1*( (X-i).^2/(2*bw^2) ) ) * histoglot(i);
            smoothGlotHisto = smoothGlotHisto + kernel;
        end
    end
    
    histos(j,:) = {p, smoothBgHisto, smoothGlotHisto};

end

end