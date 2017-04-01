function new_grid(src, event, handles)
    grid_add();

    global h_grid;
    
    h_grid = Grid();
    h_grid.setup_electrode_grid();
    
    NeuroimagingWindow.mock_2D_window(h_grid);
end
