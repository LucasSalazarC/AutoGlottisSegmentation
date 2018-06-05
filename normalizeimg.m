function [ normImg ] = normalizeimg( img )

% Convert to HSV
imghsv = rgb2hsv(img);
hsv_h = imghsv(:,:,1);
hsv_s = imghsv(:,:,2);
hsv_v = imghsv(:,:,3);

% Equalize V channel
[eqValue, ~] = histeq(hsv_v);

% Make sure range is 0 to 1
eqValue = eqValue - min(min(eqValue));
eqValue = eqValue ./ max(max(eqValue));

% Rebuild HSV
eqImgHsv = cat(3, hsv_h, hsv_s, eqValue);

% Back to RGB
normImg = uint8(hsv2rgb(eqImgHsv)*255);


end

