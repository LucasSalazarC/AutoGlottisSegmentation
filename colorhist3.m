function [histos, glotprobs, bgcell, glotcell, testing] = colorhist3(I, shape, border, roimask, vecmap, npoints, kHalfSize)
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

histos = cell(npoints,3);
bpoints = linspace(1, length(border), npoints+1);
bpoints = round(bpoints(1:end-1));

% Calculo de Color medio ponderado por distancia
sigma  = 20;
wsize = 2;

% Matriz (casi) gaussiana
[xf,yf] = meshgrid(-wsize*sigma:wsize*sigma, -wsize*sigma:wsize*sigma);
gmatrix = exp(-1*(xf.^2 + yf.^2) / (2*sigma^2) );

% 3d histogram variables
L = vecmap(end,2) + 1;

[R,G,B] = meshgrid(1:L, 1:L, 1:L);
% rbw = 100;
% gbw = rbw/2.7;
% bbw = 1000;
% rbw = 5;
% gbw = rbw/1.5;
% bbw = 100;

glotprobs = zeros(length(bpoints), 1);

% Kernel calculation
ksize = 2*kHalfSize + 1;
bw = 10;
[N,M,Z] = meshgrid(-kHalfSize:kHalfSize, -kHalfSize:kHalfSize, -kHalfSize:kHalfSize);
kernel = exp(-1*( (N).^2/(2*bw^2) + (M).^2/(2*bw^2) + (Z).^2/(2*bw^2) ) );

for j = 1:length(bpoints)
    histobg = zeros(L,L,L);
    histoglot = zeros(L,L,L);
    bgcount = 0;
    glotcount = 0;
    
    bgdata = double.empty(0,4);
    glotdata = double.empty(0,4);
    
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
                        bgcount = bgcount + 1;

                        [exists, idx] = ismember([r g b], bgdata(:,1:3), 'rows');
                        if exists
                            bgdata(idx,4) = bgdata(idx,4) + weight;
                        else
                            bgdata(end+1,:) = [r g b weight];
                        end
                    else            % Inside glottis
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
        
        ni = max([r - kHalfSize, 1]);
        kni = max([1 - r + kHalfSize, 0]) + 1;
        mi = max([g - kHalfSize, 1]);
        kmi = max([1 - g + kHalfSize, 0]) + 1;
        zi = max([b - kHalfSize, 1]);
        kzi = max([1 - b + kHalfSize, 0]) + 1;

        nf = min([r + kHalfSize, L]);
        knf = ksize - max([r + kHalfSize - L, 0]);
        mf = min([g + kHalfSize, L]);
        kmf = ksize - max([g + kHalfSize - L, 0]);
        zf = min([b + kHalfSize, L]);
        kzf = ksize - max([b + kHalfSize - L, 0]);
        
        histobg(mi:mf, ni:nf, zi:zf) = histobg(mi:mf, ni:nf, zi:zf) + w * kernel(kmi:kmf, kni:knf, kzi:kzf);
    end
    for i = 1:length(glotdata)
        r = glotdata(i,1);
        g = glotdata(i,2);
        b = glotdata(i,3);
        w = glotdata(i,4);
        
        ni = max([r - kHalfSize, 1]);
        kni = max([1 - r + kHalfSize, 0]) + 1;
        mi = max([g - kHalfSize, 1]);
        kmi = max([1 - g + kHalfSize, 0]) + 1;
        zi = max([b - kHalfSize, 1]);
        kzi = max([1 - b + kHalfSize, 0]) + 1;

        nf = min([r + kHalfSize, L]);
        knf = ksize - max([r + kHalfSize - L, 0]);
        mf = min([g + kHalfSize, L]);
        kmf = ksize - max([g + kHalfSize - L, 0]);
        zf = min([b + kHalfSize, L]);
        kzf = ksize - max([b + kHalfSize - L, 0]);
        
         histoglot(mi:mf, ni:nf, zi:zf) = histoglot(mi:mf, ni:nf, zi:zf) + w * kernel(kmi:kmf, kni:knf, kzi:kzf);
    end
    
    glotprobs(j) = glotcount / (bgcount+glotcount);
    
    histos(j,:) = {p, histobg, histoglot};
    
%     bgcell(j) = {bgdata};
%     glotcell(j) = {glotdata};
%     testing(j) = {testdata};
end

end