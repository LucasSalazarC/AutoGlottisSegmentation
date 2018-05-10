load('test\pimage_testdata_new_FN003_1.mat');

prevframe1 = prevframe;
border1 = border;
shape1 = shape;
cg1 = cg;
rg1 = rg;
rpts1 = rpts;
roimask1 = roimask;

close
figure(1)
plot(border1(:,1), border1(:,2))
hold on

load('test\pimage_testdata_new_FN003_2.mat');

prevframe2 = prevframe;
border2 = border;
shape2 = shape;
cg2 = cg;
rg2 = rg;
rpts2 = rpts;
roimask2 = roimask;

plot(border2(:,1), border2(:,2), 'r')
axis image





















