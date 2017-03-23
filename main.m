h_figure_whole = figure('MenuBar', 'none', 'Color', 'white');

global grids;
grids = [];

global h_grid;
h_grid = Grid();
h_grid.setup_electrode_grid();

h_menu = uimenu(h_figure_whole,'Label','File');
menu_grid_add = uimenu(h_menu, 'Label', 'Add Grid', 'callback', {@new_grid});
menu_grid_delete = uimenu(h_menu, 'Label', 'Delete Grid', 'callback', {@delete_grid});
menu_save = uimenu(h_menu, 'Label', 'Save', 'callback', {@save_elec_info});

NeuroimagingWindow.mock_2D_window(h_grid);
