% I=readmraw('Photron_mraw_example',[1 10]);
% for n=1:1:10
% imshow(I.Images.RawImages(:,:,n),[0 3000]);
% pause(.1);
% end

path = 'C:\Users\lucassalazar12\Videos\DSP\raws\FN001_rigido\';
filename = 'FN001_rigido';

cih_file = fopen( sprintf('%s%s.cih', path, filename), 'r' );
raw_file = fopen( sprintf('%s%s%06d.raw', path, filename, 1), 'r' );

header = textscan(cih_file, '%s', 'delimiter', '\n');

% frames = str2double( cell2mat(header{1}(32)) );

% % If NaN, go back 1 index
% if isnan(frames)
%     frames = str2double( cell2mat(header{1}(31)) );
%     width = str2double( cell2mat(header{1}(39)) );
%     height = str2double( cell2mat(header{1}(41)) );
% end

height = 250;
width = 200;
pixels = height*width;
R_vector = uint8(zeros(pixels,1));
G_vector = uint8(zeros(pixels,1));
B_vector = uint8(zeros(pixels,1));

shift = 1;
whiteThreshold = 2^(12-shift) - 1;

fseek(raw_file, 0, 'bof');
for i = 1:pixels
    for j = 1:3
        data = fread(raw_file, 1, 'uint16');
        eliminatedOnes = sum(bitget(data, 17-shift:16));
        if eliminatedOnes ~= 0
            value = uint8(255);
        else
            data = bitshift(data, -4);
            value = double(data) * 255 / whiteThreshold;
            value = uint8( value );
        end
        
        if j == 1
            R_vector(i) = value;
        elseif j == 2
            G_vector(i) = value;
        else
            B_vector(i) = value;
        end
    end
end

R = reshape(R_vector, [width, height])';
G = reshape(G_vector, [width, height])';
B = reshape(B_vector, [width, height])';
img = cat(3, R, G, B);

unplot
figure(1), hold on
imshow(img)



% offset = 100*6;
% fseek(raw_file, offset, 'bof');
% for i = 1:3
%     data = fread(raw_file, 16, 'ubit1');
%     fprintf('%d', data);
%     fprintf(' ');
%     
%     % Back to beginning of pixel channel
%     fseek(raw_file, offset + (i-1)*2, 'bof');
%     
%     data = fread(raw_file, 1, 'uint16');
%     fprintf('%d', data);
%     fprintf(' ');
%     
%     fseek(raw_file, offset + (i-1)*2, 'bof');
%     
%     data = fread(raw_file, 1, 'uint16');
%     eliminatedOnes = sum(bitget(data, 17-shift:16));
%     if eliminatedOnes ~= 0
%         value = uint8(255);
%     else
%         data = bitshift(data, -4);
%         
%         value = double(data) * 255 / whiteThreshold;
%         value = uint8( value );
%     end
%     
%     fprintf('%d', value);
% 
%     fprintf('\n');
% end
% fprintf('\n');

fclose(cih_file);
fclose(raw_file);