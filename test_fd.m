load('test\fd_testdata2.mat');

% plot(bestB(:,1), bestB(:,2), 'b*', 'MarkerSize', 0.5)
% plot(c(:,1), c(:,2), 'g*', 'MarkerSize', 0.5)

border = c;
border = flipud(border);
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