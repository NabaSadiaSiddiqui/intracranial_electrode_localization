classdef FigureController < handle
    properties(Access = protected)
        hFigure
        hAxes
        gui_controller
        geometry_controller
        camLight
    end
    properties(Access = protected, Constant)
        ROTATE_SENSITIVITY = 0.7
    end
    
    methods(Access = public)
        function obj = FigureController(gui_controller, hFigure, hAxes, filename, varargin)
            % Copyright (c) 2015, Leonardo Bonilha, John Delgaizo and Chris Rorden
            % All rights reserved.
            % BSD License: https://www.mathworks.com/matlabcentral/fileexchange/56788-mricros
            % With modifications licensed under license found at:
            % [project_root]/LICENSE.txt
            axes(hAxes);
            
            obj.hFigure = hFigure;
            obj.hAxes = hAxes;
            
            obj.camLight = camlight(0, 90);
            
            obj.gui_controller = gui_controller;
            obj.geometry_controller = obj.file_parse_sub(filename, varargin{:});
            
            is_rotated = utils.Wrapper(false);
            set( hFigure, 'WindowButtonDownFcn', { @obj.button_down, is_rotated });
        end
        function hFigure = get_hFigure(this)
            hFigure = this.hFigure;
        end
        function v = view(this, varargin)
            v = view(this.hAxes, varargin{:});
        end
        function redraw(this)
            this.geometry_controller.redraw(this.hAxes);
        end
        function set_volume_trace_radius(this, radius)
            this.geometry_controller.set_volume_trace_radius(radius)
        end
    end
    
    methods(Access = protected)
        function button_down(this, src, ev, is_rotated)
            % bind this handler to figure plz
            % k
            [az, el] = view(this.hAxes);
            this.perspectiveChange_Callback(src, ev);
            p_0 = get(groot, 'PointerLocation');
            set(this.hFigure, 'WindowButtonMotionFcn', {@this.rotate, is_rotated, p_0, [az, el]});
            set(this.hFigure, 'WindowButtonUpFcn', { @this.button_up, is_rotated });
        end
        function rotate(this, ~, ~, is_rotated, p_0, view_0)
            is_rotated.set(true);
            p = get(groot, 'PointerLocation');
%             fprintf('(%.3f,%.3f)\t(%.3f,%.3f)\n', p_0, p);
            cam_location = (p_0 - p) ./ ...
                ones(size(p_0)) .* this.ROTATE_SENSITIVITY +...
                view_0;
            cam_location = [ cam_location(1), max(-90, min(90, cam_location(2))) ];
            view(this.hAxes, cam_location);
        end
        function button_up(this, src, ev, is_rotated, varargin)
            set(this.hFigure, 'WindowButtonMotionFcn', '');
            set(this.hFigure, 'WindowButtonUpFcn', '');
            if ~is_rotated.get() && ~isempty(varargin)
                if isa(varargin{1}, 'matlab.graphics.eventdata.Hit')
                    % mark electrode
                    hit = varargin{1};
                    centroid = this.geometry_controller.marker_by_point(hit.IntersectionPoint);
                    if ~isempty(centroid)
                        % disp('FACE HIT');
                        this.gui_controller.mark(centroid, true); % modify Grid model
                    end % no logic for no-op yet
                elseif ismatrix(varargin{1}) && all(size(varargin{1}) == [1, 2])
                    % select existing marker
                    this.gui_controller.select(varargin{1});
                end
            else
                this.perspectiveChange_Callback(src, ev);
            end
            is_rotated.set(false);
        end
        function perspectiveChange_Callback(this, ~, ~)
            % Copyright (c) 2015, Leonardo Bonilha, John Delgaizo and Chris Rorden
            % All rights reserved.
            % BSD License: https://www.mathworks.com/matlabcentral/fileexchange/56788-mricros
            % With modifications licensed under license found at:
            % [project_root]/LICENSE.txt
            camlight(this.camLight, 0, 40);
        end
    end
    methods(Access = protected)
        function geometry_controller = file_parse_sub(this, filename, varargin)
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
            
            inputs = electrode.FigureController.parseInputParamsSub(varargin);
            reduce = inputs.reduce; 
            reduceMesh = inputs.reduceMesh;
            smooth = inputs.smooth;
            thresh = inputs.thresh; 
            vertexColor = inputs.vertexColor;

            [filename, isFound] = fileUtils.isFileFound(filename);
            if ~isFound
                fprintf('Unable to find "%s"\n',filename); 
                return; 
            end;
            if fileUtils.isTrk(filename);
                commands.addTrack(v,filename);
                return;
            end
            if isequal(filename,0), return; end;
            if exist(filename, 'file') == 0, fprintf('Unable to find %s\n',filename); return; end;
            
            % function addLayerSub(...)
%             if (isBackground) 
%                 v = drawing.removeDemoObjects(v);
%             end;
%             layer = utils.fieldIndex(v, 'surface');
            colorMap = utils.colorTables(1);
            colorMin = 0;
            vol_img = []; hdr = struct();
            if fileUtils.isMesh(filename)
                [faces, vertices, vertexColors, colorMap, colorMin] = fileUtils.readMesh(filename, reduceMesh);
            else    
                %v.surface(layer).vertexColors = [];
                [faces, vertices, vertexColors, vol_img, hdr] = fileUtils.readVox (filename, reduce, smooth, thresh, vertexColor);
                %if vertexColor
                %    guidata(v.hMainFigure,v);%store settings
                %    commands.projectVolume(v, layer, filename) ;
                %    v = guidata(v.hMainFigure);%retrieve latest settings
                %end
            end
            
            fprintf('Generating adjacency list of thresholded surface...\n');
            timer = tic;
            vert_adj_list = utils.vert_adj_list(faces, vertices);
            [ E1, E2 ] = utils.tri_planes(faces, vertices);
            fprintf('Adjacency list generated in %.3f seconds.\n', toc(timer));
            
            surf = electrode.Surface(this.gui_controller.get_prefs(), vertices, faces, vertexColors, colorMap, colorMin, vert_adj_list, E1, E2);
            geometry_controller = electrode.GeometryController(surf, vol_img, hdr);
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
    end
end