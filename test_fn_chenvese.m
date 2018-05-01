%==========================================================================
%
%   Active contour with Chen-Vese Method 
%   for image segementation
%
%   Implemented by Yue Wu (yue.wu@tufts.edu)
%   Tufts University
%   Feb 2009
%   http://sites.google.com/site/rexstribeofimageprocessing/
% 
%   all rights reserved 
%   Last update 02/26/2009
%--------------------------------------------------------------------------
%   Usage of varibles:
%   input: 
%       I           = any gray/double/RGB input image
%       mask        = initial mask, either customerlized or built-in
%       num_iter    = total number of iterations
%       mu          = weight of length term
%       method      = submethods pick from ('chen','vector','multiphase')
%
%   Types of built-in mask functions
%       'small'     = create a small circular mask
%       'medium'    = create a medium circular mask
%       'large'     = create a large circular mask
%       'whole'     = create a mask with holes around
%       'whole+small' = create a two layer mask with one layer small
%                       circular mask and the other layer with holes around
%                       (only work for method 'multiphase')
%   Types of methods
%       'chen'      = general CV method
%       'vector'    = CV method for vector image
%       'multiphase'= CV method for multiphase (2 phases applied here)
%
%   output: 
%       phi0        = updated level set function 
%
%--------------------------------------------------------------------------
%
% Description: This code implements the paper: "Active Contours Without
% Edges" by Chan and Vese for method 'chen', the paper:"Active Contours Without
% Edges for vector image" by Chan and Vese for method 'vector', and the paper
% "A Multiphase Level Set Framework for Image Segmentation Using the 
% Mumford and Shah Model" by Chan and Vese. 
%
%--------------------------------------------------------------------------
% Deomo: Please see HELP file for details
%==========================================================================

% 2017-10-27: Adapted by Lucas Salazar
% UTFSM, Valparaiso, Chile
% Mostly removing functions I don't need

% dt = stepsize

function seg = test_fn_chenvese(I,mask,num_iter, rsz, mu, dt)
%% Default settings
% length term mu = 0.2
% 
% if(~exist('mu','var')) 
%     mu=0.2; 
% end

%% Initializations on input image I and mask
% Resize original image

s = 200./min(size(I,1),size(I,2)); % resize scale
if rsz && s<1
    I = imresize(I,s);
    mask = imresize(mask,s);
end

if size(mask,1)>size(I,1) || size(mask,2)>size(I,2)
  error('dimensions of mask unmathch those of the image.')
end

if size(I,3)== 3
    P = rgb2gray(uint8(I));
    P = double(P);
elseif size(I,3) == 2
    P = 0.5.*(double(I(:,:,1))+double(I(:,:,2)));
else
    P = double(I);
end
layer = 1;


%% Core function

% SDF
% Get the distance map of the initial mask

mask = mask(:,:,1);
phi0 = bwdist(mask)-bwdist(1-mask)+im2double(mask)-.5; 

% Initial force, set to eps to avoid division by zeros
force = eps; 

% Display settings
figure(7);
subplot(2,2,1); image(I); axis image; title('Input Image');
subplot(2,2,2); contour(flipud(phi0), [0 0], 'r','LineWidth',1); title('initial contour');
subplot(2,2,3); title('Segmentation');

% For convergence evaluation
N = 7;
areahist = zeros(1,N);
meanareahist = zeros(1,N);
p = 1;

