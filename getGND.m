function GND = getGND(I, Ibin, B, idxlow, idxhigh)
% GND = newGND(I, Ibin, B, idxlow, idxhigh)
% 
%  I: Imagen a color
%  Ibin: Imagen binaria indicando zona de la glotis. 0 -> dentro de la
%   glotis, 1 -> Fuera de la glotis
%  B: Puntos del contorno de la glotis (matriz de 2 columnas)
%  idxlow: Punto mas bajo de eje de la glotis
%  idxhigh: Punto mas alto del eje de la glotis
%
% Retorna el GND: Glottal Neighborhood Descriptor

    % Elegir 8 puntos base equidistantes del borde

    % N° de puntos a cada costado
    if idxhigh < idxlow
        nleft = idxlow - idxhigh - 1;
        nright = idxhigh - 1 + length(B) - idxlow;
    else
        nleft = idxlow - 1 + length(B) - idxhigh;
        nright = idxhigh - idxlow - 1;
    end

    bpoints = zeros(6,1);
    for j = 1:8
        if j < 5
            bpoints(j) = mod(idxhigh + (j-1)*nleft/4, length(B));
        else
            bpoints(j) = mod(idxlow + (j-5)*nright/4, length(B));
        end
        
        if bpoints(j) <= 0.5
            bpoints(j) = 1;
        end
    end
    bpoints = round(bpoints);

    % Calculo de Color medio ponderado por distancia
    sigma  = 20;
    wsize = 2;
    GND = zeros(1,8);
    
    % Matriz (casi) gaussiana
    [x,y] = meshgrid(-wsize*sigma:wsize*sigma, -wsize*sigma:wsize*sigma);
    gmatrix = exp(-1*(x.^2 + y.^2) / sigma^2 );
    
    for j = 1:length(bpoints)
        % Evaluar color solo en puntos dentro de un area cuadrada en torno al
        % punto base
        p = B(bpoints(j),:);    % x -> columna 1, y -> columna 2
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
        [r,c] = size(Ibin);
        if pfin(1) > c
            %fincorr(1) = pfin(1) - c;
            pfin(1) = c;
        end
        if pfin(2) > r
            %fincorr(2) = pfin(2) - r;
            pfin(2) = r;
        end

        ycorr = 1 - pini(2) + inicorr(2);
        xcorr = 1 - pini(1) + inicorr(1);

        % Calcular color medio ponderado por distancia 
        intnum = zeros(3,1);
        intden = 0;
        extnum = zeros(3,1);
        extden = 0;
        for n = pini(1):pfin(1)
            for m = pini(2):pfin(2)
                color = double(reshape(I(m,n,:),3,1));
                weight = gmatrix(m + ycorr, n + xcorr);

                if Ibin(m,n)    % Outside glottis   
                    extnum = extnum + color*weight;
                    extden = extden + weight;
                else            % Inside glottis
                    intnum = intnum + color*weight;
                    intden = intden + weight;
                end
            end
        end

        extcolor = extnum / extden;
        intcolor = intnum / intden;

        GND(j) = norm(extcolor - intcolor);
    end

end