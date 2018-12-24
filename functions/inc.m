function y = inc(x,N)
    y = mod(x+1,N+1);
    if y == 0
        y = 1;
    end
end