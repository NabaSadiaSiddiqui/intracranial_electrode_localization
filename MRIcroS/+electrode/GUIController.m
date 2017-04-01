classdef GUIController < handle
    properties(Access = public)
        f_mutables
        h_menus
    end
    properties(Access = protected)
        f_gui_root
        prefs
        grid_controller
        figure_controller
        indicators
        ghost_indicator
    end
    properties(Access = protected, Constant)
        LABEL_HEIGHT = 16
        INPUT_HEIGHT = 22
        DEFAULT_AZ_EL = [ 45, 45 ]
        SZ = [ 960, 680 ]
        GRID_DEFAULT = [ 8, 8 ]
        NAME_DEFAULT = 'Unnamed'
    end
    
    methods(Access = public)
        % <<EntryPoint>>
        function obj = GUIController(varargin)
            obj.checkVersionSub();
            
            obj.grid_controller = electrode.GridController(obj);
            obj.indicators = {};
            % cell(obj.grid_controller.GRID_DEFAULT(1), obj.grid_controller.GRID_DEFAULT(2))
            
            [ hFigure, hAxes ] = obj.make_gui_sub();
            obj.prefs_sub();
            obj.make_menus_sub(hFigure);
            
            obj.figure_controller = electrode.FigureController(obj, hFigure, hAxes, varargin{:});
            
            set(hFigure, 'ResizeFcn', @(~, ~) obj.reposition_all());
            set(hFigure, 'KeyPressFcn', @obj.keypress_handler);
             % crucial to make GUI (including figures) before passing to FigureController
            
            %display results
            obj.add_default_grid();
            obj.reposition_all();
            obj.figure_controller.redraw();
            obj.figure_controller.view(obj.DEFAULT_AZ_EL(1), obj.DEFAULT_AZ_EL(2));
            
            obj.ghost_indicator = rectangle(obj.f_mutables.ax_grid,...
                'Position', [ 0, 0, 1, 1 ], ...
                'FaceColor', [ .91, .91, .91 ],...
                'EdgeColor', [ .86, .86, .86 ]);
        end
        function figure_controller = get_figure_controller(this)
            figure_controller = this.figure_controller;
        end
        function keypress_handler(this, ~, ev)
            move_keymap = containers.Map(...
                { 'leftarrow', 'rightarrow', 'uparrow', 'downarrow',...
                  'a', 'd', 'w', 's' }, ...
                { [ -1 0 ], [ 1 0 ], [ 0 1 ], [ 0 -1 ],...
                  [ -1 0 ], [ 1 0 ], [ 0 1 ], [ 0 -1 ] }...
            );
            if move_keymap.isKey(ev.Key)
                direction = move_keymap(ev.Key);
                if any(strcmp(ev.Modifier, 'shift'))

                else
                    this.select(this.poll_electrode_idx() + direction);
                end
            elseif strcmp(ev.Key, 'escape')
                this.unmark(this.poll_electrode_idx());
            end
        end
        function update_grid_name(this, new_name)
            this.f_mutables.h_grid_name.String = new_name;
            this.f_mutables.h_grid_dropdown.String{this.f_mutables.h_grid_dropdown.Value} = new_name;
            this.grid_controller.update_grid_name(new_name);
        end
        function new_dims = update_grid_dims(this)
            new_dims = [...
                str2num(this.f_mutables.h_edit_grid_dimensions_x.String), ...
                str2num(this.f_mutables.h_edit_grid_dimensions_y.String) ...
            ];
            
            this.grid_controller.update_grid_dims(new_dims);
        
            new_C = min(new_dims, this.poll_electrode_idx());
            
            this.f_mutables.h_electrode_x.String = 1:new_dims(1);
            this.f_mutables.h_electrode_y.String = 1:new_dims(2);
            
            this.f_mutables.h_electrode_x.Value = new_C(1);
            this.f_mutables.h_electrode_y.Value = new_C(2);
            
            xlim(this.f_mutables.ax_grid, [0, new_dims(1)]);
            ylim(this.f_mutables.ax_grid, [0, new_dims(2)]);
        end
        function add_default_grid(this)
            % mutate model
            this.grid_controller.add_grid(this.NAME_DEFAULT, this.GRID_DEFAULT(1),  this.GRID_DEFAULT(2)); % mutate model
            this.f_mutables.h_grid_dropdown.String{length(this.f_mutables.h_grid_dropdown.String) + 1} = this.NAME_DEFAULT;
            this.switch_grid(length(this.f_mutables.h_grid_dropdown.String));
        end
        function switch_grid(this, idx)
            this.grid_controller.unselect_last_selected();
            
            this.f_mutables.h_grid_dropdown.Value = idx;
            
            grid = this.grid_controller.get_grid(idx);
            coords = grid.get_marked_coords();
            for i = 1:size(this.indicators, 1)
                for j = 1:size(this.indicators, 2)
                    delete(this.indicators{ i, j });
                    this.indicators{i, j} = [];
                end
            end
            for i = 1:length(coords)
                this.mark_indicator(coords{i});
                this.unselect(coords{i});
            end
            
            this.f_mutables.h_grid_name.String = grid.name;
            this.f_mutables.h_electrode_x.String = 1:grid.dims(1);
            this.f_mutables.h_electrode_y.String = 1:grid.dims(2);
            this.f_mutables.h_edit_grid_dimensions_x.String = grid.dims(1);
            this.f_mutables.h_edit_grid_dimensions_y.String = grid.dims(2);
            this.f_mutables.h_electrode_x.Value = grid.selected(1);
            this.f_mutables.h_electrode_y.Value = grid.selected(2);
            set(this.f_mutables.ax_grid, 'xtick', 1:grid.dims(1));
            set(this.f_mutables.ax_grid, 'ytick', 1:grid.dims(2));
            xlim(this.f_mutables.ax_grid, [ 0, grid.dims(1) ]);
            ylim(this.f_mutables.ax_grid, [ 0, grid.dims(2) ]);
            
            this.select(grid.selected);
        end
        % <<Canonical>>
        function prefs = get_prefs(this)
            prefs = this.prefs;
        end
        % <<Canonical>>
        function idx = get_current_grid(this)
            % canonical grid idx
            idx = this.f_mutables.h_grid_dropdown.Value;
        end
        
        function delete_current_grid(this)
            idx = this.get_current_grid();
            num = this.grid_controller.get_num_grids();
            this.grid_controller.delete_grid(idx);
            this.f_mutables.h_grid_dropdown.String(idx) = [];
            if idx == num
                if idx == 1
                    this.add_default_grid();
                else
                    this.f_mutables.h_grid_dropdown.Value = idx - 1;
                    this.f_mutables.h_grid_dropdown.Callback(this.f_mutables.h_grid_dropdown, []);
                end
            end
        end
        function C = poll_electrode_idx(this)
            C = [ this.f_mutables.h_electrode_x.Value, ...
                  this.f_mutables.h_electrode_y.Value ...
                ];
        end
        function mark(this, centroid, enabled)
            C = this.poll_electrode_idx;
            this.grid_controller.mark(centroid, C, enabled);
            this.mark_indicator(C);
            this.select(C);
        end
        function mark_indicator(this, C)
            if this.has_indicator(C)
                set(this.indicators{C(1), C(2)}, 'FaceColor', 'cyan');
            else
                indicator = rectangle(this.f_mutables.ax_grid,...
                            'Position', [ (C - ones(size(C))), 1.0, 1.0 ], ...
                            'FaceColor', 'cyan');
                set(indicator, 'ButtonDownFcn', @(~, ~) this.select(C));
                this.indicators{C(1), C(2)} = indicator;
            end
        end
        function select(this, C)
            if this.grid_controller.in_range(C)
                this.f_mutables.h_electrode_x.Value = C(1);
                this.f_mutables.h_electrode_y.Value = C(2);

                if this.grid_controller.select_if_exists(C)
                    % a view inconsistency will (and should really) trigger an
                    % error
                    set(this.indicators{C(1), C(2)}, 'FaceColor', 'cyan');
                    set(this.ghost_indicator, 'Visible', 'off');
                    set(this.f_mutables.h_unmark_button, 'Visible', 'on');
                else
                    % ghost-select unmarked spaces
                    set(this.ghost_indicator, 'Position', [ C - ones(size(C)), 1.0, 1.0 ] );
                    set(this.ghost_indicator, 'Visible', 'on');
                end
            end
        end
