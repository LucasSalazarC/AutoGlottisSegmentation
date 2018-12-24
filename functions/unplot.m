function unplot(n, mode)
c = get(gca,'children');
if nargin < 1
    n = 1;
    delete( c(1:min(n,length(c))) );
elseif nargin == 1
    delete( c(1:min(n,length(c))) );
else
    if mode == 'abs' && n <= length(c)
        delete( c(end-n+1) );
    end
end
end

