function [vFig] = makeGui()
% --- Declare and create all the user interface objects
checkVersionSub()
sz = [980 680]; % figure width, height in pixels
screensize = get(0,'ScreenSize');
margin = [ceil((screensize(3)-sz(1))/2) ceil((screensize(4)-sz(2))/2)];
v.hMainFigure = figure('MenuBar','none','Toolbar','none','HandleVisibility','on', ...
  'position',[margin(1), margin(2), sz(1), sz(2)], ...
    'Tag', mfilename,'Name', mfilename, 'NumberTitle','off', ...
 'Color', get(0, 'defaultuicontrolbackgroundcolor'));
set(v.hMainFigure,'Renderer','OpenGL')
v.hAxes = axes('Parent', v.hMainFigure,'HandleVisibility','on','Units', 'normalized','Position',[0.0 0.0 1 1]); %important: turn ON visibility

v.controller = electrode.GeometryController();

showOpts = 1;
%menus...
v.hFileMenu = uimenu('Parent',v.hMainFigure,'HandleVisibility','callback','Label','File');
v.hAddLayerMenu = uimenu('Parent',v.hFileMenu,'Label','Add layer','HandleVisibility','callback', ...
    'Callback', utils.curry(@gui.AddLayer_Callback, ~showOpts));
% v.hAddLayerWithOptsMenu = uimenu('Parent',v.hFileMenu,'Label','Add layer with options','HandleVisibility','callback', ...
%     'Callback', utils.curry(@gui.AddLayer_Callback, showOpts));
% v.hCloseLayersMenu = uimenu('Parent',v.hFileMenu,'Label','Close layer(s)','HandleVisibility','callback', 'Callback', @gui.CloseLayers_Callback);
v.hAddTracksMenu = uimenu('Parent',v.hFileMenu,'Label','Add tracks','HandleVisibility','callback','Callback', @gui.AddTracks_Callback);
% v.hCloseTracksMenu = uimenu('Parent',v.hFileMenu, 'Label','Close tracks', 'HandleVisibility', 'callback','Callback', @gui.CloseTracks_Callback);
% v.hAddNodesMenu = uimenu('Parent',v.hFileMenu, 'Label','Add Nodes', 'HandleVisibility', 'callback', ...
%     'Callback', utils.curry(@gui.AddNodes_Callback, ~showOpts));
% v.hAddNodesWithOptsMenu = uimenu('Parent',v.hFileMenu, 'Label','Add Nodes with options', 'HandleVisibility', 'callback',...
%     'Callback', utils.curry(@gui.AddNodes_Callback, showOpts));
% v.hSaveBmpMenu = uimenu('Parent',v.hFileMenu,'Label','Save bitmap','HandleVisibility','callback', 'Callback', @gui.SaveBmpMenu_Callback);
% v.hSaveMeshesMenu = uimenu('Parent',v.hFileMenu,'Label','Save mesh(es)','HandleVisibility','callback', 'Callback', @gui.SaveMeshesMenu_Callback);
% v.closeAllItemsMenu = uimenu('Parent',v.hFileMenu, 'Label','Close All Items', 'HandleVisibility', 'callback','Callback', @gui.CloseAllItems_Callback);
% 
% v.hEditMenu = uimenu('Parent',v.hMainFigure,'HandleVisibility','callback','Label','Edit');
% v.hCopyToClipboardMenu = uimenu('Parent',v.hEditMenu,'Label','Copy To Clipboard','HandleVisibility','callback','Callback', @gui.CopyToClipboardMenu_Callback);
% 
v.hFunctionMenu = uimenu('Parent',v.hMainFigure,'HandleVisibility','callback','Label','Functions');
% v.hToolbarMenu = uimenu('Parent',v.hFunctionMenu,'Label','Show/hide toolbar','HandleVisibility','callback','Callback', @gui.ToolbarMenu_Callback);
% v.hLayerRgbaMenu = uimenu('Parent',v.hFunctionMenu,'Label','Color and transparency','HandleVisibility','callback','Callback', @gui.LayerRGBA_Callback);
% v.hShowWireFrameMenu = uimenu('Parent',v.hFunctionMenu,'Label','Show Wireframe','HandleVisibility',...
%     'callback','Callback', utils.curry(@gui.ShowWireframe_Callback, ~showOpts));
% v.hShowWireFrameWithOptsMenu = uimenu('Parent',v.hFunctionMenu,'Label','Show Wireframe with options','HandleVisibility',...
%     'callback','Callback', utils.curry(@gui.ShowWireframe_Callback, showOpts));
% v.hCloseWireFrameMenu = uimenu('Parent',v.hFunctionMenu,'Label','Hide Wireframe','HandleVisibility','callback','Callback',@gui.HideWireframe_Callback);
% v.hMaterialOptionsMenu = uimenu('Parent',v.hFunctionMenu,'Label','Surface material and lighting','HandleVisibility','callback','Callback', @gui.MaterialOptionsMenu_Callback);
% v.hSimplifyMeshesMenu = uimenu('Parent',v.hFunctionMenu,'Label','Simplify mesh(es)','HandleVisibility','callback','Callback', @gui.SimplifyMeshesMenu_Callback);
% v.hRotateToggleMenu = uimenu('Parent',v.hFunctionMenu,'Label','Rotate','HandleVisibility', 'callback', 'Callback', utils.curry(@gui.RotateToggle_Callback, ~showOpts));
% v.hRotateToggleWithOptionsMenu = uimenu('Parent',v.hFunctionMenu,'Label','Rotate With Options','HandleVisibility', 'callback', 'Callback', utils.curry(@gui.RotateToggle_Callback, showOpts));
v.hChangeBgColorMenu = uimenu('Parent',v.hFunctionMenu, 'Label', 'Change Background Color', 'HandleVisibility', 'callback', 'Callback', @gui.ChangeBgColor_Callback);
% v.hProjectVolumeMenu = uimenu('Parent',v.hFunctionMenu, 'Label', 'Project Volume onto Surface', 'HandleVisibility', 'callback', 'Callback', utils.curry(@gui.ProjectVolume_Callback));
% v.hCloseProjectionsMenu = uimenu('Parent',v.hFunctionMenu, 'Label', 'Close Projected Volumes', 'HandleVisibility', 'callback', 'Callback', @gui.CloseProjections_Callback);
% v.viewHistoryMenu = uimenu('Parent',v.hFunctionMenu, 'Label', 'Echo instructions to command window', 'HandleVisibility', 'callback', 'Callback', @gui.EchoHistory_Callback);
% 
% v.hHelpMenu = uimenu('Parent',v.hMainFigure,'HandleVisibility','callback','Label','Help');
% v.hAboutMenu = uimenu('Parent',v.hHelpMenu,'Label','About','HandleVisibility','callback','Callback', @gui.AboutMenu_Callback);


