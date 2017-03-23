classdef GeometryController < handle
    %electrode.GeometryController
    %   Portions of this code 
    
    properties(Access = protected)
        grids = {}
        selected = NaN(1, 2)
        surf
        vol
    end
    properties(Access = protected, Constant)
        ROTATE_SENSITIVITY = 0.7
        POINT_IN_FACE_TOL = 1E-4
        POINT_IN_TRI_TOL = 1E-5
        GRID_DEFAULT = [ 8, 8 ]
    end
    
    methods(Access = public)
        function obj = GeometryController(filename, varargin)
            % Copyright (c) 2015, Leonardo Bonilha, John Delgaizo and Chris Rorden
            % All rights reserved.
            % BSD License: https://www.mathworks.com/matlabcentral/fileexchange/56788-mricros
            % With modifications licensed under license found at:
            % [project_root]/LICENSE.txt
            
            % --- add an image as a new layer on top of previously opened images
            %  inputs:
            %   filename
            %       * can be .nii, .nii.gz, .vtk, .gii, .pial, .nv, .stl
            %   reduce (optional)
            %       * applies to surfaces (pial/NV) and volumes (NiFTI)
            %       * must be between 0 and 1
            %       * default value of .25
            %   smooth (optional)
            %       * applies only to volumes (NiFTI)
            %       * convolution kernel size for gaussian smoothing
            %       * default value 1 (slight smoothing)
            %       * must be odd number
            %   thresh (optional)
            %       * applies only to volumes (NiFTI)
            %       * Inf for midrange, -Inf for Otsu
            %       * defaults to Inf (midrange)
            %   vertexColor (optional)
            %       * applies only to volumes (NiFTI)
            %       * 0=noVertexColors, 1=defaultVertexColors, 2=vertexColorsWithOptions
            %   defaults are specified if empty string ('') is input for value, or if
            %   not specified
            %
            %  No Optional Values have influence on meshes (VTK, GIfTI)
            %  thresh=Inf for midrange, thresh=-Inf for otsu
            %
            %GeometryController('cortex_5124.surf.gii'); %use defaults
            %Otsu's threshold, defaults for reduce and smooth
            %GeometryController('addLayer','attention.nii.gz','','',-Inf);
            %GeometryController('addLayer','attention.nii.gz',0.05,0,3); %threshold >3

            inputs = obj.parseInputParamsSub(varargin{:});
            reduce = inputs.reduce; 
            reduceMesh = inputs.reduceMesh;
            smooth = inputs.smooth;
            thresh = inputs.thresh; 
            vertexColor = inputs.vertexColor;

            [filename, isFound] = fileUtils.isFileFound(v, filename);
            if ~isFound
                fprintf('Unable to find "%s"\n',filename); 
                return; 
            end;
            if fileUtils.isTrk(filename);
                commands.addTrack(v,filename);
                return;
            end
            isBackground = v.vprefs.demoObjects;if isequal(filename,0), return; end;
            if exist(filename, 'file') == 0, fprintf('Unable to find %s\n',filename); return; end;
            
            % function addLayerSub(...)
