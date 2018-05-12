% I=readmraw('Photron_mraw_example',[1 10]);
% for n=1:1:10
% imshow(I.Images.RawImages(:,:,n),[0 3000]);
% pause(.1);
% end

% path = 'Photron_MRAW_read_function\';
% filename = 'example';
% 
% cih_file = fopen( sprintf('%s%s.cih', path,filename), 'r' );
% mraw_file = fopen( sprintf('%s%s.mraw', path,filename), 'r' );
% 
% header = textscan(cih_file, '%s', 'delimiter', ':');
% 
% frames = str2double( cell2mat(header{1}(32)) );
% 
% % If NaN, go back 1 index
% if isnan(frames)
%     frames = str2double( cell2mat(header{1}(31)) );
%     width = str2double( cell2mat(header{1}(39)) );
%     height = str2double( cell2mat(header{1}(41)) );