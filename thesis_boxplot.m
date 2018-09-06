% matList = {'original_12-Jul-2018 200821', 'master_12-Jul-2018 124458', 'variance_roi_crop_12-Jul-2018 003515', 'gie_rgb2gray_results'};
% titles = {'Original', 'Mod', 'ROI', 'GIE'};

matList = {'roi_nocolor_rgb2gray_12-Jul-2018 022104', 'roi_nocolor_red_12-Jul-2018 011341', 'roi_nocolor_green_12-Jul-2018 020038', 'roi_nocolor_blue_12-Jul-2018 013751', ...
            'gie_red_results', 'gie_green_results', 'gie_blue_results'};
titles = {'rgb2gray', 'Red', 'Green', 'Blue', 'GIE Red', 'GIE Green', 'GIE Blue'};

for i = 1:length(matList)
    load( strcat('Output_contours\', matList{i}, '.mat') );
    
    % Write to .csv
    diceCsv = fopen(strcat('C:\Users\lucassalazar12\Google Drive - Sansano\Memoria\boxplot\', titles{i}, '_dice.csv'), 'w');
    fprintf(diceCsv, 'FN003 FN007 FP007 FP016 FN003_naso FP005_naso FP011_naso FD003_pre FN003_lombard MN003_adapt\n');
    for j = 1:20
        for k = 1:size(evaluationData,1)
            if k == size(evaluationData,1)
                fprintf( diceCsv, '%0.4f', evaluationData{k,2}(j) );
            else
                fprintf( diceCsv, '%0.4f ', evaluationData{k,2}(j) );
            end
            
        end
        fprintf(diceCsv, '\n');
    end
    fclose(diceCsv);
    
    aErrorCsv = fopen(strcat('C:\Users\lucassalazar12\Google Drive - Sansano\Memoria\boxplot\', titles{i}, '_areaerror.csv'), 'w');
    fprintf(aErrorCsv, 'FN003 FN007 FP007 FP016 FN003_naso FP005_naso FP011_naso FD003_pre FN003_lombard MN003_adapt\n');
    for j = 1:20
        for k = 1:size(evaluationData,1)
            if k == size(evaluationData,1)
                fprintf( aErrorCsv, '%0.4f', evaluationData{k,3}(j) );
            else
                fprintf( aErrorCsv, '%0.4f ', evaluationData{k,3}(j) );
            end
        end
        fprintf(aErrorCsv, '\n');
    end
    fclose(aErrorCsv);
    
    segData = cell2mat(evaluationData(:,2));
    segData = segData';
    
    figure
    boxplot( segData );
    title( titles{i} );
    ylim([-0.03 1])
    xticklabels({'FN003', 'FN007', 'FP007', 'FP016', 'FN003_naso', 'FP005_naso', 'FP011_naso', 'FD003_pre', 'FN003_lombard', 'MN003_adapt'})
    
end