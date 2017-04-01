classdef Grid < handle
    properties(Access = public)
        name
        markers
        h_linkages
        v_linkages
        selected = NaN(1, 2)
        dims
        color
    end
    properties(Access = public, Constant)
        MARKER_RAD = 3.0 % mm-radius
        DEFAULT_MARKER_COLOR = [ 1.0, 0, 0] % red
    end
    properties(Access = protected)
        figure_controller
    end
    methods(Access = public)
        function obj = Grid(name, width, height)
            if any([width, height] == [0, 0])
                error('Grid width and height must be non-negative integer.');
            end
            obj.name = name;
            obj.markers = {}; % cell(width, height)
            obj.h_linkages = {}; % NaN(width-1, height)
            obj.v_linkages = {}; % NaN(width, height-1) % fenceposts!
            obj.dims = [ width, height ];
            obj.selected = [ 1, 1 ];
            obj.color = obj.DEFAULT_MARKER_COLOR;
        end
        
        function selected = get_local_selected(this)
            selected = this.selected;
        end
        
        function marker = get_local_selected_marker(this)
            marker = this.markers{this.selected(1), this.selected(2)};
        end
        
        function coords = get_marked_coords(this)
            coords = {};
            for i = 1:size(this.markers, 1)
                for j = 1:size(this.markers, 2)
                    if this.has_enabled_marker([i, j])
                        coords{length(coords) + 1} = [i, j];
                    end
                end
            end
        end
        
        function selected = unselect_local_selected(this)
            selected = this.selected;
            if ~any(isnan(this.selected))
                if this.has_enabled_marker(this.selected)
                    this.unselect(this.selected);
                end
            end
            % else % no-op
        end
        
        function selected = toggle_local_selected(this, is_enabled)
            selected = this.selected;
            if ~any(isnan(selected))
%                 if this.has_enabled_marker(selected) ...
%                         && ~is_enabled % sanity check -- should always be toggling to disable
%                     this.unmark(selected);
%                 end
                if is_enabled
                    this.markers{selected(1), selected(2)} = [];
                else
                    this.markers{selected(1), selected(2)} = struct(...
                        'centroid', [],...
                        'marker', [],...
                        'enabled', false...
                    );
                end
            end
        end
        
        function change_color(this, new_color)
            marked_coords = this.get_marked_coords();
            for i = 1:length(marked_coords)
                % view manip
                coord = marked_coords{i};
                set(this.markers{coord(1), coord(2)}.marker,...
                    { 'FaceColor', 'EdgeColor' }, ...
                    { new_color, new_color }...
                );
            end
            % lazily change the color to the new one
            this.color = new_color; % model manip
            this.select(this.selected);
        end
        
        % [OBS] Purely view manipulations: do not talk to model
        % this.markers is the model for the selected markers, so
        % manipulating the this.markers modifies the model necessarily.
        % This is sort of a model class.
        function mark(this, centroid, C, enabled)
            if this.has_enabled_marker(C)
                delete(this.markers{C(1), C(2)}.marker);
            end
            if ~(this.has_marker(C) && ~this.markers{C(1), C(2)}.enabled)
                [X, Y, Z] = sphere();
                X = X * this.MARKER_RAD + centroid(1);
                Y = Y * this.MARKER_RAD + centroid(2);
                Z = Z * this.MARKER_RAD + centroid(3);
                % use marker_rad directly -- figure should be scaled to 1mm
                % cubic vox at loading time
                pMarker = surf2patch(X, Y, Z);
                hMarker = patch('vertices', pMarker.vertices,...
                    'faces', pMarker.faces, 'facealpha',1.0,...
                    'facecolor',this.color,'facelighting','phong',...
                    'edgecolor',this.color, 'ButtonDownFcn', { @this.marker_button_down, C });
                centroid = double(centroid);
