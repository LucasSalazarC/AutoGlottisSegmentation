% Vars:
%   pseg
%   gaxis
%   normaxis

figure(1), imshow(pseg)

% Normal axis line
normSlope = normaxis(1) / normaxis(2);
offset = 135;
x0 = 0;
y0 = offset;
x1 = 200;
y1 = x1 * normSlope + offset;
hold on, plot([x0 x1], [y0 y1], 'g'), hold off


% Main axis lines
mainSlope = gaxis(1) / gaxis(2);

offset = -523;
x0 = 0;
y0 = offset;
x1 = 1000;
y1 = x1 * mainSlope + offset;
hold on, plot([x0 x1], [y0 y1], 'c'), hold off

offset = -653;
x0 = 0;
y0 = offset;
x1 = 1000;
y1 = x1 * mainSlope + offset;
hold on, plot([x0 x1], [y0 y1], 'c'), hold off