%             if (isBackground) 
%                 v = drawing.removeDemoObjects(v);
%             end;
%             layer = utils.fieldIndex(v, 'surface');
            colorMap = utils.colorTables(1);
            colorMin = 0;
            if fileUtils.isMesh(filename)
                [faces, vertices, vertexColors, colorMap, colorMin] = fileUtils.readMesh(filename, reduceMesh);
                timer = tic;
                v.surface(layer).vert_adj_list = utils.vert_adj_list(v.surface(layer).faces, v.surface(layer).vertices);
                elapsed = toc(timer)
                [ v.surface(layer).E1, v.surface(layer).E2 ] = utils.tri_planes(v.surface(layer).faces, v.surface(layer).vertices);
                toc(timer) - elapsed
            else    
                %v.surface(layer).vertexColors = [];
                [faces, vertices, vertexColors, obj.vol] = fileUtils.readVox (filename, reduce, smooth, thresh, vertexColor);
                %if vertexColor
                %    guidata(v.hMainFigure,v);%store settings
                %    commands.projectVolume(v, layer, filename) ;
                %    v = guidata(v.hMainFigure);%retrieve latest settings
                %end
            end
            obj.surf = Surface(faces, vertices, vertexColors, colorMap, colorMin);
            
            %display results
            obj.redrawSurface(v);
            view( v.hAxes, v.vprefs.az,  v.vprefs.el);
        end
        function [H, V] = get_linkages(varargin)
            [idx, ~, ~] = this.poll_inputs();
            H = this.grids{idx}.h_linkages;
            V = this.grids{idx}.v_linkages;
        end
        function add_grid(this, name, width, height)
            this.unselect_last_selected();
            if ~isempty(this.grids)
                [idx, ~, ~] = this.poll_inputs();
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
            this.v_w.v.h_grid_dropdown.String = [ this.v_w.v.h_grid_dropdown.String, name ];
            this.v_w.v.h_grid_name.String = name;
            this.v_w.v.h_edit_grid_dimensions_x.String = width;
            this.v_w.v.h_edit_grid_dimensions_y.String = height;
            this.v_w.v.h_electrode_x.String = 1:width;
            this.v_w.v.h_electrode_y.String = 1:height;
            
            set(this.v_w.v.ax_grid, 'xtick', 0:1/(width+1):1);
            set(this.v_w.v.ax_grid, 'ytick', 0:1/(height+1):1);
        end
        function update_grid(this)
            [idx, ~, dims] = this.poll_inputs();
            this.v_w.v.h_electrode_x.String = 1:dims(1);
            this.v_w.v.h_electrode_y.String = 1:dims(2);
            
            set(this.v_w.v.ax_grid, 'xtick', 0:1/(dims(1)+1):1);
            set(this.v_w.v.ax_grid, 'ytick', 0:1/(dims(2)+1):1);
            
            for i=1:size(this.grids{idx}.markers, 1)
                for j=1:size(this.grids{idx}.markers, 2)
                    if ~isempty(this.grids{idx}.markers{i, j})
                        set(this.grids{idx}.markers{i, j}.indicator, 'Position', ...
                            [ [ i-1, j-1 ] .* (dims + ones(size(dims))) .^ -1,  (dims + ones(size(dims))) .^ -1 ]);
                    end
                end
            end
        end
        function unmark_current(this)
            [idx, ~, ~] = this.poll_inputs();
            if ~any(isnan(this.selected)) % &&...
               % ~isempty()
                delete(this.grids{idx}.markers{this.selected(1), this.selected(2)}.marker);
                delete(this.grids{idx}.markers{this.selected(1), this.selected(2)}.indicator);
                this.grids{idx}.markers{this.selected(1), this.selected(2)} = [];
                
                % delete active linkages around this marker
                linkages = this.get_active_linkages();
                for i = 1:length(linkages(1, :))
                    % horizontal linkages
                    if ~isempty(linkages{1, i})
                        linkage_idx = linkages{1, i}.linkage;
                        delete(this.grids{idx}.h_linkages(linkage_idx(1), linkage_idx(2)));
                        this.grids{idx}.h_linkages(linkage_idx(1), linkage_idx(2)) = NaN(1);
                    else
                        break
                    end
                end
                for i = 1:length(linkages(2, :))
                    % vertical linkages
                    if ~isempty(linkages{2, i})
                        linkage_idx = linkages{2, i}.linkage;
                        delete(this.grids{idx}.v_linkages(linkage_idx(1), linkage_idx(2)));
                        this.grids{idx}.v_linkages(linkage_idx(1), linkage_idx(2)) = NaN(1);
                    else
                        break
                    end
                end
                
                this.selected = NaN(1, 2);
            end
            
            set(this.v_w.v.h_unmark_button, 'Visible', 'Off');
        end
        function select(this, coord)
            [idx, ~, dims] = this.poll_inputs();
            x = coord(1);
            y = coord(2);
            if 1 <= x && x <= dims(1) &&...
               1 <= y && y <= dims(2)
                this.unselect_last_selected();
                
                this.v_w.v.h_electrode_x.Value = x;
                this.v_w.v.h_electrode_y.Value = y;
                
                if ~isempty(this.grids{idx}.markers{x, y})
                    % marker exists at this coordinate
                    this.selected = coord;
                
                    set(this.grids{idx}.markers{x, y}.marker, ...
                        'facecolor', 'cyan');
                    set(this.grids{idx}.markers{x, y}.marker, ...
                        'edgecolor', 'cyan');
                    
                    set(this.grids{idx}.markers{x, y}.indicator, ...
                        'facecolor', 'cyan');
                    
                    set(this.v_w.v.h_unmark_button, 'Visible', 'On');
                end
            else
                set(this.v_w.v.h_unmark_button, 'Visible', 'Off');
            end
        end
    end
    methods(Access = protected)
        function unselect_last_selected(this)
            if ~any(isnan(this.selected))
                [idx, ~, ~] = this.poll_inputs();
                set(this.grids{idx}.markers{this.selected(1), this.selected(2)}.marker, ...
                    'facecolor', 'red');
                set(this.grids{idx}.markers{this.selected(1), this.selected(2)}.marker, ...
                    'edgecolor', 'red');
                
                set(this.grids{idx}.markers{this.selected(1), this.selected(2)}.indicator, ...
                    'facecolor', 'red');
                
                this.selected = NaN(1, 2);
            end
            % else % no-op
            
            set(this.v_w.v.h_unmark_button, 'Visible', 'Off');
        end
        function active = get_active_linkages(this)
            [idx, C, ~] = this.poll_inputs();
            active = cell(2, 0);
            num_linkages = [ 0 0 ]; % h, v
            cardinals = [[ 1 0 ]; [ -1 0 ]; [ 0 1 ]; [ 0 -1 ]];
            for i = 1:length(cardinals)
                target = C + cardinals(i, :);
                if ~any(target < 1 | target > size(this.grids{idx}.markers)) && ...
                   ~isempty(this.grids{idx}.markers{target(1), target(2)})
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
        function add_marker(this, marker, centroid, enabled)
            [idx, C, dims] = this.poll_inputs();
            if ~isempty(this.grids{idx}.markers{C(1), C(2)})
                delete(this.grids{idx}.markers{C(1), C(2)}.marker);
            end
            
            indicator = rectangle(this.v_w.get().ax_grid,...
                        'Position', [ (C - ones(size(C))) .* (dims + ones(size(dims))) .^ -1, (dims + ones(size(dims))) .^ -1 ], ...
                        'FaceColor', 'red');
            set(indicator, 'ButtonDownFcn', @(~, ~) this.select(C));
            
            this.grids{idx}.markers{C(1), C(2)} = ...
                struct(...
                    'centroid', centroid,...
                    'marker', marker,...
                    'indicator', indicator, ...
                    'enabled', enabled,...
                    'color', this.next_color()...
            );
            is_rotated = utils.Wrapper(false);
            set(marker, 'ButtonDownFcn', { @this.marker_button_down, is_rotated, C });
            this.select(C);
            
            % reposition linkages
            linkages = this.get_active_linkages();
            for i = 1:length(linkages(1, :))
                if ~isempty(linkages{1, i})
                    % horizontal linkages
                    linkage_idx = linkages{1, i}.linkage;
                    target = linkages{1, i}.marker;
                    h_cylinder = this.cylinder_to_linkage(...
                        centroid, this.grids{idx}.markers{target(1), target(2)}.centroid, 1.0);
                    
                    if ~isnan(this.grids{idx}.h_linkages(linkage_idx(1), linkage_idx(2)))
                        delete(this.grids{idx}.h_linkages(linkage_idx(1), linkage_idx(2)));
                    end
                    this.grids{idx}.h_linkages(linkage_idx(1), linkage_idx(2)) = h_cylinder;
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
                        centroid, this.grids{idx}.markers{target(1), target(2)}.centroid, 1.0);
                    
                    if ~isnan(this.grids{idx}.v_linkages(linkage_idx(1), linkage_idx(2)))
                        delete(this.grids{idx}.v_linkages(linkage_idx(1), linkage_idx(2)));
                    end
                    this.grids{idx}.v_linkages(linkage_idx(1), linkage_idx(2)) = h_cylinder;
                else
                    break
                end
            end
        end
        function [idx, coord, dims] = poll_inputs(this)
            idx = this.v_w.v.h_grid_dropdown.Value;
            X = str2num(this.v_w.v.h_electrode_x.String(this.v_w.v.h_electrode_x.Value,:));
            Y = str2num(this.v_w.v.h_electrode_y.String(this.v_w.v.h_electrode_y.Value,:));
            coord = [X, Y];
            W = str2num(this.v_w.v.h_edit_grid_dimensions_x.String);
            H = str2num(this.v_w.v.h_edit_grid_dimensions_y.String);
            dims = [W, H];
        end
        function color = next_color(varargin)
            color = [ 0.8500    0.3250    0.0980 ]; % burnt orange
        end
    end
    methods(Access = protected, Static)
        function inputParams = parseInputParamsSub(args)
            % Copyright (c) 2015, Leonardo Bonilha, John Delgaizo and Chris Rorden
            % All rights reserved.
            % BSD License: https://www.mathworks.com/matlabcentral/fileexchange/56788-mricros
            p = inputParser;
            d.reduce = .2; d.smooth = 1; d.thresh = Inf; d.vertexColor = 0;

            p.addOptional('reduce', d.reduce, ...
                @(x) validateattributes(x, {'numeric'}, {'<=',1,'>=',0}));
            p.addOptional('smooth', d.smooth, ...
                @(x) validateattributes(x, {'numeric'}, {'integer', '>=',0})); %smooth 0=none, 1=little, 2=more...
            p.addOptional('thresh', d.thresh, ...
                @(x) validateattributes(x, {'numeric'}, {'real'}));
            p.addOptional('vertexColor', d.vertexColor, ...
                @(x) validateattributes(x, {'numeric'}, {'<=', 14, '>=', 0}));
            p = utils.stringSafeParse(p, args, fieldnames(d), d.reduce, d.smooth, d.thresh, ...
                d.vertexColor);
            inputParams = p.Results;
            inputParams.reduceMesh = 1.0;
            if ~max(strcmp(p.UsingDefaults,'reduce'))
                inputParams.reduceMesh = inputParams.reduce;
            end
        end
        function marker_button_down(src, ev, is_rotated, C)
            gui.perspectiveChange_Callback(src, ev);
            v = guidata(src);
            [az, el] = view(v.hAxes);
            p_0 = get(groot, 'PointerLocation');
            set(v.hMainFigure, 'WindowButtonMotionFcn', {@electrode.GeometryController.rotate, is_rotated, p_0, [az, el]});
            set(v.hMainFigure, 'WindowButtonUpFcn', { @electrode.GeometryController.marker_button_up, is_rotated, C });
        end
        function marker_button_up(src, ev, is_rotated, C)
            v = guidata(gcbf);
            set(v.hMainFigure, 'WindowButtonMotionFcn', '');
            set(v.hMainFigure, 'WindowButtonUpFcn', '');
            if ~is_rotated.get()
                v.controller.select(C);
            else
                gui.perspectiveChange_Callback(src, ev);
            end
            is_rotated.set(false);
        end
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
            rotate(h_cylinder, rot(1:3), rot(4)/pi*180, centroid);
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