%         function ghost_select(this, C)
%             % select iff there isn't a marker at C. The caller must have
%             % that knowledge to distinguish calling this::ghost_select vs.
%             % this::select
%             this.f_mutables.h_electrode_x.Value = C(1);
%             this.f_mutables.h_electrode_y.Value = C(2);
%         end
        function unselect(this, C)
            if this.has_indicator(C)
                set(this.indicators{C(1), C(2)}, 'FaceColor', 'red');
            end
            
            set(this.f_mutables.h_unmark_button, 'Visible', 'Off');
        end
        function unselect_all(this)
            dims = this.get_characteristic_dims();

            for i = 1:dims(1)
                for j = 1:dims(2)
                    this.unselect([i, j]);
                end
            end
        end
        function unmark(this, C)
            if this.grid_controller.unmark_if_exists(C)
                % again, a view inconsistency will (and should really) 
                % trigger an error
                delete(this.indicators{C(1), C(2)});
            end
            this.indicators{C(1), C(2)} = [];
            set(this.f_mutables.h_unmark_button, 'Visible', 'Off');
        end
        function unmark_all(this)
            dims = this.get_characteristic_dims();
            for i = 1:dims(1)
                for j = 1:dims(2)
                    this.unmark([i, j]);
                end
            end
        end
    end
    methods(Access = protected)
        function maybe = has_indicator(this, C)
            maybe = all(C <= size(this.indicators)) && ~isempty(this.indicators{C(1), C(2)});
        end
        function dims = get_characteristic_dims(this)
            dims = min(...
                this.grid_controller.get_current_dims(),...
                size(this.indicators)...
            ); % take the min of grid dims and actual filled indicators to save some time
        end
        function reposition_all(this)
            this.f_mutables.fAxes.reposition(this.SZ.');
            this.f_mutables.f_gui_root.reposition(this.SZ.');
        end
        function [ hFigure, hAxes ] = make_gui_sub(this)
            screensize = get(0,'ScreenSize');
            margin = [ceil((screensize(3)-this.SZ(1))/2) ceil((screensize(4)-this.SZ(2))/2)];
            hFigure = figure('MenuBar','none','Toolbar','none','HandleVisibility','on', ...
                'Tag', mfilename,'Name', mfilename, 'NumberTitle','off', ...
             'Color', get(0, 'defaultuicontrolbackgroundcolor'), ...
             'Position', [ margin, this.SZ ]);
            set(hFigure, 'Renderer', 'OpenGL');
            
            this.f_mutables.h_edit_grid_dimensions_x =  uicontrol('style','edit');
            this.f_mutables.h_edit_grid_dimensions_y =  uicontrol('style','edit');
            this.f_mutables.h_grid_dropdown = uicontrol('style', 'popup', 'Callback', @(src, ~) this.switch_grid(src.Value));
            % obj.f_mutables.h_grid_adder = uicontrol('style', 'pushbutton', 'string', 'Add Grid', 'Callback', @(~, ~) v_w.get().add_grid(this.NAME_DEFAULT, 8, 8));
            this.f_mutables.h_grid_name = uicontrol('style','edit', 'HorizontalAlignment', 'Left', 'Callback', @(src, ~) this.update_grid_name(src.String));
            % v.h_push_button_grid_dimensions = uicontrol('style', 'pushbutton', 'string', 'Update Grid', 'callback', {@setup_electrode_grid_callback, v.h_edit_grid_dimensions_x, v.h_edit_grid_dimensions_y}, 'position', [0.35 0.65 0.15 0.1]);

            this.f_mutables.h_unmark_button = uicontrol('style', 'pushbutton', 'string', 'Unmark', 'Visible', 'Off', 'Callback', @(~, ~) this.unmark(this.poll_electrode_idx()));

            % uicontrol('style','text', 'position',[0.005 0.55 0.15 0.05], 'string', 'Pick an electrode');
            % v.h_electrode_drop_down = uicontrol('style','popup');
            this.f_mutables.h_electrode_x = uicontrol('style', 'popup', 'Callback', ...
                @(src, ev) this.select([ this.f_mutables.h_electrode_x.Value, this.f_mutables.h_electrode_y.Value ]));
            this.f_mutables.h_electrode_y = uicontrol('style', 'popup', 'Callback', ...
                @(src, ev) this.select([ this.f_mutables.h_electrode_x.Value, this.f_mutables.h_electrode_y.Value ]));

            set(this.f_mutables.h_electrode_x, 'string', 1:this.GRID_DEFAULT(1));
            set(this.f_mutables.h_electrode_y, 'string', 1:this.GRID_DEFAULT(2));
            this.f_mutables.fAxes = gui.FloatingControl(axes('HandleVisibility', 'on', 'Parent', hFigure),...
                [ 0; 0 ], [[ -240, 1.0 ]; [ 0, 1.0 ]]...
            );
            hAxes = this.f_mutables.fAxes.get_root();
        
            this.f_mutables.f_gui_root = gui.FloatingControl(uipanel('Parent', hFigure), ...
                [ -240; 0.0 ], [[ 0, 1.0 ]; [ 0, 1.0 ]], [ ...
                    gui.FloatingControl(this.f_mutables.h_grid_dropdown, ...
                        [ 10; -25 ], [[ -60, 1.0 ]; [ this.LABEL_HEIGHT, 0.0 ] ]), ...
                    gui.FloatingControl(uicontrol('style', 'pushbutton', 'string', 'Add Grid', 'callback', @(~, ~) this.add_default_grid()),...
                        [ -60; -32 ], [[ -10, 1.0 ]; [ this.INPUT_HEIGHT, 0.0 ]]), ...
                    gui.FloatingControl(uipanel('BorderType', 'none'), ...
                        [ 10; -235 ], [[ -10, 1.0 ]; [ 200, 0.0 ]], [...
                            gui.FloatingControl(uicontrol('style','text', 'HorizontalAlignment', 'Left', 'string','Grid Properties'), ...
                                [ 0; -25 ], [[ 0, 1.0 ]; [ this.LABEL_HEIGHT, 0.0 ] ]), ...
                            gui.FloatingControl(uicontrol('style','text', 'HorizontalAlignment', 'Left', 'string','Name:'), ...
                                [ 15; -50 ], [ 35; this.LABEL_HEIGHT ]), ...
                            gui.FloatingControl(this.f_mutables.h_grid_name, ...
                                [ 90; -52 ], [[ 0, 1.0 ]; [ this.INPUT_HEIGHT, 0.0 ]]), ...
                            gui.FloatingControl(uicontrol('style','text', 'HorizontalAlignment', 'Left', 'string','Dimensions:'), ...
                                [ 15; -75 ], [ 60; this.LABEL_HEIGHT ]), ...
                            gui.FloatingControl(uipanel(), ...
                                [ 90; -77 ], [[ 0, 1.0 ]; [ this.INPUT_HEIGHT, 0.0 ]], [...
                                    gui.FloatingControl(this.f_mutables.h_edit_grid_dimensions_x, ...
                                        [0; 0], [[ 0, 0.5 ]; [ 0, 1.0 ]]), ...
                                    gui.FloatingControl(this.f_mutables.h_edit_grid_dimensions_y, ...
                                        [[ 0, 0.5 ]; [ 0, 0.0 ]], [[ 0, 1.0 ]; [ 0, 1.0 ]]) ...
                                ]), ...
                            gui.FloatingControl(uicontrol('style', 'pushbutton', 'string', 'Update Grid Dims', 'callback', @(~, ~) this.update_grid_dims()),...
                                [ 90; -100 ], [[ 0, 1.0 ]; [ this.INPUT_HEIGHT, 0.0 ]]), ...
                            gui.FloatingControl(uicontrol('style', 'pushbutton', 'string', 'Delete Grid', 'callback', @(~, ~) this.delete_current_grid()),...
                                [ 90; -140 ], [[ 0, 1.0 ]; [ this.INPUT_HEIGHT, 0.0 ]])
                        ]), ...
                    gui.FloatingControl(uicontrol('style', 'text', 'HorizontalAlignment', 'Left', 'string', 'Pick an electrode'), ...
                        [ 10; -225 ], [[ -10, 1.0 ]; [ this.INPUT_HEIGHT, 0.0 ]]), ...
                    gui.FloatingControl(uipanel('BorderType', 'none'), ...
                        [ 10; -265 ], [[ -10, 1.0 ]; [ 2*this.INPUT_HEIGHT, 0.0 ]], [...
                            gui.FloatingControl(this.f_mutables.h_electrode_x, ...
                                [0; 0], [[ 0, 0.5 ]; [ 0, 1.0 ]]), ...
                            gui.FloatingControl(this.f_mutables.h_electrode_y, ...
                                [[ 0, 0.5 ]; [ 0, 0.0 ]], [[ 0, 1.0 ]; [ 0, 1.0 ]]) ...
                            gui.FloatingControl(this.f_mutables.h_unmark_button, ...
                                [ 0; 1.0], [[ 0, 1.0 ]; [ this.INPUT_HEIGHT, 0 ]])...
                        ]), ...
                    gui.FloatingControl(uicontrol('style', 'checkbox', 'Callback', @this.grid_controller.disable_current), ...
                        [ 10; -290 ], [ 15; this.LABEL_HEIGHT ]), ...
                    gui.FloatingControl(uicontrol('style', 'text', 'string', 'Disable electrode', 'HorizontalAlignment', 'Left'), ...
                        [ 30; -290 ], [[ 0, 1.0 ]; [ this.LABEL_HEIGHT, 0.0 ]])...
                ]...
            );
        
            this.f_mutables.ax_grid = this.f_mutables.f_gui_root.add_child(gui.FloatingControl(axes('box', 'off',...
                    'xtick', 0:this.GRID_DEFAULT(1), 'ytick', 0:this.GRID_DEFAULT(2), ...
                    'xgrid', 'on', 'ygrid', 'on'), ...
                [ 10; 10 ], [[ -10, 1.0 ]; [ 240, 0.0 ]])).get_root();
            set(this.f_mutables.ax_grid, 'YTickLabel', []);
            set(this.f_mutables.ax_grid, 'XTickLabel', []);
            xlim(this.f_mutables.ax_grid, [0, this.GRID_DEFAULT(1)]);
            ylim(this.f_mutables.ax_grid, [0, this.GRID_DEFAULT(2)]);
        end
        function make_menus_sub(this, h_menus)
            h_menu_file = uimenu(h_menus,'Label','File');
            uimenu(h_menu_file, 'Label', 'Save', 'callback', {@this.save_session});
        end
        function prefs_sub(this)
            this.prefs.colors = [0.7 0.7 0.9 1.0; 1 0 0 1.0; 0 1 0 0.7; 0 0 1 0.7; 0.5 0.5 0 0.7; 0.5 0 0.5 0.7; 0 0.5 0.5 0.7]; %rgba for each layer CRZ
            this.prefs.edgeColors = this.prefs.colors;
            this.prefs.showEdges = zeros(size(this.prefs.colors, 1),1);

            this.prefs.materialKaKdKsn = [0.6 0.4 0.4 100.0];%ambient/diffuse/specular strength and specular exponent
            this.prefs.backFaceLighting = 1;
            this.prefs.azLight = 0; %light azimuth relative to camera
            this.prefs.elLight = 90; %light elevation relative to camera
            %v.prefs.elLight = 10; %light elevation relative to camera - 6767
            this.prefs.camLight = camlight(0, 90);
            this.prefs.lightangle = [];
            this.prefs.az = 45; %camera azimuth
            this.prefs.el = 10; %camera elevation
        end
        function save_session(this, src, event, handles)
            folder_name = uigetdir('~/', 'Choose the location to save file to');
            if folder_name ~= 0
                filename = strcat(folder_name, '/', 'result.mat');
                grids = this.grid_controller.get_grids();
                save(filename, 'grids');
                msg = strcat('Work from current session has been saved to ', filename);
                title = 'Save';
                msgbox(msg, title)
            end
        end
    end
    methods(Access = protected, Static)
        function checkVersionSub()
            % Copyright (c) 2015, Leonardo Bonilha, John Delgaizo and Chris Rorden
            % All rights reserved.
            % BSD License: https://www.mathworks.com/matlabcentral/fileexchange/56788-mricros
            if verLessThan('matlab', '7.09')
                error('This software requires Matlab 2009b or later (requires unused argument syntax, "[~ d] = version")');
                % http://blogs.mathworks.com/steve/2010/01/11/about-the-unused-argument-syntax-in-r2009b/
            end
            if verLessThan('matlab', '7.11')
               printf('WARNING: This software has only been tested on Matlab 2010b and later\n');
            end
        end
    end
end