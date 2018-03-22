clear all
load('testing1.mat')

tic

border = round(border);

% N° de puntos a cada costado
if idxhigh < idxlow
    nleft = idxlow - idxhigh - 1;
    nright = idxhigh - 1 + length(border) - idxlow;
else
    nleft = idxlow - 1 + length(border) - idxhigh;
    nright = idxhigh - idxlow - 1;
end

bpoints = zeros(8,1);
for j = 1:8
    if j < 5
        bpoints(j) = mod(idxhigh + (j-1)*nleft/4, length(border));
    else
        bpoints(j) = mod(idxlow + (j-5)*nright/4, length(border));
    end
end
bpoints = round(bpoints);

% Calculo de Color medio ponderado por distancia
sigma  = 10;
wsize = 3;

% Matriz (casi) gaussiana
[xgf,ygf] = meshgrid(-wsize*sigma:wsize*sigma, -wsize*sigma:wsize*sigma);
gmatrix = exp(-1*(xgf.^2 + ygf.^2) / sigma^2 );

% 3d histogram variables
step = 8;
[R,G,B] = meshgrid(0:step:255, 0:step:255, 0:step:255);
histobg = zeros(size(R));
histoglot = zeros(size(R));
bw = 10;

bins = 10;
cc = 255/bins/2 : 255/bins : 255;        % Centro de cada bin


% For scatter plot
bgdata = double.empty(0,4);
glotdata = double.empty(0,4);

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

    % Calcular color medio ponderado por distancia 
    intnum = zeros(3,1);
    intden = 0;
    extnum = zeros(3,1);
    extden = 0;
    for n = pini(1):pfin(1)
        for m = pini(2):pfin(2)
            if roimask(m,n)
                color = double(reshape(I(m,n,:),1,3)) + 1;
                weight = gmatrix(m + ycorr, n + xcorr);
                
                [~,ri] = min(abs(cc - color(1)));
                [~,gi] = min(abs(cc - color(2)));
                [~,bi] = min(abs(cc - color(3)));
                
                
                    

                if shape(m,n)    % Outside glottis  
                    bgcount(ri, gi, bi) = bgcount(ri, gi, bi) + weight;
                    
                    [exists, idx] = ismember(color, bgdata(:,1:3), 'rows');
                    if exists
                        bgdata(idx,4) = bgdata(idx,4) + weight;
                    else
                        bgdata(end+1,:) = [color weight];
                    end
                else            % Inside glottis
                    glotcount(ri, gi, bi) = glotcount(ri, gi, bi) + weight;
                    
                    [exists, idx] = ismember(color, glotdata(:,1:3), 'rows');
                    if exists
                        glotdata(idx,4) = glotdata(idx,4) + weight;
                    else
                        glotdata(end+1,:) = [color weight];
                    end
                end
            end
        end
    end
    
    [xf,yf,zf] = size(bgcount);
    for x = 1:xf
        fprintf('%d\n', x);
        for y = 1:yf
            for z = 1:zf
                if bgcount(x,y,z) ~= 0
                    histobg = histobg  +  bgcount(x,y,z) * exp(-1*( (R-cc(x)-1).^2 + (G-cc(y)-1).^2 + (B-cc(z)-1).^2 ) / (2*bw^2) );
                end
                
                if glotcount(x,y,z) ~= 0
                    histoglot = histoglot  +  glotcount(x,y,z) * exp(-1*( (R-cc(x)-1).^2 + (G-cc(y)-1).^2 + (B-cc(z)-1).^2 ) / (2*bw^2) );
                end
            end
        end
    end

    histobg = histobg / max(max(max(histobg)));
    histoglot = histoglot / max(max(max(histoglot)));
end

toc

%%

figure(6)
[X,Y] = meshgrid(0:step:255, 0:step:255);
mesh(X, Y, histoglot(:,:,round(100/step)))
xlabel('R')
ylabel('G')

%%

figure(7)
scatter3(bgdata(:,1), bgdata(:,2), bgdata(:,3), 10, bgdata(:,4), 'filled')
cb = colorbar;
xlabel('R')
ylabel('G')
zlabel('B')
colormap jet
xlim([0 255])
ylim([0 255])
zlim([0 255])
title('Background')

figure(8)
scatter3(glotdata(:,1), glotdata(:,2), glotdata(:,3), 10, glotdata(:,4), 'filled')
cb = colorbar;
xlabel('R')
ylabel('G')
zlabel('B')
colormap jet
xlim([0 255])
ylim([0 255])
zlim([0 255])
title('Glottis')




