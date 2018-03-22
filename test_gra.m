figure(30), image(pseg), axis image, colormap(gray(2))

[labels, num] = bwlabel(pseg);
newproj = cell(num,3);
for j = 1:num
    [objr, objc] = find(labels == j);
    horproj = [objr objc] * normaxis;
    vertproj = [objr objc] * gaxis;

    prevwidth = pmax - pmin;
    objwidth = max(horproj) - min(horproj);
    objheight = max(vertproj) - min(vertproj);
    objctr = mean(horproj);

    outofrange = (objctr > pmax - prevwidth*0.15) | (objctr < pmin + prevwidth*0.15);
    toobig = (objwidth > objheight) && (objwidth > prevwidth);
    toosmall = (length(objr) < 5) || (length(objr) < length(rg)/20);

    val = outofrange || toosmall || toobig;
    if val
        obj = (labels == j);
        pseg = pseg & ~obj;
    end

    newproj(j,:) = {horproj, vertproj, ~val};
end