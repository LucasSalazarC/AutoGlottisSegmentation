%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% PROBABILITY IMAGE %%
%%%%%%%%%%%%%%%%%%%%%%%%%

% Calcular histograma 3d para 8 puntos en el borde
tic
[histos, step, testing] = colorhist2(s(prevframe).cdata, shape, border, roimask, idxlow, idxhigh);
toc
bpoints = cell2mat(histos(:,1));

% Closest base points for each ROI point
rpts2 = [rpts; [cg rg]];
idxs = dsearchn(bpoints, rpts2);

% Vector map and interpolate histogram
ihist = cell(length(histos),2);
for j = 1:length(histos)
    ihist(j,:) = {interpn(cell2mat(histos(j,2)),1), interpn(cell2mat(histos(j,3)),1)};
end
L = length(cell2mat(ihist(1,1)));
vecmap = 1:256;
vecmap = floor(L*vecmap/256.01) + 1;

% Calculate probability image
I = s(curframe).cdata;
pimage = zeros(size(shape));
for j = 1:length(rpts2)
    color = double(reshape(I(rpts2(j,2),rpts2(j,1),:),1,3)) + 1;
    idx = idxs(j);

    histobg = cell2mat(ihist(idx,1));
    histoglot = cell2mat(ihist(idx,2));

    r = vecmap(color(1));
    g = vecmap(color(2));
    b = vecmap(color(3));
    bglike = histobg(r,g,b);
    glotlike = histoglot(r,g,b);
    
    pglot = 0.5;
    pbg = 0.5;

    postprob = glotlike*pglot / (bglike*pbg + glotlike*pglot);
    pimage(rpts2(j,2), rpts2(j,1)) = postprob * 255;
end

figure(10)
subplot(1,2,1), image(uint8(pimage)); title('Probability Image')
subplot(1,2,2), hold off, image(I), hold on, plot(bpoints(:,1), bpoints(:,2), 'y*', 'MarkerSize', 1)

%%


asd = zeros(length(rpts2), 4);
for i = 1:length(rpts2)
    asd(i,:) = [rpts2(i,:) bpoints(idxs(i),:)];
end
asd = sortrows(asd,2);


