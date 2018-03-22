%% Thresholding

%Img = imread('vocal_cords3.jpg');
Img = s(1).cdata;
Img = rgb2gray(Img);

threshframe = im2bw(Img, 30/255);
threshframe = imcomplement(threshframe);
%threshframe = pbinimg;

% Apertura
se = strel('disk',2);
openedframe = imopen(threshframe,se);

figure(1)
hold off
image(openedframe)
axis image
colormap(gray(2))
title('Apertura')
hold on

% Bordes
[allBorders,~] = bwboundaries(openedframe, 'noholes');
B = allBorders{5};              % Clockwise order
B = flipud(B);                  % Counterclockwise
B = fliplr(B);                  % x -> columna 1, y -> columna 2
plot(B(:,1), B(:,2), 'r*', 'MarkerSize', 1)

glottis = false(size(openedframe));
for i = 1:length(B)
    glottis(B(i,2), B(i,1)) = true;
end
glottis = imfill(glottis, 'holes');
% figure(3)
% image(glottis)
% colormap(gray(2))
% title('Glotis')

glottis = imcomplement(glottis);
glottis = double(glottis);

c0 = 4;
phi = 2*c0*glottis - c0;


%% LGD Algorithm

%Img=imread('vocal_cords2.jpg');
Img = double(Img(:,:,1));

NumIter = 1000; %iterations
timestep=1; %time step
mu=0.2/timestep;% level set regularization term, please refer to "Chunming Li and et al. Level Set Evolution Without Re-initialization: A New Variational Formulation, CVPR 2005"
sigma = 2.5;%size of kernel
epsilon = 0.7;
%c0 = 2; % the constant value 
lambda1=1;%outer weight, please refer to "Chunming Li and et al,  Minimization of Region-Scalable Fitting Energy for Image Segmentation, IEEE Trans. Image Processing, vol. 17 (10), pp. 1940-1949, 2008"
lambda2=1;%inner weight
%if lambda1>lambda2; tend to inflate
%if lambda1<lambda2; tend to deflate
nu = 0.001*255*255;%length term
alf = 30;%data term weight


%figure,imagesc(uint8(Img),[0 255]),colormap(gray),axis off;axis equal
[Height Wide] = size(Img);
[xx yy] = meshgrid(1:Wide,1:Height);
%phi = (sqrt(((xx - 65).^2 + (yy - 40).^2 )) - 20);
%phi = sign(phi).*c0;


Ksigma=fspecial('gaussian',round(2*sigma)*2 + 1,sigma); %  kernel
ONE=ones(size(Img));
KONE = imfilter(ONE,Ksigma,'replicate');  
KI = imfilter(Img,Ksigma,'replicate');  
KI2 = imfilter(Img.^2,Ksigma,'replicate'); 


figure(2),imagesc(uint8(Img),[0 255]),colormap(gray),axis off;axis equal,
hold on,[c,h] = contour(phi,[0 0],'r','linewidth',1); hold off
pause(0.5)

L = 20;
areahist = zeros(1,L);
meanareahist = zeros(1,L);
p = 1;

tic
for iter = 1:NumIter
    phi = evolution_LGD(Img,phi,epsilon,Ksigma,KONE,KI,KI2,mu,nu,lambda1,lambda2,timestep,alf); 
    phi = real(phi);
    
    signm = sign(phi);
    phiarea = length(phi(signm==-1));
    areahist(p) = phiarea;
    meanareahist(p) = mean(areahist);
    meanareastd = std(meanareahist);
    p = inc(p,L);
    
    fprintf('It. %d; Area: %d; MeanStd: %f\n', iter, phiarea, meanareastd);
    % Convergence Criteria: meanareastd < 1

    if(mod(iter,10) == 0)
        figure(2),
        imagesc(uint8(Img),[0 255]),colormap(gray),axis off;axis equal,title(num2str(iter))
        hold on,[c,h] = contour(phi,[0 0],'r','linewidth',1); hold off
        pause(0.02);
    end
    
    if meanareastd == 0
        c = contourc(phi, [0 0]);
        c = transpose(c);
        
        outliers = isoutlier(c);
        outliers = outliers(:,1) | outliers(:,2);
        c = c(~outliers, :);
        break
    end

end
toc