%                 hLabel = text(centroid(1), centroid(2), centroid(3), sprintf('(%d,%d)', C(1), C(2)));

                this.markers{C(1), C(2)} = ...
                    struct(...
                        'centroid', centroid,...
                        'marker', hMarker,...
                        'enabled', enabled...
                );
%                         'label', hLabel,...

    %             this.select(C); % don't select here: have the parent select
    %             during its logic

                % reposition linkages
                linkages = this.get_active_linkages(C);
                for i = 1:length(linkages(1, :))
                    if ~isempty(linkages{1, i})
                        % horizontal linkages
                        linkage_idx = linkages{1, i}.linkage;
                        target = linkages{1, i}.marker;
                        h_cylinder = this.cylinder_to_linkage(...
                            centroid, this.markers{target(1), target(2)}.centroid, 1.0);

                        if all(linkage_idx <= size(this.h_linkages)) && ~isempty(this.h_linkages{linkage_idx(1), linkage_idx(2)})
                            delete(this.h_linkages{linkage_idx(1), linkage_idx(2)});
                        end
                        this.h_linkages{linkage_idx(1), linkage_idx(2)} = h_cylinder;
                    else
                        break

                    end
                end
                for i = 1:length(linkages(2, :))
                    if ~isempty(linkages{2, i})
                        % vertical linkages
                        linkage_idx = linkages{2, i}.linkage;
                        target = linkages{2, i}.marker;
                        h_cylinder = this.cylinder_to_linkage(...
                            centroid, this.markers{target(1), target(2)}.centroid, 1.0);

                        if all(linkage_idx <= size(this.v_linkages)) && ~isempty(this.v_linkages{linkage_idx(1), linkage_idx(2)})
                            delete(this.v_linkages{linkage_idx(1), linkage_idx(2)});
                        end
                        this.v_linkages{linkage_idx(1), linkage_idx(2)} = h_cylinder;
                    else
                        break
                    end
                end
            end
        end
        function unmark(this, C)
            delete(this.markers{C(1), C(2)}.marker);
%             delete(this.markers{C(1), C(2)}.label);
            this.markers{C(1), C(2)} = [];

            % delete active linkages around this marker
            linkages = this.get_active_linkages(C);
            for i = 1:length(linkages(1, :))
                % horizontal linkages
                if ~isempty(linkages{1, i})
                    linkage_idx = linkages{1, i}.linkage;
                    delete(this.h_linkages{linkage_idx(1), linkage_idx(2)});
                    this.h_linkages{linkage_idx(1), linkage_idx(2)} = [];
                else
                    break
                end
            end
            for i = 1:length(linkages(2, :))
                % vertical linkages
                if ~isempty(linkages{2, i})
                    linkage_idx = linkages{2, i}.linkage;
                    delete(this.v_linkages{linkage_idx(1), linkage_idx(2)});
                    this.v_linkages{linkage_idx(1), linkage_idx(2)} = [];
                else
                    break
                end
            end
        end
        function unmark_all(this)
            dims = size(this.markers);
            for i = 1:dims(1)
                for j = 1:dims(2)
                    if this.has_enabled_marker([i, j])
                        delete(this.markers{i, j}.marker);
