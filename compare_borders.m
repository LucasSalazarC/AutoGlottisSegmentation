function [dice, area_error] = compare_borders(b1, b2, imsize)
%COMPARE_BORDERS Summary of this function goes here
%   Detailed explanation goes here

im1 = false(imsize);
im2 = false(imsize);

for i = 1:length(b1)
    im1( b1(i,2), b1(i,1) ) = true;
end
for i = 1:length(b2)
    im2( b2(i,2), b2(i,1) ) = true;
end

im1 = imfill(im1, 'holes');
im2 = imfill(im2, 'holes');

if isequal( size(im1), size(im2) )
    intersection = im1 & im2;  
    
else    % Border is wrong; probably went off bounds
    dice = 0;
    area_error = 1;
    return
end

den = sum(sum(im1)) + sum(sum(im2));
if den == 0
    dice = 1;
    area_error = 0;
else
    dice = 2*sum(sum(intersection)) / den;
    area_error = abs( sum(sum(im1)) - sum(sum(im2)) ) / den;
end

end

