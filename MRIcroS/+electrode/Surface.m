classdef Surface < handle
    properties
        prefs
        vertices
        faces
        vertexColors
        colorMap
        colorMin
        vert_adj_list
        E1
        E2
        
        alph = 1.0
        clr = [ 154, 169, 181 ] ./ 255
        
        % unconstructed %
        P
    end
    properties(Access = protected, Constant)
        POINT_IN_FACE_TOL = 1E-4
        POINT_IN_TRI_TOL = 1E-5
    end
    
    methods(Access = public)
        function obj = Surface(prefs, vertices, faces, vertexColors, colorMap, colorMin, vert_adj_list, E1, E2)
            obj.prefs = prefs;
            obj.vertices = vertices;
            obj.faces = faces;
            obj.vertexColors = vertexColors;
            obj.colorMap = colorMap;
            obj.colorMin = colorMin;
            obj.vert_adj_list = vert_adj_list;
            obj.E1 = E1;
            obj.E2 = E2;
        end
        function redraw(this, hAxes)
            % Copyright (c) 2015, Leonardo Bonilha, John Delgaizo and Chris Rorden
            % All rights reserved.
            % BSD License: https://www.mathworks.com/matlabcentral/fileexchange/56788-mricros
            % With modifications licensed under license found at:
            % [project_root]/LICENSE.txt
            axes(hAxes); % prevent against stupid gca-bound functions
            if ( this.prefs.backFaceLighting == 1)
                bf = 'reverselit';
            else
                bf = 'unlit'; % 'reverselit';
            end
    
            if ( this.prefs.showEdges(1) == 1)
                ec = this.prefs.edgeColors(1,1:3);
                ea = this.prefs.edgeColors(1,4);
            else
                ec = 'none';
                ea = this.prefs.colors(1, 4);
            end
            if size(this.vertices, 1) == size(this.vertexColors, 1)
                if size(this.vertexColors,2) == 3 %if vertexColors has 3 components Red/Green/Blue
                    this.P = patch(hAxes, 'vertices', this.vertices,...
                    'faces', this.faces, 'facealpha',this.alph,...
                    'FaceVertexCData', this.vertexColors,...
                    'facecolor','interp','facelighting','phong',...
                    'edgecolor',ec,'edgealpha', ea, ...
                    'BackFaceLighting',bf,...
                    'ButtonDownFcn', @this.patch_hit);
                else %color is scalar
                    %magnitudes at -1 beleived to be surface color
                    projectedIndices = this.vertexColors > -1;
                    clrs = zeros(length(this.vertexColors), 3);
                    clrs(projectedIndices,:) = utils.magnitudesToColors(this.vertexColors(projectedIndices), this.colorMap, this.colorMin);
                    clrs(~projectedIndices, :) = repmat(this.clr,[sum(~projectedIndices) 1]);
                    this.P = patch(hAxes, 'vertices', this.vertices,...
                        'faces', this.faces, 'facealpha',this.alph,...
                        'FaceVertexCData',clrs,...
                        'facecolor','interp','facelighting','phong',...
                        'edgecolor',ec,'edgealpha', ea, ...
                        'BackFaceLighting',bf,...
                        'ButtonDownFcn', @this.patch_hit);
                end
            else 
                this.P = patch(hAxes, 'vertices', this.vertices,...
                    'faces', this.faces, 'facealpha',this.alph,...
                    'facecolor',this.clr,'facelighting','phong',...
                    'edgecolor',ec,'edgealpha', ea, ...
                    'BackFaceLighting',bf,...
                    'ButtonDownFcn', @this.patch_hit...
                );
            end
            set(hAxes,'DataAspectRatio',[1 1 1])
            axis vis3d off; %tight
            % h = rotate3d;
            rotate3d off;
            
            if ~isempty(this.prefs.camLight)
                delete(this.prefs.camLight);
            end
            this.prefs.camLight = camlight( 0, 90 );
            material(this.prefs.materialKaKdKsn);
        end
        function centroid = marker_by_point(this, P)
            % [point-in-face]
            % Following point-in-face algorithm courtesy of Sandor Toth, (c) 2017 (MIT)
            % https://www.mathworks.com/matlabcentral/fileexchange/61078-callback-function-for-selecting-triangular-faces-of-patch-objects
%                 E1 = this.vertices(this.faces(:,2),:)-this.vertices(this.faces(:,1),:);
%                 E2 = this.vertices(this.faces(:,3),:)-this.vertices(this.faces(:,1),:);
            D = bsxfun(@minus,P,this.vertices(this.faces(:,1),:));
            det = dot(cross(D, this.E1, 2), this.E2, 2);
            face_idx = find(abs(det)<this.POINT_IN_FACE_TOL);
            % [/point-in-face]
            for j = 1:length(face_idx)
                face_vertices = this.vertices(this.faces(face_idx(j), :), :);
                patch('Faces', [1 2 3], 'Vertices', face_vertices, 'FaceColor', 'red', 'EdgeColor', 'red');
                Q = bsxfun(@minus, P, face_vertices);
                barycentric = cross(Q, face_vertices - circshift(face_vertices, 1, 1), 2);
                barycentric_norms = sqrt(sum(barycentric.^2, 2));
                face_area = norm(cross(this.E1(face_idx(j), :), this.E2(face_idx(j), :), 2));
                if(sum(barycentric_norms) / face_area <= 1 + this.POINT_IN_TRI_TOL)
                    F = this.contiguous(...
                        face_idx(j), containers.Map(... % only take first hit
                            'KeyType', 'uint32', 'ValueType', 'uint32')...
                    );
                    V_idx = this.faces(cell2mat(F.keys()));
                    V_idx = unique(V_idx(:)); % unique vertices
                    V = this.vertices(V_idx, :);
                    
                    centroid = mean(V, 1);
                    radius = 0;
                    for k = 1:length(V)
                        dist = norm(V(k, :) - centroid);
                        if(dist > radius)
                            radius = dist;
                        end
                    end
                    return
                end
            end
        end
        function visited = contiguous(this, face_idx, visited)
            face = this.faces(face_idx,:);
            num_vertices_per_face = size(face, 2);
            for i = 1:num_vertices_per_face
                face_adjs = this.vert_adj_list{face(i)};
                num_adjs = size(face_adjs, 2);
                for j = 1:num_adjs
                    if face_adjs{ j } ~= face_idx && ~visited.isKey(face_adjs{ j })
                        visited(face_adjs{ j }) = 1;
                        this.contiguous(face_adjs{ j }, visited);
                    end
                end
            end
        end
    end
    methods(Access = protected, Static)
        function patch_hit(~, ev)
             [ src, hFigure ] = gcbo;
             current_callback = get(hFigure, 'WindowButtonUpFcn');
             current_callback{length(current_callback) + 1} = ev;
             set(hFigure, 'WindowButtonUpFcn', current_callback);
        end
    end
end