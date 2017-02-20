
h_figure_whole = figure('MenuBar', 'none', 'Color', 'white');

global grids;
grids = [];

global h_grid;
h_grid = Grid();
h_grid.setup_electrode_grid();

h_menu = uimenu(h_figure_whole,'Label','Grid');
menu_grid_add = uimenu(h_menu, 'Label', 'Add Grid', 'callback', {@new_grid});

NeuroimagingWindow.mock_2D_window(h_grid);



function new_grid(src, event, handles)
    global h_grid;
    aGrid = struct('name', h_grid.GridName.String, 'xDim', h_grid.GridDimensionsX.String, 'yDim', h_grid.GridDimensionsY.String, 'markedElectrodes', h_grid.GridMarkedElectrodes);
    
    global grids;
    grids = [grids, aGrid];

    h_grid = Grid();
    h_grid.setup_electrode_grid();
    
    for grid = grids
        disp(grid.markedElectrodes);
    end
end