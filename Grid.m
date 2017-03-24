classdef Grid < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        GridDimensionsX;
        GridDimensionsY;
        GridName;
        GridElectrodeDropdown;
        GridMarkedElectrodes = containers.Map;
        GridAxes;
        GridDisabledElectrodes = [];
        GridCurrElectrodeDisabled;
        GridColor = [0, 0, 1];
    end
    
    methods
        function obj = Grid
            uicontrol('style', 'frame', 'units', 'normalized', 'position', [0.5 0 1 1]);
            uicontrol('style','text', 'units','normalized', 'position',[0.505 0.85 0.15 0.09], 'string','Grid Properties');
            uicontrol('style', 'frame', 'units', 'normalized', 'position', [0.51 0.64 0.485 0.25]);
            uicontrol('style','text', 'units','normalized', 'position',[0.52 0.75 0.1 0.1], 'string','Name:');
            h_grid_name = uicontrol('style','edit', 'units','normalized', 'position',[0.66 0.75 0.19 0.1], 'string','Grid X');
            uicontrol('style', 'pushbutton', 'units', 'normalized', 'position', [0.85 0.75 0.14 0.1],'string','Color', 'callBack', {@obj.color_callback});
            uicontrol('style','text', 'units','normalized', 'position',[0.52 0.65 0.14 0.1], 'string','Dimensions:');
            h_grid_dim_x =  uicontrol('style','edit', 'units','normalized', 'position',[0.66 0.65 0.09 0.1], 'string','8');
            h_grid_dim_y =  uicontrol('style','edit', 'units','normalized', 'position',[0.76 0.65 0.09 0.1], 'string','8');
            uicontrol('style', 'pushbutton', 'units','normalized', 'position', [0.85 0.65 0.14 0.1], 'string', 'Update Grid', 'callback', {@obj.setup_electrode_grid_callback});
            obj.GridDimensionsX = h_grid_dim_x;
            obj.GridDimensionsY = h_grid_dim_y;
            obj.GridName = h_grid_name;
            obj.GridMarkedElectrodes = containers.Map;
            obj.GridDisabledElectrodes = [];
            obj.GridColor = [0, 0, 1];
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
        
        function set.GridDisabledElectrodes(obj, value)
            obj.GridDisabledElectrodes = value;
        end
        
        function set.GridAxes(obj, value)
            obj.GridAxes = value;
        end
        
        function set.GridCurrElectrodeDisabled(obj, value)
            obj.GridCurrElectrodeDisabled = value;
        end
        
        function set.GridColor(obj, value)
            obj.GridColor = value;
        end
        
        function setup_electrode_grid(obj)
            grid_dim_x = str2num(obj.GridDimensionsX.String);
            grid_dim_y = str2num(obj.GridDimensionsY.String);
            obj.create_electrode_drop_down(grid_dim_x, grid_dim_y);
            obj.create_grid(grid_dim_x, grid_dim_y);
        end
        
        function setup_electrode_grid_callback(obj, src, event, handles)
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
            obj.GridElectrodeDropdown = uicontrol('style','popup', 'units','normalized', 'position',[0.505 0.5 0.495 0.05], 'string', options, 'callback', {@obj.electrode_dropdown});
            uicontrol('style', 'text', 'units', 'normalized', 'position', [0.505 0.45 0.15 0.05], 'string', 'Disable electrode');
            obj.GridCurrElectrodeDisabled = uicontrol('style','checkbox', 'units', 'normalized', 'position', [0.7 0.45 0.05 0.05], 'value', 0, 'callback', {@obj.update_disabled_electrodes});
        end
        
        function create_grid(obj, dim_x, dim_y)
            % Delete current axis. This is for cases when you want to create a new
            % new grid of electrodes, and remove existing grid that is already
            % drawn
            delete(obj.GridAxes);
            % Create grid
            % xtick = [] and ytick = [] turns off labels
            obj.GridAxes = axes('position', [0.15 0.05 0.2 0.2]);
            sz = 75;
            hold on;
            for x = linspace(1, dim_x, dim_x)
                for y = linspace(1, dim_y, dim_y)
                    %scatter(x, y, sz, 'filled', obj.GridColor);
                    scatter(x, y, sz, 'filled', 'r');
                end
            end
            hold off;
            % Remove axes border
            set(obj.GridAxes,'Visible','off')
        end
        
        function update_disabled_electrodes(obj, checkbox, event, handles)
            % Update the state of the variable 'GridDisabledElectrodes'
            % depending on whether or not the user has checked or unchecked
            % the 'Disable Electrode' checkbox
            selected_value = obj.get_selected_electrode_from_dropdown();
            if (get(checkbox,'Value') == get(checkbox,'Max')) % User checked the checkbox --> add to list
                isPresent = 0;
                for electrode = obj.GridDisabledElectrodes
                    if electrode == selected_value
                        isPresent = 1;
                    end
                end
                if isPresent == 0
                    obj.GridDisabledElectrodes = [obj.GridDisabledElectrodes, selected_value];
                end
            else % User unchecked checkbox --> remove from list
                isPresent = 0;
                index = 1;
                selected_value_index = 0;
                for electrode = obj.GridDisabledElectrodes
                    if electrode == selected_value
                        isPresent = 1;
                        selected_value_index = index;
                    end
                    index = index + 1;
                end
                if isPresent
                    obj.GridDisabledElectrodes(selected_value_index) = [];
                end
            end
        end
        
        function add_marked_electrode(obj, grid_electrode, brain_electrode)
            % Map the value of selected drop down to clicked position on
            % neuroimaging window
            obj.GridMarkedElectrodes(grid_electrode) = brain_electrode;
        end
        
        function color_callback(obj, uicolor, event, handles)
          obj.GridColor = uisetcolor;
          disp(obj.GridColor);
        end
        
        function electrode_dropdown(obj, dropdown, event, handles)
            % Preserve the state of checkbox
            % If the selected electrode value from dropdown was previously
            % marked as disabled, then set the value of checkbox to 1
            % Otherwise, set the value of checkbox to 0
            selected_value = obj.get_selected_electrode_from_dropdown();
            isPresent = 0;
            disabled_electrodes = strsplit(obj.GridDisabledElectrodes, ')(');
            for disabled_electrode = disabled_electrodes
                token = strtok(disabled_electrode, ')');
                token2 = strtok(token, '(');
                electrode = string(strcat('(', token2, ')'));
                if strcmp(electrode, string(selected_value)) == 1
                    isPresent = 1;
                end
            end
            if isPresent == 0
                set(obj.GridCurrElectrodeDisabled, 'Value', 0);
            else
                set(obj.GridCurrElectrodeDisabled, 'Value', 1);
            end
        end
        
        function selected_electrode = get_selected_electrode_from_dropdown(obj)
            % Get the value of selected electrode from dropdown
            electrode_drop_down = obj.GridElectrodeDropdown;
            selected_index = electrode_drop_down.Value;
            selected_electrode = electrode_drop_down.String(selected_index,:);
        end
        
        function increment_electrode_dropdown(obj)
            % Set the electrode dropdown value to next element in the list
            electrode_dropdown = obj.GridElectrodeDropdown;
            selected_index = electrode_dropdown.Value;
            electrode_dropdown.Value = selected_index + 1;
        end
        
        function copy_data(obj, src)
            obj.GridName.String = src.name;
            obj.GridDimensionsX.String = src.xDim;
            obj.GridDimensionsY.String = src.yDim;
            marked_electrodes_arr = strsplit(src.markedElectrodes, ']');
            for marked_electrode = marked_electrodes_arr
                if strcmp(marked_electrode, '') == 0
                    token = strtok(marked_electrode, '[');
                    marked_electrode_clean = strsplit(string(token), '),(');
                    grid_electrode = strcat(marked_electrode_clean(1), ')');
                    brain_electrode = strcat('(', marked_electrode_clean(2));
                    obj.add_marked_electrode(char(grid_electrode), char(brain_electrode))
                end
            end
            if strcmp(src.disabledElectrodes, '') == 0
                obj.GridDisabledElectrodes = src.disabledElectrodes;
            end
        end
        
    end
end

