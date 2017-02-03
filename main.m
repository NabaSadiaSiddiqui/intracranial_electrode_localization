
h_figure_whole = figure('MenuBar', 'none', 'Color', 'white');
% Create frame object that represents NeuroImaging window
h_frame_left = uicontrol('style', 'frame', 'units', 'normalized', 'position', [0 0.3 0.5 1]);

% Create frame object that represents electrode editing controls
h_frame_right = uicontrol('style', 'frame', 'units', 'normalized', 'position', [0.5 0 1 1]);
% Grid properties
h_text_grid =  uicontrol('style','text', 'units','normalized', 'position',[0.505 0.85 0.15 0.09], 'string','Grid Properties');
h_frame_grid = uicontrol('style', 'frame', 'units', 'normalized', 'position', [0.51 0.64 0.49 0.25]);
h_text_grid_name =  uicontrol('style','text', 'units','normalized', 'position',[0.52 0.75 0.1 0.1], 'string','Name:');
h_edit_grid_name =  uicontrol('style','edit', 'units','normalized', 'position',[0.66 0.75 0.19 0.1], 'string','Grid X');
h_text_grid_dimensions =  uicontrol('style','text', 'units','normalized', 'position',[0.52 0.65 0.14 0.1], 'string','Dimensions:');
h_edit_grid_dimensions_x =  uicontrol('style','edit', 'units','normalized', 'position',[0.66 0.65 0.09 0.1], 'string','8');
h_edit_grid_dimensions_y =  uicontrol('style','edit', 'units','normalized', 'position',[0.76 0.65 0.09 0.1], 'string','8');
h_push_button_grid_dimensions = uicontrol('style', 'pushbutton', 'units','normalized', 'position', [0.85 0.65 0.15 0.1], 'string', 'Update Grid', 'callback', {@setup_electrode_grid_callback, h_edit_grid_dimensions_x, h_edit_grid_dimensions_y});  

setup_electrode_grid(h_edit_grid_dimensions_x, h_edit_grid_dimensions_y);

create_mock_2D_neuroimaging_window();

function create_mock_2D_neuroimaging_window
    uicontrol('style', 'pushbutton', 'units','normalized', 'position', [0.1 0.5 0.3 0.3], 'string', 'Click here', 'callback', @mock_image_clicked);  
end

function mock_image_clicked(src, event)
    global electrode_drop_down;
    selected_index = electrode_drop_down.Value;
    selected_value = electrode_drop_down.String(selected_index,:);
    x_and_y = char(strsplit(selected_value, ','));
    x = str2num(x_and_y(1, 2:end));
    y = str2num(x_and_y(2, 1:end-1));
    hold on;
    plot(y, x, '-ob');
    hold off;
end

function create_electrode_drop_down(dim_x, dim_y)
    global electrode_drop_down;
    
    % Drop down list to select electrodes
    options = '';
    for x = linspace(1, dim_x, dim_x)
        for y = linspace(1, dim_y, dim_y)
            option = strcat('(', num2str(x), ',', num2str(y), ')');
            options = strcat(options, '|', option);
        end
    end
    options = options(2:end);
    
    uicontrol('style','text', 'units','normalized', 'position',[0.505 0.55 0.15 0.05], 'string', 'Pick an electrode');
    electrode_drop_down = uicontrol('style','popup', 'units','normalized', 'position',[0.505 0.5 0.495 0.05], 'string', options);
end

function create_grid( dim_x, dim_y )
    % Delete current axis. This is for cases when you want to create a new
    % new grid of electrodes, and remove existing grid that is already
    % drawn
    delete(gca);
    % Create grid
    % xtick = [] and ytick = [] turns off labels
    axes('position', [0.15 0.05 0.2 0.2],'box','off', 'xtick', [], 'ytick', []);
    x = linspace(1, dim_x, dim_x);
    y = linspace(1, dim_y, dim_y);
    [X, Y] = meshgrid(y,x);
    plot(X, Y, '-dr');
    % Remove axes border
    set(gca,'Visible','off')
end

function setup_electrode_grid(h_grid_dim_x, h_grid_dim_y)
    % Read dimensions for creating grid
    h_grid_x = str2num(h_grid_dim_x.String);
    h_grid_y = str2num(h_grid_dim_y.String);
    create_electrode_drop_down(h_grid_x, h_grid_y);
    create_grid(h_grid_x, h_grid_y);
end

function setup_electrode_grid_callback(src, event, handle_x, handle_y)
    setup_electrode_grid(handle_x, handle_y)
end