function redrawSurface(v)
% --- creates renderings
v = guidata(v.hMainFigure);
drawing.removeSurfaces(v);
%delete(allchild(v.hAxes));%
set(v.hMainFigure,'CurrentAxes',v.hAxes)
set(0, 'CurrentFigure', v.hMainFigure);  %# for figures
if ( v.vprefs.backFaceLighting == 1)
    bf = 'reverselit';
else
    bf = 'unlit'; % 'reverselit';
end
surfaceCount = 0;
if(isfield(v, 'surface'))
    surfaceCount = length(v.surface);
end
v.surfacePatches = zeros(surfaceCount, 1);
for i=1:surfaceCount
    [clr, alph] = drawing.utils.currentLayerRGBA(i, v.vprefs.colors);
    
    if ( v.vprefs.showEdges(i) == 1)
        ec = v.vprefs.edgeColors(i,1:3);
        ea = v.vprefs.edgeColors(i,4);
    else
        ec = 'none';
        ea = alph;
    end;
    %fprintf('%d %d %d\n',i, size(v.surface(i).vertexColors,1), size(v.surface(i).vertexColors,2));
    
    if size(v.surface(i).vertices,1) == size(v.surface(i).vertexColors,1) % - if provided edge color information
        if size(v.surface(i).vertexColors,2) == 3 %if vertexColors has 3 components Red/Green/Blue
            v.surfacePatches(i) = patch('vertices', v.surface(i).vertices,...
            'faces', v.surface(i).faces, 'facealpha',alph,...
            'FaceVertexCData',v.surface(i).vertexColors,...
            'facecolor','interp','facelighting','phong',...
            'edgecolor',ec,'edgealpha', ea, ...
            'BackFaceLighting',bf,...
            'ButtonDownFcn', @electrode.GeometryController.patch_hit);
        else %color is scalar
            %magnitudes at -1 beleived to be surface color
            projectedIndices = v.surface(i).vertexColors > -1;
            clrs = zeros(length(v.surface(i).vertexColors), 3);
            clrs(projectedIndices,:) = utils.magnitudesToColors(v.surface(i).vertexColors(projectedIndices), v.surface(i).colorMap, v.surface(i).colorMin);
            clrs(~projectedIndices, :) = repmat(clr,[sum(~projectedIndices) 1]);
            v.surfacePatches(i) = patch('vertices', v.surface(i).vertices,...
            'faces', v.surface(i).faces, 'facealpha',alph,...
            'FaceVertexCData',clrs,...
            'facecolor','interp','facelighting','phong',...
            'edgecolor',ec,'edgealpha', ea, ...
            'BackFaceLighting',bf,...
            'ButtonDownFcn', @electrode.GeometryController.patch_hit);
        end
    else 
        v.surfacePatches(i) = patch('vertices', v.surface(i).vertices,...
        'faces', v.surface(i).faces, 'facealpha',alph,...
        'facecolor',clr,'facelighting','phong',...
        'edgecolor',ec,'edgealpha', ea, ...
        'BackFaceLighting',bf,...
        'ButtonDownFcn', @electrode.GeometryController.patch_hit);
    end
end;

markerCount = 0;
if(isfield(v, 'markers'))
    markerCount = length(v.markers);
end
v.markerPatches = zeros(markerCount, 1);
for i = 1:markerCount
    v.markerPatches(i) = patch('vertices', v.markers(i).vertices,...
        'faces', v.markers(i).faces, 'facealpha',alph,...
        'facecolor',clr,'facelighting','phong',...
        'edgecolor',ec,'edgealpha', ea, ...
        'BackFaceLighting',bf);
end

set(gca,'DataAspectRatio',[1 1 1])
axis vis3d off; %tight
% h = rotate3d;
rotate3d off;
h = v.hMainFigure;

is_rotated = utils.Wrapper(false);
set( h, 'WindowButtonDownFcn', { @electrode.GeometryController.button_down, is_rotated }); %called when user changes perspective

%set( h, 'ActionPostCallback', @gui.perspectiveChange_Callback); %called when user changes perspective
% view( v.vprefs.az,  v.vprefs.el);
%v.vprefs.camLight = camlight( v.vprefs.azLight, v.vprefs.elLight);
if ~isempty(v.vprefs.camLight)
    delete(v.vprefs.camLight); % - delete previous lights!
end
%v.vprefs.camLight = camlight( v.vprefs.azLight, v.vprefs.elLight);
v.vprefs.camLight = camlight( 0, 90); %2015 consider changing to 0,10 6767
%v.vprefs.camLight = camlight('headlight');
%v.vprefs.lightangle= lightangle(0, 90);
material( v.vprefs.materialKaKdKsn);
guidata(v.hMainFigure,v);%store settings
%end redrawSurface()

