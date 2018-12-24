function [histos, glotprobs, bgcell, glotcell, testing] = colorhist2(I, shape, border, roimask, vecmap, L, filtsigma)
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
sigma  = 40;
wsize = 3;

% Matriz (casi) gaussiana
[xf,yf] = meshgrid(-wsize*sigma:wsize*sigma, -wsize*sigma:wsize*sigma);
gmatrix = exp(-1*(xf.^2 + yf.^2) / (2*sigma^2) );

% 3d histogram variables
N = vecmap(end,2) + 1;


glotprobs = zeros(length(bpoints), 1);

% % For scatter plot
% bgcell = cell(length(bpoints), 1);
% glotcell = cell(length(bpoints), 1);
% 
% testing = cell(length(bpoints), 1);

for j = 1:length(bpoints)
    histobg = zeros(N,N,N);
    histoglot = zeros(N,N,N);
    bgcount = 0;
    glotcount = 0;
%     % For scatter plot
%     bgdata = double.empty(0,4);
%     glotdata = double.empty(0,4);
%     testdata = double.empty(0,4);
    
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
                    color = double(reshape(I(m_im,n_im,:),1,3)) + 1;
                    r = vecmap(color(1), 2) + 1;
                    g = vecmap(color(2), 2) + 1;
                    b = vecmap(color(3), 2) + 1;
                    weight = gmatrix(m + wsize*sigma + 1, n + wsize*sigma + 1);

                    if shape(m_im,n_im)    % Outside glottis  
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
    end
    
    glotprobs(j) = glotcount / (bgcount+glotcount);
    
    filtsize = 2*ceil(2*filtsigma) + 1;
    histobg = imgaussfilt3(histobg, filtsigma, 'FilterSize', filtsize);
    histoglot = imgaussfilt3(histoglot, filtsigma, 'FilterSize', filtsize);
%     histobg = imboxfilt3(histobg, [filtsize filtsize filtsize]);
%     histoglot = imboxfilt3(histoglot, [filtsize filtsize filtsize]);
    
%     histobg = histobg / max(max(max(histobg)));
%     histoglot = histoglot / max(max(max(histoglot)));
    
    histos(j,:) = {p, histobg, histoglot};
    
%     bgcell(j) = {bgdata};
%     glotcell(j) = {glotdata};
%     testing(j) = {testdata};
end

end