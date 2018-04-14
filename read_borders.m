% Always save the first 100 video frames, in order.

path = "C:\Users\lucassalazar12\Videos\DSP\";
vidName = "MN002";

imagefiles = dir(char(path + vidName + "\*.png")); 
nfiles = length(imagefiles);

glotborders = cell(nfiles,1);

for i = 1:nfiles
    I = imread(char(imagefiles(i).folder + "\" + imagefiles(i).name));

    I = rgb2gray(I);            
    thr = graythresh(I);
    Ibin = im2bw(I, thr);    % Threshold, get binary image

    B = bwboundaries(Ibin);
    B = B{2};   % Clockwise, column 1 -> y, column 2 -> x

    glotborders(i) = {B};

%     figure(1)
%     subplot(1,2,1); image(I);
%     subplot(1,2,2); image(I); hold on;
%     plot(B(:,2), B(:,1), 'g*', 'MarkerSize', 0.5)

end

save(char("manual_segmentation\" + vidName + ".mat"), 'glotborders');