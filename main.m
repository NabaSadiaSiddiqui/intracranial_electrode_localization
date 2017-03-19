h_figure_whole = figure('MenuBar', 'none', 'Color', 'white');

global grids;
grids = [];

global h_grid;
h_grid = Grid();
h_grid.setup_electrode_grid();

h_menu = uimenu(h_figure_whole,'Label','File');
menu_grid_add = uimenu(h_menu, 'Label', 'Add Grid', 'callback', {@new_grid});
menu_save = uimenu(h_menu, 'Label', 'Save', 'callback', {@save});

NeuroimagingWindow.mock_2D_window(h_grid);

function new_grid(src, event, handles)
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

    h_grid = Grid();
    h_grid.setup_electrode_grid();
    
    NeuroimagingWindow.mock_2D_window(h_grid);
end

function save(src, event, handles)
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