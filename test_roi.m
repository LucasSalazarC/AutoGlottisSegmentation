% rg y cg: puntos de la glotis

rini = min(rg) - 7;
rfin = max(rg) + 7;
cini = min(cg) - 4;
cfin = max(cg) + 4;

% Que no se pasen de los border de la imagen
if rini < 1
    rini = 1;
end
if cini < 1
    cini = 1;
end
[maxr,maxc] = size(shape);
if rfin > maxr
    rfin = maxr;
end
if cfin > maxc
    cfin = maxc;
end

% rpts: puntos dentro de la roi, pero fuera de la glotis
roilen = (rfin-rini+1) * (cfin-cini+1) - length(rg);
rpts = zeros(roilen,2);

tempglot = [cg rg];
j = 1;
for r = rini:rfin
    for c = cini:cfin
        if ~ismember([c r], tempglot, 'rows')
            rpts(j,:) = [c r];
            j = j+1;
        end
    end
end

plot(rpts(:,1), rpts(:,2), '*', 'MarkerSize', 1)
xlim([50 100])
ylim([100 200])
axis ij