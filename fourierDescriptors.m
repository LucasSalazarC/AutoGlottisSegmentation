function [FD, idxlow, idxhigh] = fourierDescriptors(B, N)
% [FD, idxlow, idxhigh] = fourierDescriptors(B, N)
% 
% Calcula descriptores de Fourier del contorno B. B debe ser una matriz de
% dos columnas, donde cada fila representa una coordenada.
% 
% Retorna los primeros N descriptores, modificados para ser invariantes a
% traslacion, rotacion, escala y punto de inicio. 
% Ademas retorna los indices en B de los dos puntos con coordenadas
% verticales mas bajas y altas (ixdlow e idxhigh) que corresponden al eje
% de la glotis, luego de aplicar una rotacion al borde.

% Encontrar puntos mas distantes, para encontrar eje de la glotis y rotarla
% a posicion vertical (invarianza a rotacion)
k = convhull(B(:,1), B(:,2), 'simplify',true);
dist = pdist(B(k,:));
dist = squareform(dist);
[maxd,idx] = max(dist(:));
[p1,p2] = ind2sub(size(dist),idx);
p1 = k(p1);       % Indices de puntos mas distantes en B
p2 = k(p2);

% Aplicar rotacion respecto al centroide. El angulo es el del eje
% glotal respecto a la vertical
m = (B(p1,2)-B(p2,2)) / (B(p1,1)-B(p2,1));      % Pendiente para angulo de rotacion
theta = pi/2 - atan(m);
if m < 0
    theta = theta + pi;
end
R = [cos(theta) sin(theta); -sin(theta) cos(theta)];    % Matriz de rotacion

centroid = mean(B);
Btr = B - centroid;         % Centrar en el origen
Btr = Btr*R;


% Se elige la coordenada con menor valor en el eje vertical como punto
% inicial (invarianza a punto inicial); siempre sera uno de los puntos p1 o p2.
% Note que esto corresponde al mayor valor de la coordenada y, ya que el eje 
% esta invertido.
% Los indices ylow e yhigh se retornan en la salida ya que son necesarios
% para el calculo del GND
if Btr(p1,2) > Btr(p2,2)
    idxlow = p1;
    idxhigh = p2;
else
    idxlow = p2;
    idxhigh = p1;
end
Btr = circshift(Btr, 1-idxlow, 1);

% Calcular descriptores de fourier
imB = Btr(:,1) + 1i*Btr(:,2);           % Convertir a imaginario
if length(imB) < N
    FD = fft(imB,N);                      % Descriptor de Fourier
else
    FD = fft(imB);                      % Descriptor de Fourier
end

FD(1) = 0;                          % Invarianza a traslacion
FD = FD / abs(FD(2));               % Invarianza a escala

% Retornar los primeros N
if length(FD) > N
    FD = [FD(1:ceil(N/2)) ; FD(end-floor(N/2)+1:end)];
end

end