%load default simulated surfaces
v = drawing.createDemoObjects(v);
%[cubeFV, sphereFV] = drawing.createDemoObjects;
%v.surface(1) = cubeFV;
%v.surface(2) = sphereFV;
%viewing preferences - color, material, camera position, light position
%v.vprefs.demoObjects = true; %denote simulated objects
%v.vprefs.colors = [0.7 0.7 0.9 0.7; 1 0 0 1.0; 0 1 0 0.7; 0 0 1 0.7; 0.5 0.5 0 0.7; 0.5 0 0.5 0.7; 0 0.5 0.5 0.7]; %rgba for each layer CRZ
v.vprefs.colors = [0.7 0.7 0.9 1.0; 1 0 0 1.0; 0 1 0 0.7; 0 0 1 0.7; 0.5 0.5 0 0.7; 0.5 0 0.5 0.7; 0 0.5 0.5 0.7]; %rgba for each layer CRZ
v.vprefs.edgeColors = v.vprefs.colors;
v.vprefs.showEdges = zeros(size(v.vprefs.colors, 1),1);

v.vprefs.materialKaKdKsn = [0.6 0.4 0.4 100.0];%ambient/diffuse/specular strength and specular exponent
v.vprefs.backFaceLighting = 1;
v.vprefs.azLight = 0; %light azimuth relative to camera
v.vprefs.elLight = 90; %light elevation relative to camera
%v.vprefs.elLight = 10; %light elevation relative to camera - 6767
v.vprefs.camLight = [];
v.vprefs.lightangle = [];
v.vprefs.az = 45; %camera azimuth
v.vprefs.el = 10; %camera elevation
v.echoCommands = false; %do not echo user actions to command window
guidata(v.hMainFigure,v);%store settings
vFig = v.hMainFigure;
set(vFig,'name','MRIcroS');
commands.setBackgroundColor(v,[1 1 1]);
drawing.redrawSurface(v);
%end makeGUI()

function checkVersionSub()
if verLessThan('matlab', '7.09')
    error('This software requires Matlab 2009b or later (requires unused argument syntax, "[~ d] = version")');
    % http://blogs.mathworks.com/steve/2010/01/11/about-the-unused-argument-syntax-in-r2009b/
end
if verLessThan('matlab', '7.11')
   printf('WARNING: This software has only been tested on Matlab 2010b and later\n');
end
%end checkVersionSub()

% function checkVersionSub()
% %http://en.wikipedia.org/wiki/MATLAB
% v = sscanf (version, '%d.%d.%d') ; %e.g. Matlab 7.14.0 v = [7; 14; 0]
% v = v(1)+v(2)/100;
% if (v < 7.09)
%    error('This software requires Matlab 2009b or later (requires unused argument syntax, "[~ d] = version")');
%     % http://blogs.mathworks.com/steve/2010/01/11/about-the-unused-argument-syntax-in-r2009b/
% end
% if (v < 7.11)
%    printf('WARNING: This software has only been tested on Matlab 2010b and later\n');
% end
% %end checkVersionSub()
