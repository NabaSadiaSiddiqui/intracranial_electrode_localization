function save_elec_info(src, event, handles)
    global h_grid;
    
    keys_marked_electrodes = keys(h_grid.GridMarkedElectrodes);
    values_marked_electrodes = values(h_grid.GridMarkedElectrodes);
    marked_electrodes_map_to_str = '';
    for i = 1:length(h_grid.GridMarkedElectrodes)
        marked_electrode = strcat('[', keys_marked_electrodes{i}, ',', values_marked_electrodes{i}, ']');
        marked_electrodes_map_to_str = strcat(marked_electrodes_map_to_str, marked_electrode);
    end
    
    disabled_electrodes = '';
    if ~isempty(h_grid.GridDisabledElectrodes)
        disabled_electrodes = h_grid.GridDisabledElectrodes;
    end
    
    aGrid = struct('name', h_grid.GridName.String, ...
        'xDim', h_grid.GridDimensionsX.String, ...
        'yDim', h_grid.GridDimensionsY.String, ...
        'markedElectrodes', marked_electrodes_map_to_str, ...
        'disabledElectrodes', disabled_electrodes);
    
    global grids;
    grids = [grids, aGrid];
    
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