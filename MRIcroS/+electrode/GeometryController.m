classdef GeometryController < handle
    %electrode.GeometryController Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Access = protected)
        grids = {}
        v
    end
    properties(Access = protected, Constant)
        ROTATE_SENSITIVITY = 0.7
        POINT_IN_FACE_TOL = 1E-4
        POINT_IN_TRI_TOL = 1E-5
    end
    
    methods(Access = public)
        function obj = GeometryController(v)
            obj.v = v; % shmeh...
        end
        function [H, V] = get_linkages(varargin)
            [idx, ~] = this.get_current_node();
            H = this.grids{idx}.h_linkages;
            V = this.grids{idx}.v_linkages;
        end
        function add_grid(this, name, width, height)
            if ~isempty(this.grids)
                [idx, ~] = this.get_current_node();
                grid_size = size(this.grids{idx}.markers);
                
                % hide the current grid
                for i = 1:grid_size(1)
                    for j = 1:grid_size(2)
                        if ~isnan(this.grids{idx}.markers{i, j})
                            set(this.grids{idx}.markers{i, j}, 'Visible', 'off');
                        end
                        if i < grid_size && ~isnan(this.grids{idx}.h_linkages(i, j))
                            set(this.grids{idx}.h_linkages{i, j}, 'Visible', 'off');
                        end
                        if j < grid_size && ~isnan(this.grids{idx}.v_linkages(i, j))
                            set(this.grids{idx}.v_linkages{i, j}, 'Visible', 'off');
                        end
                    end
                end
            end
            this.grids{length(this.grids) + 1} = electrode.Grid(name, width, height);
            this.v.h_grid_dropdown.String = [ this.v.h_grid_dropdown.String, name ];
            this.v.h_grid_name.String = name;
            this.v.h_edit_grid_dimensions_x.String = width;
            this.v.h_edit_grid_dimensions_y.String = height;
            this.v.h_electrode_x.String = 1:width;
            this.v.h_electrode_y.String = 1:height;
        end
    end
    methods(Access = protected)
        function add_marker(this, marker, centroid, enabled)
            [idx, C] = this.get_current_node();
            if ~isempty(this.grids{idx}.markers{C(1), C(2)})
                delete(this.grids{idx}.markers{C(1), C(2)});
            end
            this.grids{idx}.markers{C(1), C(2)} = ...
                struct(...
                    'centroid', centroid,...
                    'marker', marker,...
                    'enabled', enabled,...
                    'color', this.next_color()...
            );
            cardinals = [[ 1 0 ]; [ -1 0 ]; [ 0 1 ]; [ 0 -1 ]];
            for i = 1:length(cardinals)
                target = C + cardinals(i, :);
                if ~any(target < 1 | target > size(this.grids{idx}.markers)) && ...
                   ~isempty(this.grids{idx}.markers{target(1), target(2)})
                    h_cylinder = this.cylinder_to_linkage(...
                        centroid, this.grids{idx}.markers{target(1), target(2)}.centroid, 1.0);
                    linkage_idx = C - poslin(-cardinals(i));
                    if cardinals(i, 1) ~= 0
                        this.grids{idx}.h_linkages(linkage_idx(1), linkage_idx(2)) = h_cylinder;
                    else
                        this.grids{idx}.v_linkages(linkage_idx(1), linkage_idx(2)) = h_cylinder;
                    end
                end
            end
        end
        function [idx, coord] = get_current_node(this)
            idx = this.v.h_grid_dropdown.Value;
            X = str2num(this.v.h_electrode_x.String(this.v.h_electrode_x.Value,:));
            Y = str2num(this.v.h_electrode_y.String(this.v.h_electrode_y.Value,:));
            coord = [X, Y];
        end
        function color = next_color(varargin)
            color = [ 0.8500    0.3250    0.0980 ]; % burnt orange
        end
    end
    methods(Access = public, Static)
        function button_down(src, ev, is_rotated)
            gui.perspectiveChange_Callback(src, ev);
            v = guidata(src);
            [az, el] = view(v.hAxes);
            p_0 = get(groot, 'PointerLocation');
            set(v.hMainFigure, 'WindowButtonMotionFcn', {@electrode.GeometryController.rotate, is_rotated, p_0, [az, el]});
            set(v.hMainFigure, 'WindowButtonUpFcn', { @electrode.GeometryController.button_up, is_rotated });
        end
        function patch_hit(src, ev)
             v = guidata(src);
             current_callback = get(v.hMainFigure, 'WindowButtonUpFcn');
             current_callback{length(current_callback) + 1} = ev;
             set(v.hMainFigure, 'WindowButtonUpFcn', current_callback);
        end
        function button_up(src, ev, is_rotated, varargin)
            v = guidata(src);
            if ~is_rotated.get() && ~isempty(varargin) && isa(varargin{1}, 'matlab.graphics.eventdata.Hit')
                hit = varargin{1};
                [X, Y, Z, centroid] = electrode.GeometryController.marker_by_point(...
                    src, hit.IntersectionPoint);
                if ~isnan(X)
                    hMarker = surf2patch(X, Y, Z);
                    % disp('FACE HIT');
                    v.controller.add_marker(hMarker, centroid, true);
                    v.markers(utils.fieldIndex(v, 'markers')) = hMarker;
                    guidata(v.hMainFigure, v);
                    drawing.redrawSurface(v);
                end % no logic for no-op yet
            else
                gui.perspectiveChange_Callback(src, ev);
            end
            is_rotated.set(false);
            set(v.hMainFigure, 'WindowButtonMotionFcn', '');
            set(v.hMainFigure, 'WindowButtonUpFcn', '');
        end
    end
    methods(Access = protected, Static)
        function rotate(src, ~, is_rotated, p_0, view_0)
            is_rotated.set(true);
            v = guidata(src);
            p = get(groot, 'PointerLocation');
