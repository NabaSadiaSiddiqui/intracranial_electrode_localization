function view_grid(src, event, handles)
%VIEW_GRID Summary of this function goes here
%   Detailed explanation goes here
    grid_add();
    
    global grids;
    grid_list = {};
    for grid = grids
        grid_list = [grid_list, {grid.name}];
    end
    
    [s,v] = listdlg('PromptString', 'Select a grid to view',...
                'SelectionMode', 'single',...
                'ListString', grid_list);
    
    global h_grid;
    if v == 1
        h_grid = Grid();
        h_grid.copy_data(grids(s));
        h_grid.setup_electrode_grid();
        NeuroimagingWindow.mock_2D_window(h_grid);
        NeuroimagingWindow.refresh_grid(h_grid);
    end

end

