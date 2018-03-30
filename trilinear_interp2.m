function c = trilinear_interp2(color, histo, vecmap)
x = color(1);
y = color(2);
z = color(3);

x0 = floor(x) + 1;
x1 = ceil(x) + 1;
if x1 > vecmap(end,2)+1
    x1 = vecmap(end,2)+1;
end
y0 = floor(y) + 1;
y1 = ceil(y) + 1;
if y1 > vecmap(end,2)+1
    y1 = vecmap(end,2)+1;
end
z0 = floor(z) + 1;
z1 = ceil(z) + 1;
if z1 > vecmap(end,2)+1
    z1 = vecmap(end,2)+1;
end

c000 = histo(x0,y0,z0);
c001 = histo(x0,y0,z1);
c010 = histo(x0,y1,z0);
c011 = histo(x0,y1,z1);
c100 = histo(x1,y0,z0);
c101 = histo(x1,y0,z1);
c110 = histo(x1,y1,z0);
c111 = histo(x1,y1,z1);

if x0 == x1
    xd = 0;
else
    xd = (x-x0)/(x1-x0);
end
if y0 == y1
    yd = 0;
else
    yd = (y-y0)/(y1-y0);
end
if z0 == z1
    zd = 0;
else
    zd = (z-z0)/(z1-z0);
end

c00 = c000*(1-xd) + c100*xd;
c01 = c001*(1-xd) + c101*xd;
c10 = c010*(1-xd) + c110*xd;
c11 = c011*(1-xd) + c111*xd;

c0 = c00*(1-yd) + c10*yd;
c1 = c01*(1-yd) + c11*yd;

c = c0*(1-zd) + c1*zd;
end