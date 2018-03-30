%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% PROBABILITY IMAGE %%
%%%%%%%%%%%%%%%%%%%%%%%%%

load('pimage_testdata.mat');

% shape: Binary image. Glottis are zeros, the rest are ones
% border: coordinates of the border; (x,y)
% roimask: Binary image. ROI are ones
% idxlow: Index of lowest border point in image. Since the axis is
%         inverted, it has the highest 'y' coordinate. idxhigh is the
%         opposite.

% Calcular histograma 3d para 8 puntos en el borde
tic

% Mapping to quantize colors
quantize = 2;
vecmap = 0:255;
vecmap = vecmap';
vecmap(:,2) = floor(vecmap(:,1)/quantize);

[histos, ~] = colorhist2(s(prevframe).cdata, shape, border, roimask, vecmap, 3, 7);
bpoints = cell2mat(histos(:,1));
toc
tic

% Closest base points for each ROI point
rpts = [rpts; [cg rg]];    % Ahora sí es la ROI entera, incluyendo glotis
idxs = dsearchn(bpoints, rpts);

% Calculate probability image
I = s(curframe).cdata;
pimage = zeros(size(shape));
%testpimage = zeros(size(shape));
for j = 1:length(rpts)
    color = double(reshape(I(rpts(j,2),rpts(j,1),:),1,3))/quantize;
    idx = idxs(j);

    histobg = cell2mat(histos(idx,2));
    histoglot = cell2mat(histos(idx,3));

    bglike = trilinear_interp2(color, histobg, vecmap);
    glotlike = trilinear_interp2(color, histoglot, vecmap);

    pglot = 0.5;
    pbg = 0.5;

    postprob = glotlike*pglot / (bglike*pbg + glotlike*pglot);
    pimage(rpts(j,2), rpts(j,1)) = postprob * 255;
end
toc

figure(10)
subplot(1,2,1), image(uint8(pimage)); title('Probability Image')
subplot(1,2,2), hold off, image(I), hold on, plot(bpoints(:,1), bpoints(:,2), 'y*', 'MarkerSize', 1)






