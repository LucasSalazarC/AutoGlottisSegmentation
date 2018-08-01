t = 0:0.1:40*pi;
x = sin(t);
x = max(x,0);

y = [];
step = 130;
k = 1;
for i = 1:step:length(t)
    y(k,:) = [ t(i) x(i) ];
    k = k+1;
end

figure(1)
subplot(2,1,1), plot(t,x), xlim([0 40*pi]), hold on
plot(y(:,1), y(:,2), 'r*'), hold off, axis off

subplot(2,1,2), plot(y(:,1), y(:,2), 'r'), axis off