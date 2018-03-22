function c = contourLGD(B, Img, numIter)
% c = contourLGD(B, Img)
%
%  Implementa un modelo de contorno activo. Ver: L. Wang, L. He, A. Mishra, 
%  and C. Li, �Active contours driven by local Gaussian distribution fitting 
%  energy�. El codigo fue escrito por los creadores del paper.
%
%  B es un vector que contiene las coordenadas del contorno inicial. Img es
%  una imagen grayscale.
%  Retorna el nuevo contorno c

binShape = false(size(Img));
for i = 1:length(B)
    binShape(B(i,2), B(i,1)) = true;
end
binShape = imfill(binShape, 'holes');
binShape = imcomplement(binShape);
binShape = double(binShape);

c0 = 4;
phi = 2*c0*binShape - c0;

Img = double(Img(:,:,1));

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

Ksigma=fspecial('gaussian',round(2*sigma)*2 + 1,sigma); %  kernel
ONE=ones(size(Img));
KONE = imfilter(ONE,Ksigma,'replicate');  
KI = imfilter(Img,Ksigma,'replicate');  
KI2 = imfilter(Img.^2,Ksigma,'replicate'); 

L = 20;
areahist = zeros(1,L);
meanareahist = zeros(1,L);
p = 1;

for iter = 1:numIter
    phi = evolution_LGD(Img,phi,epsilon,Ksigma,KONE,KI,KI2,mu,nu,lambda1,lambda2,timestep,alf); 
    phi = real(phi);
    
    signm = sign(phi);
    phiarea = length(phi(signm==-1));
    areahist(p) = phiarea;
    meanareahist(p) = mean(areahist);
    meanareastd = std(meanareahist);
    p = inc(p,L);
    
    %fprintf('It. %d; Area: %d; MeanStd: %f\n', iter, phiarea, meanareastd);
    % Convergence Criteria: meanareastd < 1
    
    if meanareastd < 0.4
        c = contourc(phi, [0 0]);
        c = transpose(c);
        
        outliers = isoutlier(c);
        outliers = outliers(:,1) | outliers(:,2);
        c = c(~outliers, :);
        
        fprintf('\nContour LGD completed in %d iterations!\n', iter);
        break
    end

end

if iter == numIter
    fprintf('\nRan out of iterations\n');
    c = contourc(phi, [0 0]);
    c = transpose(c);

    outliers = isoutlier(c);
    outliers = outliers(:,1) | outliers(:,2);
    c = c(~outliers, :);
end

end