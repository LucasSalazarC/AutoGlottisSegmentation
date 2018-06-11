
L = 256;

kHalfSize = 10;
ksize = 2*kHalfSize + 1;
bw = 10;
[N,M,Z] = meshgrid(-kHalfSize:kHalfSize, -kHalfSize:kHalfSize, -kHalfSize:kHalfSize);
kernel = exp(-1*( (N).^2/(2*bw^2) + (M).^2/(2*bw^2) + (Z).^2/(2*bw^2) ) );

r = 5;
g = 30;
b = 80;

ni = max([r - kHalfSize, 1]);
kni = max([1 - r + kHalfSize, 0]) + 1;
mi = max([g - kHalfSize, 1]);
kmi = max([1 - g + kHalfSize, 0]) + 1;
zi = max([b - kHalfSize, 1]);
kzi = max([1 - b + kHalfSize, 0]) + 1;

nf = min([r + kHalfSize, L]);
knf = ksize - max([r + kHalfSize - L, 0]);
mf = min([g + kHalfSize, L]);
kmf = ksize - max([g + kHalfSize - L, 0]);
zf = min([b + kHalfSize, L]);
kzf = ksize - max([b + kHalfSize - L, 0]);

func = zeros(L,L,L);

tic
func(mi:mf, ni:nf, zi:zf) = func(mi:mf, ni:nf, zi:zf) + kernel(kmi:kmf, kni:knf, kzi:kzf);

% func(:,:, 80)

toc




