%-- Main loop
for n=1:num_iter
    inidx = find(phi0>=0); % frontground index
    outidx = find(phi0<0); % background index
    force_image = 0; % initial image force for each layer 
    
    L = im2double(P(:,:,1)); % get one image component
    c1 = sum(sum(L.*Heaviside2(phi0)))/(length(inidx)+eps); % average inside of Phi0
    c2 = sum(sum(L.*(1-Heaviside2(phi0))))/(length(outidx)+eps); % verage outside of Phi0
    force_image=-(L-c1).^2+(L-c2).^2+force_image;
    % sum Image Force on all components (used for vector image)
    % if 'chan' is applied, this loop become one sigle code as a
    % result of layer = 1

    % calculate the external force of the image 
    force = mu*kappa(phi0)./max(max(abs(kappa(phi0))))+1/layer.*force_image;

    % normalized the force
    force = force./(max(max(abs(force))));

    % get parameters for checking whether to stop
    old = phi0;
    phi0 = phi0+dt.*force;
    new = phi0;

    % intermediate output
    if(mod(n,20) == 0) 
        showphi(I,phi0,n); 
    end
    
    % Convergence evaluation
    area = sign(phi0);
    area = length(phi0(area==-1));
    areahist(p) = area;
    meanareahist(p) = mean(areahist);
    meanareastd = std(meanareahist);
    p = inc(p,N);
    
    fprintf('It. %d; Area: %d; MeanStd: %f\n', n, area, meanareastd);
    
    if meanareastd < 0.3
        fprintf('\nCompleted in %d iterations!\n', n);
        showphi(I,phi0,n);

        %make mask from SDF
        seg = phi0<=0; %-- Get mask from levelset

        subplot(2,2,4); imshow(seg); title('Global Region-Based Segmentation');

        return
    end
end
showphi(I,phi0,n);

%make mask from SDF
seg = phi0<=0; %-- Get mask from levelset

subplot(2,2,4); imshow(seg); title('Global Region-Based Segmentation');

end

function H=Heaviside2(z)
% Heaviside step function (smoothed version)
% Copyright (c) 2009, 
% Yue Wu @ ECE Department, Tufts University
% All Rights Reserved  

    Epsilon=10^(-5);
    H=zeros(size(z,1),size(z,2));
    idx1=find(z>Epsilon);
    idx2=find(z<Epsilon & z>-Epsilon);
    H(idx1)=1;
    for i=1:length(idx2)
        H(idx2(i))=1/2*(1+z(idx2(i))/Epsilon+1/pi*sin(pi*z(idx2(i))/Epsilon));
    end
end


function KG = kappa(I)
% get curvature information of input image
% input: 2D image I
% output: curvature matrix KG

% Copyright (c) 2009, 
% Yue Wu @ ECE Department, Tufts University
% All Rights Reserved  

    I = double(I);
    [m,n] = size(I);
    P = padarray(I,[1,1],1,'pre');
    P = padarray(P,[1,1],1,'post');

    % central difference
    fy = P(3:end,2:n+1)-P(1:m,2:n+1);
    fx = P(2:m+1,3:end)-P(2:m+1,1:n);
    fyy = P(3:end,2:n+1)+P(1:m,2:n+1)-2*I;
    fxx = P(2:m+1,3:end)+P(2:m+1,1:n)-2*I;
    fxy = 0.25.*(P(3:end,3:end)-P(1:m,3:end)+P(3:end,1:n)-P(1:m,1:n));
    G = (fx.^2+fy.^2).^(0.5);
    K = (fxx.*fy.^2-2*fxy.*fx.*fy+fyy.*fx.^2)./((fx.^2+fy.^2+eps).^(1.5));
    KG = K.*G;
    KG(1,:) = eps;
    KG(end,:) = eps;
    KG(:,1) = eps;
    KG(:,end) = eps;
    KG = KG./max(max(abs(KG)));
end


function showphi(I, phi, i)
% show curve evolution of phi

% Copyright (c) 2009, 
% Yue Wu @ ECE Department, Tufts University
% All Rights Reserved  

    for j = 1:size(phi,3)
        phi_{j} = phi(:,:,j);
    end
    imshow(I,'initialmagnification','fit','displayrange',[0 255]);
    hold on;

    if size(phi,3) == 1
        contour(phi_{1}, [0 0], 'r','LineWidth',4);
        contour(phi_{1}, [0 0], 'g','LineWidth',1.3);
    else
        contour(phi_{1}, [0 0], 'r','LineWidth',4);
        contour(phi_{1}, [0 0], 'x','LineWidth',1.3);
        contour(phi_{2}, [0 0], 'g','LineWidth',4);
        contour(phi_{2}, [0 0], 'x','LineWidth',1.3);
    end
    hold off; 
    axis normal
    title([num2str(i) ' Iterations']); 
    drawnow;
    
end