%             fprintf('(%.3f,%.3f)\t(%.3f,%.3f)\n', p_0, p);
            cam_location = (p_0 - p) ./ ...
                ones(size(p_0)) .* electrode.GeometryController.ROTATE_SENSITIVITY +...
                view_0;
            cam_location = [ cam_location(1), max(-90, min(90, cam_location(2))) ];
            view(v.hAxes, cam_location);
        end
        function h_cylinder = cylinder_to_linkage(A, B, r)
            [X, Y, Z] = cylinder(r);
            centroid = (A + B) ./ 2;
            h_cylinder = patch(surf2patch(X + centroid(1), Y + centroid(2), (Z - 0.5) * norm(A - B) + centroid(3)));
            rot = vrrotvec([ 0, 0, 1 ], A - B);
            rotate(h_cylinder, rot(1:3), rot(4), centroid);
            drawnow;
        end
        function [X, Y, Z, centroid] = marker_by_point(src, P)
            v = guidata(src);
            S = v.surface;
            X = NaN; Y = NaN; Z = NaN;
            for i = 1:length(S)
                % [point-in-face]
                % Following point-in-face algorithm courtesy of Sandor Toth, (c) 2017 (MIT)
                % https://www.mathworks.com/matlabcentral/fileexchange/61078-callback-function-for-selecting-triangular-faces-of-patch-objects
%                 E1 = S(i).vertices(S(i).faces(:,2),:)-S(i).vertices(S(i).faces(:,1),:);
%                 E2 = S(i).vertices(S(i).faces(:,3),:)-S(i).vertices(S(i).faces(:,1),:);
                E1 = S(i).E1;
                E2 = S(i).E2;
                D = bsxfun(@minus,P,S(i).vertices(S(i).faces(:,1),:));
                det = dot(cross(D, E1, 2), E2, 2);
                face_idx = find(abs(det)<electrode.GeometryController.POINT_IN_FACE_TOL);
                % [/point-in-face]
                for j = 1:length(face_idx)
                    face_vertices = S(i).vertices(S(i).faces(face_idx(j), :), :);
                    patch('Faces', [1 2 3], 'Vertices', face_vertices, 'FaceColor', 'red', 'EdgeColor', 'red');
                    Q = bsxfun(@minus, P, face_vertices);
                    barycentric = cross(Q, face_vertices - circshift(face_vertices, 1, 1), 2);
                    barycentric_norms = sqrt(sum(barycentric.^2, 2));
                    face_area = norm(cross(E1(face_idx(j), :), E2(face_idx(j), :), 2));
                    if(sum(barycentric_norms) / face_area <= 1 + electrode.GeometryController.POINT_IN_TRI_TOL)
                       F = electrode.GeometryController.contiguous(...
                            S, face_idx(j), containers.Map(... % only take first hit
                                'KeyType', 'uint32', 'ValueType', 'uint32')...
                        );
                        V_idx = S(i).faces(cell2mat(F.keys()));
                        V_idx = unique(V_idx(:)); % unique vertices
                        V = S(i).vertices(V_idx, :);
                        centroid = mean(V, 1);
                        radius = 0;
                        for k = 1:length(V)
                            dist = norm(V(k, :) - centroid);
                            if(dist > radius)
                                radius = dist;
                            end
                        end
                        [X, Y, Z] = sphere();
                        X = X .* radius + centroid(1);
                        Y = Y .* radius + centroid(2);
                        Z = Z .* radius + centroid(3); 
                        return
                    end
                end
            end
        end
        function visited = contiguous(S, face_idx, visited)
            face = S.faces(face_idx,:);
            num_vertices_per_face = size(face, 2);
            for i = 1:num_vertices_per_face
                face_adjs = S.vert_adj_list{face(i)};
                num_adjs = size(face_adjs, 2);
                for j = 1:num_adjs
                    if face_adjs{ j } ~= face_idx && ~visited.isKey(face_adjs{ j })
                        visited(face_adjs{ j }) = 1;
                        electrode.GeometryController.contiguous(...
                            S, face_adjs{ j }, visited);
                    end
                end
            end
        end
    end
end