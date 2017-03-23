function grid_add(src, event, handles)
%GRID_ADD Summary of this function goes here
%   Detailed explanation goes here
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
    exists = 0;
    for grid = grids
        if strcmp(grid.name, aGrid.name) == 1
            exists = 1;
        end
    end
    if exists == 0
        grids = [grids, aGrid];
    end
end

