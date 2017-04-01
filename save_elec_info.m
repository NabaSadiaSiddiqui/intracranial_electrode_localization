function save_elec_info(src, event, handles)
    grid_add();
    
    folder_name = uigetdir('~/', 'Choose the location to save file to');
    if folder_name ~= 0
        global grids;
    
        filename = strcat(folder_name, '/', 'result.txt');
        fid = fopen(filename, 'wt+');
        fprintf(fid, 'GridName,GridRows,GridCols,MarkedElectrodes,DisabledElectrodes\n');
        for grid = grids
            fprintf(fid, '%s,',grid.name);
            fprintf(fid, '%s,',grid.xDim);
            fprintf(fid, '%s,',grid.yDim);
            fprintf(fid, '%s,',grid.markedElectrodes);
            fprintf(fid, '%s\n',grid.disabledElectrodes);
        end
        fclose(fid);
        msg = strcat('Work from current session has been saved to ', filename);
        title = 'Save';
        msgbox(msg, title)
    end
end