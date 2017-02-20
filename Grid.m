classdef Grid < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        GridDimensionsX;
        GridDimensionsY;
        GridName;
        GridElectrodeDropdown;
        GridMarkedElectrodes = [];
        GridAxes;
    end
    
    methods
        function obj = Grid
            uicontrol('style', 'frame', 'units', 'normalized', 'position', [0.5 0 1 1]);
            uicontrol('style','text', 'units','normalized', 'position',[0.505 0.85 0.15 0.09], 'string','Grid Properties');
            uicontrol('style', 'frame', 'units', 'normalized', 'position', [0.51 0.64 0.49 0.25]);
            uicontrol('style','text', 'units','normalized', 'position',[0.52 0.75 0.1 0.1], 'string','Name:');
            h_grid_name = uicontrol('style','edit', 'units','normalized', 'position',[0.66 0.75 0.19 0.1], 'string','Grid X');
            uicontrol('style','text', 'units','normalized', 'position',[0.52 0.65 0.14 0.1], 'string','Dimensions:');
            h_grid_dim_x =  uicontrol('style','edit', 'units','normalized', 'position',[0.66 0.65 0.09 0.1], 'string','8');
            h_grid_dim_y =  uicontrol('style','edit', 'units','normalized', 'position',[0.76 0.65 0.09 0.1], 'string','8');
            uicontrol('style', 'pushbutton', 'units','normalized', 'position', [0.85 0.65 0.15 0.1], 'string', 'Update Grid', 'callback', {@obj.setup_electrode_grid_callback});
            obj.GridDimensionsX = h_grid_dim_x;
            obj.GridDimensionsY = h_grid_dim_y;
            obj.GridName = h_grid_name;
        end
        
        function set.GridDimensionsX(obj, value)
            obj.GridDimensionsX = value;
        end
        
        function set.GridDimensionsY(obj, value)
            obj.GridDimensionsY = value;
        end
        
        function set.GridName(obj, value)
            obj.GridName = value;
        end
        
        function set.GridElectrodeDropdown(obj, value)
            obj.GridElectrodeDropdown = value;
        end
        
        function set.GridMarkedElectrodes(obj, value)
            obj.GridMarkedElectrodes = value;
        end
        
        function set.GridAxes(obj, value)
            obj.GridAxes = value;
        end
        
        function setup_electrode_grid(obj)
            grid_dim_x = str2num(obj.GridDimensionsX.String);
            grid_dim_y = str2num(obj.GridDimensionsY.String);
            obj.create_electrode_drop_down(grid_dim_x, grid_dim_y);
            obj.create_grid(grid_dim_x, grid_dim_y);
        end
        
        function setup_electrode_grid_callback(obj, src, event)
            obj.setup_electrode_grid();
        end
        
        function create_electrode_drop_down(obj, dim_x, dim_y)
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
            obj.GridElectrodeDropdown = uicontrol('style','popup', 'units','normalized', 'position',[0.505 0.5 0.495 0.05], 'string', options);
        end
        
        function create_grid(obj, dim_x, dim_y)
            % Delete current axis. This is for cases when you want to create a new
            % new grid of electrodes, and remove existing grid that is already
            % drawn
            delete(obj.GridAxes);
            % Create grid
            % xtick = [] and ytick = [] turns off labels
            obj.GridAxes = axes('position', [0.15 0.05 0.2 0.2],'box','off', 'xtick', [], 'ytick', []);
            x = linspace(1, dim_x, dim_x);
            y = linspace(1, dim_y, dim_y);
            [X, Y] = meshgrid(y,x);
            plot(X, Y, '-dr');
            % Remove axes border
            set(obj.GridAxes,'Visible','off')
        end
        
        function add_marked_electrode(obj, electrode)
            obj.GridMarkedElectrodes = [obj.GridMarkedElectrodes, electrode];
        end
    end
    
end

