function save_elec_info(src, event, handles)
    grid_add();
    
    global grids;
    
    fid = fopen('result.txt', 'wt+');
    fprintf(fid, 'GridName,GridRows,GridCols,MarkedElectrodes,DisabledElectrodes\n');
    for grid = grids
        fprintf(fid, '%s,',grid.name);
        fprintf(fid, '%s,',grid.xDim);
        fprintf(fid, '%s,',grid.yDim);
        fprintf(fid, '%s,',grid.markedElectrodes);
        fprintf(fid, '%s\n',grid.disabledElectrodes);
    end
    fclose(fid);
end