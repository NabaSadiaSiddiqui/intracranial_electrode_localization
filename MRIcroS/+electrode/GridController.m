classdef GridController < handle
    %electrode.GridController
    %   Portions of this code 
    
    properties(Access = protected)
        grids = {}
        selected = NaN(1, 2)
        gui_controller
        figure_controller
    end
    properties(Access = public, Constant)
        GRID_DEFAULT = [ 8, 8 ]
    end
    
    methods(Access = public)
        function obj = GridController(gui_controller)
            obj.gui_controller = gui_controller;
        end
        function figure_controller = get_figure_controller(this)
            figure_controller = this.figure_controller;
        end
        % <<Canonical>>
        function dims = get_current_dims(this)
            % Canonical current dimension
            dims = this.grids{this.get_current_grid()}.dims;
        end
        function mark(this, centroid, C, enabled)
%             assert(~any(isnan(this.selected)),...
%                 'GridController::mark:BadMethodCallException',...
%                 'Attempted to mark with no marker selected');
            idx = this.get_current_grid();
            this.grids{idx}.mark(centroid, C, enabled);
            
            this.select_if_exists(C);
        end
        % Mutators
        function add_grid(this, name, width, height)
            this.unselect_last_selected();
            this.grids{length(this.grids) + 1} = electrode.Grid(name, width, height);
        end
        function update_grid_dims(this)
            idx = this.get_current_grid();
            this.grids{idx}.dims = this.gui_controller.update_grid_dims();
        end
%         function unmark_current(this)
%             idx = this.get_current_grid();
%             if ~any(isnan(this.selected)) % &&...
%                % ~isempty()
%                 this.gui_controller.unmark(this.selected);
%                 this.grids{idx}.unmark(this.selected);
%             end
%         end
        function exists = unmark_if_exists(this, C)
            % for model consistency, MUST be called from GUIController
            exists = false;
            
            dims = this.get_current_dims();
            idx = this.get_current_grid();
            if all(1 <= C & C <= dims)
                if this.grids{idx}.has_marker(C)
                    this.grids{idx}.unmark(C);
                    
                    exists = true;
                end
            end
        end
        function exists = select_if_exists(this, C)
            % for model consistency, MUST be called from GUIController
            exists = false;
            
            dims = this.get_current_dims();
            idx = this.get_current_grid();
            if all(1 <= C & C <= dims)
                this.unselect_last_selected();
                if this.grids{idx}.has_marker(C)
                    this.grids{idx}.select(C);
                    
                    exists = true;
                end
                this.selected = C;
            end
        end
        function maybe = in_range(this, C)
            idx = this.get_current_grid();
            maybe = all(1 <= C & C <= this.grids{idx}.dims);
        end
    end
    methods(Access = protected)
        function idx = get_current_grid(this)
            idx = this.gui_controller.get_current_grid();
        end
        function unselect_last_selected(this)
            if ~any(isnan(this.selected))
                idx = this.get_current_grid();
                
                if this.grids{idx}.has_marker(this.selected)
                    this.grids{idx}.unselect(this.selected);
                    this.gui_controller.unselect(this.selected);
                end
                
                this.selected = NaN(1, 2);
            end
            % else % no-op
        end
        function color = next_color(varargin)
            color = [ 0.8500    0.3250    0.0980 ]; % burnt orange
        end
    end
    methods(Access = protected, Static)
    end
end