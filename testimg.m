asdimg = uint8(pimage);
img2 = im2bw(asdimg, 220/255);

figure(7)
image(img2)
colormap(gray(2))