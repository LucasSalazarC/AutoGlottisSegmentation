load('training_data\trained_data.mat');

% Find maximum x-value for probability > 0.4
for i = size(gndhisto,2):-1:1
    colmax = max(gndhisto(:,i));
    
    if colmax >= 0.4
        break
    end
end

xaxis(i)