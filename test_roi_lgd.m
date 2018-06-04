load('test\lgd_testdata.mat');

tic

% format [y,x]
roiMinCoord = min(initialRoiBorder);
roiMaxCoord = max(initialRoiBorder);

origImage = rgb2gray(s(i).cdata);
lgdImage = origImage(roiMinCoord(1):roiMaxCoord(1),roiMinCoord(2):roiMaxCoord(2));

% format [x,y]
bestB(:,1) = bestB(:,1) - roiMinCoord(2) + 1;
bestB(:,2) = bestB(:,2) - roiMinCoord(1) + 1;

c = contourLGD(bestB, lgdImage, 350);       % Variable c es el contorno

c(:,1) = c(:,1) + roiMinCoord(2) - 1;
c(:,2) = c(:,2) + roiMinCoord(1) - 1;

figure(6), hold off
image(origImage), colormap(gray(255)), hold on
plot(c(:,1), c(:,2), 'g*', 'MarkerSize', 0.5)

toc