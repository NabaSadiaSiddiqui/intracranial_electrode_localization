
h_figure_whole = figure('MenuBar', 'none', 'Color', 'white');

h_grid = Grid();
h_grid.setup_electrode_grid();

NeuroimagingWindow.mock_2D_window();

function hello
    disp('Naba');
end