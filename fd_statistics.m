files = dir('test');

close
figure(1), hold on

fprintf('Best\t  Best Error\tBefore Error  First Error\n');
for i = 1:length(files)
    if files(i).isdir
        continue
    end
    
    load(strcat('test\', files(i).name));
    
    if isempty(bestBeforeError)
        bbe = -0.01;
    else
        bbe = bestBeforeError(2);
    end
    
    fprintf('%f  %f\t\t%f\t  %f  \t%s\n', bestB(2), bestError(2), bbe, firstError(2), files(i).name);
    
    plot(i, bestB(2), 'b*')
    plot(i, bestError(2), 'r*')
    plot(i, bbe, 'g*')
    plot(i, firstError(2), 'm*')
    
    ylim([0 1])
end