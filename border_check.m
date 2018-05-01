
load('training_data\MP003.mat');

border = cell2mat(correctBorders(1,1));
L = floor(length(border)/8);

close all
figure(1)
axis equal
axis ij
hold on

for i = 1:L
    idxs = ( (i-1)*L + 1) : ( i*L );
    plot(border(idxs,1), border(idxs,2), 'b*')
    waitforbuttonpress
end