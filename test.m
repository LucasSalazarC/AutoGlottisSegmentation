imgList =  ["vocal_cords1.jpg", "vocal_cords1_crop.png"; ...
            "vocal_cords2.jpg", "vocal_cords2_crop.png"; ...
            "vocal_cords3.jpg", "vocal_cords3_crop.png"];

I = imread(char(imgList(3,1)));

% Leer y binarizar imagen
Iseg = imread(char(imgList(3,2)));
Iseg = rgb2gray(Iseg);
thr = graythresh(Iseg);
Ibin = im2bw(Iseg, thr);

A = rgb2gray(I);
[r,c] = size(A);
A = double(A);
for i = 1:r*c
    if Ibin(i) == 0
        A(i) = 255;
    end
end

figure(1)
image(A)
colormap(gray(256))
axis ij
axis image

%% GND base point area

% For image 3:
sigma  = 20;
%p = B(bpoints(8),:);
p = [300,300];
pini = p - 3*sigma;
pfin = p + 3*sigma;

pini(pini < 1) = 1;
if pfin(1) > c
    pfin(1) = c;
end
if pfin(2) > r
    pfin(2) = r;
end

for i = pini(1):pfin(1)
    for j = pini(2):pfin(2)
        A(j,i) = 0;
    end
end

figure(1)
image(A)
colormap(gray(256))
axis ij
axis image

%% Gaussian

sigma = 20;
x = -3*sigma:3*sigma;
y = (1/sigma/sqrt(pini)) * exp(-1*x.^2 / sigma^2 );
plot(x,y)
sum(y)


%% Test plot
asd = fliplr(allBorders{7});
asd = flipud(asd);
figure(3)
for i = 1:length(asd)
    plot(asd(i,1), asd(i,2), '*')
    axis ij
    axis equal
    hold on
    waitforbuttonpress
end


%% Test plot
figure(4)
for i = 1:length(B)
    plot(B(i,1), B(i,2), '*')
    axis ij
    axis equal
    hold on
    waitforbuttonpress
end

%% asdasd

[FD,idxlow,idxhigh] = fourierDescriptors(fliplr(allBorders{7}),30);
figure(5)
hold off
plot(1:30, real(FD))
hold on
plot(1:30, real(FDmatrix(2,:)))
title('real')

figure(6)
hold off
plot(1:30, imag(FD))
hold on
plot(1:30, imag(FDmatrix(2,:)'))



%% Cells

h = {};
h(1,:) = {'holi', 23};
h(end+1,:) = {'asd', 12}

%% Search
rpts = [r(roi) c(roi)];

roimask = ~binShape;
for j = 1:length(rpts)
    roimask(rpts(j,1), rpts(j,2)) = true;
end

figure(5)
image(roimask)
colormap(gray(2))




%%

[histos, step] = colorhist(s(prevframe).cdata, shape, border, roimask, idxlow, idxhigh);


%% Gaussian 2d

xbw = 20;
ybw = 10;
ws = 5;
vec = -ws*sigma:ws*sigma;
[x,y] = meshgrid(vec, vec);
f = exp(-1*( x.^2/xbw^2 + y.^2/ybw^2  ) );
mesh(x,y,f)

%% Semi-positive definite

asdmat = [3.5 0; 0 0];

~all(eig(asdmat) > eps)


%%

figure(30)
image(pseg)
colormap(gray(2))
axis image

