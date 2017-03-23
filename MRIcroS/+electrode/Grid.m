classdef Grid
    properties(Access = public)
        name
        markers
        h_linkages
        v_linkages
        dims
        marker_rad = 100
    end
    properties(Access = protected)
        figure_controller
    end
    methods(Access = public)
        function obj = Grid(name, figure_controller, width, height)
            obj.name = name;
            obj.figure_controller = figure_controller;
            obj.markers = {}; % cell(width, height)
            obj.h_linkages = {}; % NaN(width-1, height)
            obj.v_linkages = {}; % NaN(width, height-1) % fenceposts!
            obj.dims = [ width, height ];
        end
        
        % Purely view manipulations: do not talk to model
        function mark(this, centroid, C, enabled)
            if this.has_marker(C)
                delete(this.markers{C(1), C(2)}.marker);
            end
            
            [X, Y, Z] = sphere(this.marker_rad);
            is_rotated = utils.Wrapper(false);
            pMarker = surf2patch(X + centroid(1), Y + centroid(2), Z + centroid(3));
            hMarker = patch('vertices', pMarker.vertices,...
                'faces', pMarker.faces, 'facealpha',1.0,...
                'facecolor','red','facelighting','phong',...
                'edgecolor','red', 'ButtonDownFcn', { @this.marker_button_down, is_rotated, C });
            
            this.markers{C(1), C(2)} = ...
                struct(...
                    'centroid', centroid,...
                    'marker', hMarker,...
                    'enabled', enabled...
            );
            this.select(C);
            
            % reposition linkages
            linkages = this.get_active_linkages(C);
            for i = 1:length(linkages(1, :))
                if ~isempty(linkages{1, i})
                    % horizontal linkages
                    linkage_idx = linkages{1, i}.linkage;
                    target = linkages{1, i}.marker;
                    h_cylinder = this.cylinder_to_linkage(...
                        centroid, this.markers{target(1), target(2)}.centroid, 1.0);
                    
                    if ~isnan(this.h_linkages{linkage_idx(1), linkage_idx(2)})
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
                    
                    if ~isnan(this.v_linkages{linkage_idx(1), linkage_idx(2)})
                        delete(this.v_linkages{linkage_idx(1), linkage_idx(2)});
                    end
                    this.v_linkages{linkage_idx(1), linkage_idx(2)} = h_cylinder;
                else
                    break
                end
            end
        end
        function unmark(this, C)
            delete(this.markers{C(1), C(2)}.marker);
            this.markers{C(1), C(2)} = [];

            % delete active linkages around this marker
            linkages = this.get_active_linkages(C);
            for i = 1:length(linkages(1, :))
                % horizontal linkages
                if ~isempty(linkages{1, i})
                    linkage_idx = linkages{1, i}.linkage;
                    delete(this.h_linkages{linkage_idx(1), linkage_idx(2)});
                    this.h_linkages{linkage_idx(1), linkage_idx(2)} = NaN(1);
                else
                    break
                end
            end
            for i = 1:length(linkages(2, :))
                % vertical linkages
                if ~isempty(linkages{2, i})
                    linkage_idx = linkages{2, i}.linkage;
                    delete(this.v_linkages{linkage_idx(1), linkage_idx(2)});
                    this.v_linkages{linkage_idx(1), linkage_idx(2)} = NaN(1);
                else
                    break
                end
            end
        end
        function unmark_all(this)
            dims = size(this.markers);
            for i = 1:dims(1)
                for j = 1:dims(2)
                    if this.has_marker(i, j)
                        delete(this.markers{i, j});
                        this.markers{i, j} = [];
                    end
                    if all(size(this.h_linkages) <= [i, j]) && ~isempty(this.h_linkages{i, j})
                        delete(this.h_linkages{i, j});
                        this.h_linkages{i, j} = [];
                    end
                    if all(size(this.v_linkages) <= [i, j]) && ~isempty(this.v_linkages{i, j})
                        delete(this.v_linkages{i, j});
                        this.v_linkages{i, j} = [];
                    end
                end
            end
        end
        function select(this, C)
            assert(this.has_marker(C), 'Grid::select', 'Tried to select an invalid or deleted marker.');
            
            set(this.markers{C(1), C(2)}.marker, { 'FaceColor', 'EdgeColor' }, { 'cyan', 'cyan' });
        end
        function unselect(this, C)
            % on the fence if this should be so strong as to assert marker
            % existence
            assert(this.has_marker(C), 'Grid::select', 'Tried to unselect an invalid or deleted marker.');
            
            set(this.marker{C(1), C(2)}, { 'FaceColor', 'EdgeColor' }, { 'red', 'red' });
        end
        function unselect_all(this)
            dims = size(this.markers);
            for i = 1:dims(1)
                for j = 1:dims(2)
                    if this.has_marker(i, j)
                        set(this.markers{i, j}, ...
                            { 'FaceColor', 'EdgeColor' }, { 'red', 'red' });
                    end
                end
            end
        end
        function hide(this)
            dims = size(this.markers);
            for i = 1:dims(1)
                for j = 1:dims(2)
                    if this.has_marker(i, j)
                        set(this.markers{i, j}, 'Visible', 'off');
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
    end
    
    methods(Access = protected)
        function maybe = has_marker(this, C)
            maybe = all(C <= size(this.markers)) && ~isempty(this.markers{C(1), C(2)});
        end
        % <<Canonical>>
        function active = get_active_linkages(this, C)
            active = cell(2, 0);
            num_linkages = [ 0 0 ]; % h, v
            cardinals = [[ 1 0 ]; [ -1 0 ]; [ 0 1 ]; [ 0 -1 ]];
            for i = 1:length(cardinals)
                target = C + cardinals(i, :);
                if ~any(target < 1 | target > size(this.markers)) && ...
                   ~isempty(this.markers{target(1), target(2)})
                    linkage_idx = C - poslin(-cardinals(i, :));
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
        function marker_button_down(this, ~, ~, is_rotated, C)
            [az, el] = view(v.hAxes);
            p_0 = get(groot, 'PointerLocation');
            fig = this.figure_controller.get_hFigure();
            set(fig.get_hFigure(), 'WindowButtonMotionFcn', ...
                {@fig.rotate, is_rotated, p_0, [az, el]});
            set(hFigure, 'WindowButtonUpFcn', { @this.marker_button_up, is_rotated, C });
        end
        function marker_button_up(this, ~, ~, is_rotated, C)
            hFigure = this.grid_controller.get_figure_controller().get_hFigure();
            set(hFigure, 'WindowButtonMotionFcn', '');
            set(hFigure, 'WindowButtonUpFcn', '');
            if ~is_rotated.get()
                this.grid_controller.select(C);
            end
            is_rotated.set(false);
        end
    end
    
    methods(Access = protected, Static)
        function h_cylinder = cylinder_to_linkage(A, B, r)
            [X, Y, Z] = cylinder(r);
            centroid = (A + B) ./ 2;
            h_cylinder = patch(surf2patch(X + centroid(1), Y + centroid(2), (Z - 0.5) * norm(A - B) + centroid(3)));
            rot = vrrotvec([ 0, 0, 1 ], A - B);
            rotate(h_cylinder, rot(1:3), rot(4)/pi*180, centroid);
            drawnow;
        end
    end
end