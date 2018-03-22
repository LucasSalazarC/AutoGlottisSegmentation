function [idxlow, idxhigh] =  maxpointdistance(B)

    Buniq = unique(B(:,1));
    if length(Buniq) == 1
        [~,idxlow] = max(B(:,2));
        [~,idxhigh] = min(B(:,2));
        return
    end
    
    k = convhull(B(:,1), B(:,2), 'simplify',true);
    dist = pdist(B(k,:));
    dist = squareform(dist);
    [~,idx] = max(dist(:));
    [p1,p2] = ind2sub(size(dist),idx);
    p1 = k(p1);       % Indices de puntos mas distantes en B
    p2 = k(p2);
    
    
    if B(p1,2) > B(p2,2)
        idxlow = p1;
        idxhigh = p2;
    else
        idxlow = p2;
        idxhigh = p1;
    end

end