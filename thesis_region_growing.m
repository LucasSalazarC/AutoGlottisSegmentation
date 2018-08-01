%% Open and read video data
vidObj = VideoReader('C:\Users\lucassalazar12\Videos\DSP\all_videos\FN003.avi');
s = struct('cdata',zeros(vidObj.Height,vidObj.Width,3,'uint8'),'colormap',[]);

k = 1;
vidObj.CurrentTime = 0;
while vidObj.CurrentTime <= 1
    s(k).cdata = readFrame(vidObj);         % Cuadros del video (imagenes)
    k = k+1;
end

frame = 20;

figure(1)
imshow(s(frame).cdata)
[x,y] = ginput(1)

x = round(x);
y = round(y);

hold on, plot(x,y,'g*'), hold off
f = getframe;
imwrite(f.cdata, 'C:\Users\lucassalazar12\Dropbox\USM\2018_1\Memoria\Latex\images\rgrowing_example_src.png')

seg = false(vidObj.Height, vidObj.Width);
seg(y,x) = true;

grayImg = rgb2gray(s(frame).cdata);

figure(2)
while true
    area = length(seg(seg == 1));
    
    border = bwboundaries(seg);
    border = border{1};
    
    for i = 1:size(border,1)
        m = border(i,1);
        n = border(i,2);
        
        for mm = -1:1
            for nn = -1:1
                if abs( grayImg(m + mm, n + nn) - grayImg(m,n) ) < 4
                    seg(m + mm, n + nn) = true;
                end
            end
        end
    end
    
    if area == length(seg(seg == 1))
        break;
    end
    
    imshow(seg)
end

f = getframe;
imwrite(f.cdata, 'C:\Users\lucassalazar12\Dropbox\USM\2018_1\Memoria\Latex\images\rgrowing_example.png')


fprintf('Finished!\n\n')


