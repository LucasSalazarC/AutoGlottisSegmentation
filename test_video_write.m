vframe = s(2).cdata;

glotborders = bwboundaries(pseg);
ctr = double.empty(0,2);

for j = 1:length(glotborders)
    ctr = [ctr; glotborders{j}];
end

for j = 1:length(ctr)
    m = ctr(j,1);
    n = ctr(j,2);
    
    vframe(m,n,1) = 0;
    vframe(m,n,2) = 255;
    vframe(m,n,3) = 0;
end



figure(15)
image(vframe)
axis image

figure(16)
plot(ctr(:,2), ctr(:,1))
axis equal
axis ij