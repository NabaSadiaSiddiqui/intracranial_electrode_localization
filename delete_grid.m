function delete_grid(src, event, handles)
%VIEW_GRIDS Summary of this function goes here
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
    grids = [grids, aGrid];
    
    grid_list = {};
    for grid = grids
        grid_list = [grid_list, {grid.name}];
    end
    
    [s,v] = listdlg('PromptString', 'Select a grid to delete',...
                'SelectionMode', 'single',...
                'ListString', grid_list);
    
    if v == 1
        grids(s) = [];
    end
end

