asdimg = uint8(pimage);
asdimg = im2bw(asdimg, 120/255);
seg = test_fn_chenvese(pimage, asdimg, 150, false, 0.18*255^2, 6);