%                         delete(this.markers{i, j}.label);
                        this.markers{i, j} = [];
                    end
                    if all(size(this.h_linkages) >= [i, j]) && ~isempty(this.h_linkages{i, j})
                        delete(this.h_linkages{i, j});
                        this.h_linkages{i, j} = [];
                    end
                    if all(size(this.v_linkages) >= [i, j]) && ~isempty(this.v_linkages{i, j})
                        delete(this.v_linkages{i, j});
                        this.v_linkages{i, j} = [];
                    end
                end
            end
        end
        function select(this, C)
            assert(this.has_enabled_marker(C), 'Tried to select an invalid or deleted marker.');
            
            hsv_grid_color = rgb2hsv(this.color);
            inverse_grid_color = hsv2rgb([ mod(hsv_grid_color(1) + 0.5, 1.0), hsv_grid_color(2:3)]);
            set(this.markers{C(1), C(2)}.marker,...
                { 'FaceColor', 'EdgeColor' },...
                { inverse_grid_color, inverse_grid_color }...
            );
        end
        function unselect(this, C)
            % on the fence if this should be so strong as to assert marker
            % existence
            assert(this.has_enabled_marker(C), 'Grid::select', 'Tried to unselect an invalid or deleted marker.');
            
            set(this.markers{C(1), C(2)}.marker,...
                { 'FaceColor', 'EdgeColor' },...
                { this.color, this.color });
        end
        function unselect_all(this)
            dims = size(this.markers);
            for i = 1:dims(1)
                for j = 1:dims(2)
                    if this.has_enabled_marker(i, j)
                        set(this.markers{i, j}, ...
                            { 'FaceColor', 'EdgeColor' },...
                            { this.color, this.color });
                    end
                end
            end
        end
        function hide(this)
            dims = size(this.markers);
            for i = 1:dims(1)
                for j = 1:dims(2)
                    if this.has_enabled_marker(i, j)
                        set(this.markers{i, j}.marker, 'Visible', 'off');
                    end
                    if all(size(this.h_linkages) <= [i, j]) && ~isempty(this.h_linkages{i, j})
                        set(this.h_linkages{i, j}, 'Visible', 'off');
                    end
                    if all(size(this.v_linkages) <= [i, j]) && ~isempty(this.v_linkages{i, j})
                        set(this.v_linkages{i, j}, 'Visible', 'off');
                    end
                end
            end
        end
        function maybe = has_marker(this, C)
            maybe = all(C <= size(this.markers)) && ~isempty(this.markers{C(1), C(2)});
        end
        function maybe = has_enabled_marker(this, C)
            maybe = this.has_marker(C) && this.markers{C(1), C(2)}.enabled;
        end
    end
    
    methods(Access = protected)
        % <<Canonical>>
        function active = get_active_linkages(this, C)
            active = cell(2, 0);
            num_linkages = [ 0 0 ]; % h, v
            cardinals = [[ 1 0 ]; [ -1 0 ]; [ 0 1 ]; [ 0 -1 ]];
            for i = 1:length(cardinals)
                target = C + cardinals(i, :);
                if ~any(target < 1 | target > size(this.markers)) && ...
                   ~isempty(this.markers{target(1), target(2)})
                    linkage_idx = C - max(0, -cardinals(i, :));
                    if cardinals(i, 1) ~= 0
                        active{1, num_linkages(1) + 1}.linkage = linkage_idx;
                        active{1, num_linkages(1) + 1}.marker = target;
                        fprintf('H: %d %d\n', linkage_idx(1), linkage_idx(2));
                        num_linkages(1) = num_linkages(1) + 1;
                    else
                        active{2, num_linkages(2) + 1}.linkage = linkage_idx;
                        active{2, num_linkages(2) + 1}.marker = target;
                        fprintf('V: %d %d\n', linkage_idx(1), linkage_idx(2));
                        num_linkages(2) = num_linkages(2) + 1;
                    end
                end
            end
        end
        function marker_button_down(this, ~, ~, C)
            % hijack figure callback
            [~, hFigure] = gcbo;
            current_callback = get(hFigure, 'WindowButtonUpFcn');
            current_callback{length(current_callback) + 1} = C;
            set(hFigure, 'WindowButtonUpFcn', current_callback);
        end
    end
    
    methods(Access = protected, Static)
        function h_cylinder = cylinder_to_linkage(A, B, r)
            [X, Y, Z] = cylinder(r);
            centroid = (A + B) ./ 2;
            h_cylinder = patch(surf2patch(X + centroid(1), Y + centroid(2), (Z - 0.5) * norm(A - B) + centroid(3)));
            n = cross([ 0, 0, 1 ], A - B);
            rotate(h_cylinder, n/norm(n), acos(dot([ 0, 0, 1 ], A - B)/norm(A - B))/pi*180, centroid);
            drawnow;
        end
    end
end