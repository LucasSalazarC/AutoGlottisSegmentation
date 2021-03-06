function [histos, glotprobs, bgcell, glotcell, testing] = colorhist3(I, shape, border, roimask, vecmap, L, ~)
% [histos, step] = colorhist(I, shape, border, roimask, idxlow, idxhigh)
% 
%  I: Imagen a color
%  shape: Imagen binaria indicando zona de la glotis. 0 -> dentro de la
%   glotis, 1 -> Fuera de la glotis
%  border: Puntos del contorno de la glotis (matriz de 2 columnas)
%  roimask: Vector de puntos que estan dentro de la ROI
%  vecmap: Mapeo de colores desde [0,255] a otro intervalo
%  L: Numero de puntos de referencia en el borde de la glotis
%  filtsize: tama�o del filtro suavizador
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
sigma  = 50;
wsize = 2;

% Matriz (casi) gaussiana
[xf,yf] = meshgrid(-wsize*sigma:wsize*sigma, -wsize*sigma:wsize*sigma);
gmatrix = exp(-1*(xf.^2 + yf.^2) / (2*sigma^2) );

% 3d histogram variables
N = vecmap(end,2) + 1;

[R,G,B] = meshgrid(1:N, 1:N, 1:N);
% rbw = 100;
% gbw = rbw/2.7;
% bbw = 1000;
rbw = 5;
gbw = rbw/1.5;
bbw = 100;

glotprobs = zeros(length(bpoints), 1);

% % For scatter plot
% bgcell = cell(length(bpoints), 1);
% glotcell = cell(length(bpoints), 1);
% 
% testing = cell(length(bpoints), 1);

for j = 1:length(bpoints)
    j
    histobg = zeros(N,N,N);
    histoglot = zeros(N,N,N);
    bgcount = 0;
    glotcount = 0;
    
    bgdata = double.empty(0,4);
    glotdata = double.empty(0,4);
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
%                         histobg(r,g,b) = histobg(r,g,b) + weight;
                        bgcount = bgcount + 1;

                        [exists, idx] = ismember([r g b], bgdata(:,1:3), 'rows');
                        if exists
                            bgdata(idx,4) = bgdata(idx,4) + weight;
                        else
                            bgdata(end+1,:) = [r g b weight];
                        end
    %                     
    %                     testdata(end+1,:) = [color weight];
                    else            % Inside glottis
%                         histoglot(r,g,b) = histoglot(r,g,b) + weight;
                        glotcount = glotcount + 1;

                        [exists, idx] = ismember([r g b], glotdata(:,1:3), 'rows');
                        if exists
                            glotdata(idx,4) = glotdata(idx,4) + weight;
                        else
                            glotdata(end+1,:) = [r g b weight];
                        end
                    end
                end
            end
        end
    end
    
    for i = 1:length(bgdata)
        r = bgdata(i,1);
        g = bgdata(i,2);
        b = bgdata(i,3);
        w = bgdata(i,4);
        histobg = histobg + w * exp(-1*( (R-r).^2/(2*rbw^2) + (G-g).^2/(2*gbw^2) + (B-b).^2/(2*bbw^2) ) );
    end
    for i = 1:length(glotdata)
        r = glotdata(i,1);
        g = glotdata(i,2);
        b = glotdata(i,3);
        w = glotdata(i,4);
        histoglot = histoglot + w * exp(-1*( (R-r).^2/(2*rbw^2) + (G-g).^2/(2*gbw^2) + (B-b).^2/(2*bbw^2) ) );
    end
    
    glotprobs(j) = glotcount / (bgcount+glotcount);
    
%     histobg = imgaussfilt3(histobg, [filtsize filtsize filtsize]);
%     histoglot = imgaussfilt3(histoglot, [filtsize filtsize filtsize]);
    
%     histobg = histobg / max(max(max(histobg)));
%     histoglot = histoglot / max(max(max(histoglot)));
    
    histos(j,:) = {p, histobg, histoglot};
    
%     bgcell(j) = {bgdata};
%     glotcell(j) = {glotdata};
%     testing(j) = {testdata};
end

end