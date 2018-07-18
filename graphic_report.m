%% See images

algorithms = {'roi_nocolor_red', 'roi_nocolor_green', 'roi_nocolor_blue', 'roi_nocolor_rgb2gray'};

vidName = 'FN003_lombard';
vidPath = 'C:\Users\lucassalazar12\Videos\DSP\all_videos\';
cfNumber = 3;

load( strcat('manual_segmentation\', vidName) );
frameNumber = correctBorders{cfNumber,2}


% Get frame from video
vidObj = VideoReader(strcat(vidPath, vidName, '.avi'));
s = struct('cdata',zeros(vidObj.Height,vidObj.Width,3,'uint8'),'colormap',[]);
k = 1;
vidObj.CurrentTime = 0;
endTime = frameNumber/vidObj.FrameRate;
while vidObj.CurrentTime <= endTime
    s(k).cdata = readFrame(vidObj);         % Cuadros del video (imagenes)
    k = k+1;
end

frame = s(frameNumber).cdata;
ctr = correctBorders{cfNumber,1};

spm = 2;
spn = 3;
figure(1)
subplot(spm,spn,1), imshow(frame), hold on, plot(ctr(:,1), ctr(:,2), 'go', 'MarkerSize', 1.2), hold off, title('Correct')

for i = 1:length(algorithms)
    matName = strcat('Output_contours\', algorithms{i}, '_', vidName, '.mat');
    if exist(matName, 'file') == 2
        load( matName );
        if isequal(algorithms{i}, 'gie_rgb2gray')
            ctr = gieToSave{cfNumber};
        else
            ctr = outputContours{frameNumber};
        end
        
        if contains(algorithms{i}, 'red')
            frameToShow = frame(:,:,1);
        elseif contains(algorithms{i}, 'green')
            frameToShow = frame(:,:,2);
        elseif contains(algorithms{i}, 'blue')
            frameToShow = frame(:,:,3);
        elseif contains(algorithms{i}, 'rgb2gray')
            frameToShow = rgb2gray(frame);
        end
        
        if ~isempty(ctr)
            subplot(spm,spn,i+1), imshow(frameToShow), hold on, plot(ctr(:,1), ctr(:,2), 'go', 'MarkerSize', 1.2), hold off, title(algorithms{i})
        else
            subplot(spm,spn,i+1), imshow(frameToShow), title(algorithms{i})
        end
    else
        subplot(spm,spn,i+1), imshow(frameToShow), title(algorithms{i})
    end
end



%% Save images

figure(2)
ctr = correctBorders{cfNumber,1};
imshow(frame), hold on, plot(ctr(:,1), ctr(:,2), 'go', 'MarkerSize', 1.2), hold off
f = getframe;
imwrite(f.cdata, strcat('C:\Users\lucassalazar12\Downloads\', vidName, '_e', num2str(cfNumber), '_correct.png' ) );

for i = 1:length(algorithms)
    matName = strcat('Output_contours\', algorithms{i}, '_', vidName, '.mat');
    if exist(matName, 'file') == 2
        load( matName );
        if isequal(algorithms{i}, 'gie_rgb2gray')
            ctr = gieToSave{cfNumber};
        else
            ctr = outputContours{frameNumber};
        end
        
        if contains(algorithms{i}, 'red')
            frameToShow = frame(:,:,1);
        elseif contains(algorithms{i}, 'green')
            frameToShow = frame(:,:,2);
        elseif contains(algorithms{i}, 'blue')
            frameToShow = frame(:,:,3);
        elseif contains(algorithms{i}, 'rgb2gray')
            frameToShow = rgb2gray(frame);
        end
        
        if ~isempty(ctr)
            imshow(frameToShow), hold on, plot(ctr(:,1), ctr(:,2), 'go', 'MarkerSize', 1.2), hold off
            f = getframe;
            imwrite(f.cdata, strcat('C:\Users\lucassalazar12\Downloads\', vidName, '_e', num2str(cfNumber), '_', algorithms{i}, '.png' ) );
%         end
        else
            imshow(frameToShow)
            f = getframe;
            imwrite(f.cdata, strcat('C:\Users\lucassalazar12\Downloads\', vidName, '_e', num2str(cfNumber), '_', algorithms{i}, '.png' ) );
        end
    end
end


