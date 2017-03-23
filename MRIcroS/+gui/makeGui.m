function [vFig] = makeGui()
% --- Declare and create all the user interface objects
checkVersionSub()
sz = [980 680]; % figure width, height in pixels
screensize = get(0,'ScreenSize');
margin = [ceil((screensize(3)-sz(1))/2) ceil((screensize(4)-sz(2))/2)];
v_w = utils.Wrapper(struct());
v_w.v.hMainFigure = figure('MenuBar','none','Toolbar','none','HandleVisibility','on', ...
  'position',[margin(1), margin(2), sz(1), sz(2)], ...
    'Tag', mfilename,'Name', mfilename, 'NumberTitle','off', ...
 'Color', get(0, 'defaultuicontrolbackgroundcolor'));
set(v_w.v.hMainFigure,'Renderer','OpenGL')
v_w.v.hAxes = axes('HandleVisibility','on'); %important: turn ON visibility
% Grid properties

% v.h_text_grid =  uicontrol('style','text', 'string','Grid Properties', 'position',[0.005 0.85 0.15 0.09]);
% % v.h_frame_grid = uicontrol('style', 'frame', 'position', [0.01 0.64 0.49 0.25]);
% v.h_text_grid_name =  uicontrol('style','text', 'string','Name:', 'position',[0.02 0.75 0.1 0.1]);
% v.h_edit_grid_name =  uicontrol('style','edit', 'string','Grid X', 'position',[0.16 0.75 0.19 0.1]);
% v.h_text_grid_dimensions =  uicontrol('style','text', 'string','Dimensions:', 'position',[0.02 0.65 0.14 0.1]);
v_w.v.h_edit_grid_dimensions_x =  uicontrol('style','edit');
v_w.v.h_edit_grid_dimensions_y =  uicontrol('style','edit');
v_w.v.h_grid_dropdown = uicontrol('style', 'popup');
% v_w.v.h_grid_adder = uicontrol('style', 'pushbutton', 'string', 'Add Grid', 'Callback', @(~, ~) v_w.get().add_grid('Unnamed', 8, 8));
v_w.v.h_grid_name = uicontrol('style','edit', 'HorizontalAlignment', 'Left');
% v.h_push_button_grid_dimensions = uicontrol('style', 'pushbutton', 'string', 'Update Grid', 'callback', {@setup_electrode_grid_callback, v.h_edit_grid_dimensions_x, v.h_edit_grid_dimensions_y}, 'position', [0.35 0.65 0.15 0.1]);

v_w.v.ax_grid = axes('box', 'off',...
        'xtick', 0:1/(8+1):1, 'ytick', 0:1/(8+1):1, ...
        'xgrid', 'on', 'ygrid', 'on');
set(v_w.v.ax_grid, 'YTickLabel', []);
set(v_w.v.ax_grid, 'XTickLabel', []);
xlim(v_w.v.ax_grid, [0, 1]);
ylim(v_w.v.ax_grid, [0, 1]);

v_w.v.h_unmark_button = uicontrol('style', 'pushbutton', 'string', 'Unmark', 'Visible', 'Off', 'Callback', @(~, ~) v_w.get().controller.unmark_current());

% uicontrol('style','text', 'position',[0.005 0.55 0.15 0.05], 'string', 'Pick an electrode');
% v.h_electrode_drop_down = uicontrol('style','popup');
v_w.v.h_electrode_x = uicontrol('style', 'popup', 'Callback', ...
    @(src, ev) v_w.v.controller.select([ v_w.v.h_electrode_x.Value, v_w.v.h_electrode_y.Value ]));
v_w.v.h_electrode_y = uicontrol('style', 'popup', 'Callback', ...
    @(src, ev) v_w.v.controller.select([ v_w.v.h_electrode_x.Value, v_w.v.h_electrode_y.Value ]));

v_w.v.fFigurePanel = gui.FloatingControl(...
    uipanel(), [ 0; 0 ], [[ -240, 1.0 ]; [ 0, 1.0 ]], [ ...
        gui.FloatingControl(...
            v_w.v.hAxes, zeros(2, 2), [[ 0, 1 ]; [ 0, 1 ]]...
        ) ...
    ]...
);
label_height = 16;
input_height = 22;
v_w.v.fFigureUtilPanel = gui.FloatingControl(uipanel(), ...
    [ -240; 0.0 ], [[ 0, 1.0 ]; [ 0, 1.0 ]], [ ...
        gui.FloatingControl(v_w.v.h_grid_dropdown, ...
            [ 10; -25 ], [[ -10, 1.0 ]; [ label_height, 0.0 ] ]), ...
        gui.FloatingControl(uipanel('BorderType', 'none'), ...
            [ 10; -175 ], [[ -10, 1.0 ]; [ 140, 0.0 ]], [...
                gui.FloatingControl(uicontrol('style','text', 'HorizontalAlignment', 'Left', 'string','Grid Properties'), ...
                    [ 0; -25 ], [[ 0, 1.0 ]; [ label_height, 0.0 ] ]), ...
                gui.FloatingControl(uicontrol('style','text', 'HorizontalAlignment', 'Left', 'string','Name:'), ...
                    [ 15; -50 ], [ 35; label_height ]), ...
                gui.FloatingControl(v_w.v.h_grid_name, ...
                    [ 90; -52 ], [[ 0, 1.0 ]; [ input_height, 0.0 ]]), ...
                gui.FloatingControl(uicontrol('style','text', 'HorizontalAlignment', 'Left', 'string','Dimensions:'), ...
                    [ 15; -75 ], [ 60; label_height ]), ...
                gui.FloatingControl(uipanel(), ...
                    [ 90; -77 ], [[ 0, 1.0 ]; [ input_height, 0.0 ]], [...
                        gui.FloatingControl(v_w.v.h_edit_grid_dimensions_x, ...
                            [0; 0], [[ 0, 0.5 ]; [ 0, 1.0 ]]), ...
                        gui.FloatingControl(v_w.v.h_edit_grid_dimensions_y, ...
                            [[ 0, 0.5 ]; [ 0, 0.0 ]], [[ 0, 1.0 ]; [ 0, 1.0 ]]) ...
                    ]), ...
                gui.FloatingControl(uicontrol('style', 'pushbutton', 'string', 'Update Grid', 'callback', @(~, ~) v_w.get().controller.update_grid()),...
                    [ 90; -100 ], [[ 0, 1.0 ]; [ input_height, 0.0 ]])
            ]), ...
        gui.FloatingControl(uicontrol('style', 'text', 'HorizontalAlignment', 'Left', 'string', 'Pick an electrode'), ...
            [ 10; -165 ], [[ -10, 1.0 ]; [ input_height, 0.0 ]]), ...
        gui.FloatingControl(uipanel('BorderType', 'none'), ...
            [ 10; -205 ], [[ -10, 1.0 ]; [ 2*input_height, 0.0 ]], [...
                gui.FloatingControl(v_w.v.h_electrode_x, ...
                    [0; 0], [[ 0, 0.5 ]; [ 0, 1.0 ]]), ...
                gui.FloatingControl(v_w.v.h_electrode_y, ...
                    [[ 0, 0.5 ]; [ 0, 0.0 ]], [[ 0, 1.0 ]; [ 0, 1.0 ]]) ...
                gui.FloatingControl(v_w.v.h_unmark_button, ...
                    [ 0; 1.0], [[ 0, 1.0 ]; [ input_height, 0 ]])...
            ]), ...
        gui.FloatingControl(v_w.v.ax_grid, ...
            [ 10; 10 ], [[ -10, 1.0 ]; [ 240, 0.0 ]]), ...
    ]...
);

% Must construct controller AFTER UI elements are defined: constructor
% modifies UI elements
v_w.v.controller = electrode.GeometryController(v_w);
v_w.v.controller.add_grid('Grid X', 8, 8);

set(v_w.v.hMainFigure, 'ResizeFcn', @refloatPanels);
set(v_w.v.hMainFigure, 'KeyPressFcn', @keypress_handler);

v = v_w.v; % stop with the Wrapper nonsense for the native MRIcroS below

function refloatPanels(src, ~)
    v = guidata(src);
    v.fFigurePanel.reposition(v.hMainFigure);
    v.fFigureUtilPanel.reposition(v.hMainFigure);
end

function keypress_handler(src, ev)
    v = guidata(src);
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
            v.controller.select(...
                [ v.h_electrode_x.Value, ...
                  v.h_electrode_y.Value ...
                ] + direction);
        end
    elseif strcmp(ev.Key, 'escape')
        v.controller.unmark_current();
    end
end

function keyboard_move(src, ev)
    
end

% [0.0 0.0 1 1]

% %%%%%%%%%%%%%%%%%%%%%%%%%%%% %
% [Electrode selection window] %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%% %

% Create frame object that represents NeuroImaging window
%h_frame_left = uicontrol('style', 'frame', 'units', 'normalized', 'position', [0 0.3 0.5 1]);

% Create frame object that represents electrode editing controls



function create_electrode_drop_down(src, ~, dim_x, dim_y)
    v = guidata(src);
    
%     % Drop down list to select electrodes
%     options = '';
%     for x = linspace(1, dim_x, dim_x)
%         for y = linspace(1, dim_y, dim_y)
%             option = strcat('(', num2str(x), ',', num2str(y), ')');
%             options = strcat(options, '|', option);
%         end
%     end
%     options = options(2:end);
    
    set(v.h_electrode_x, 'string', [1:dim_x]);
    set(v.h_electrode_y, 'string', [1:dim_y]);
end

function create_grid( src, ~, dim_x, dim_y )
    v = guidata(src);
    cla(v.ax_grid);
    % Create grid
    % xtick = [] and ytick = [] turns off labels
    x = linspace(1, dim_x, dim_x);
    y = linspace(1, dim_y, dim_y);
    [X, Y] = meshgrid(y,x);
    plot(v.ax_grid, X, Y, '-dr');
end

function setup_electrode_grid(src, ev, h_grid_dim_x, h_grid_dim_y)
    % Read dimensions for creating grid
    h_grid_x = str2num(h_grid_dim_x.String);
    h_grid_y = str2num(h_grid_dim_y.String);
    create_electrode_drop_down(src, ev, h_grid_x, h_grid_y);
    create_grid(src, ev, h_grid_x, h_grid_y);
end

function setup_electrode_grid_callback(src, event, handle_x, handle_y)
    setup_electrode_grid(src, event, handle_x, handle_y)
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
% [/Electrode selection window] %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%% %

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
refloatPanels(vFig);
% setup_electrode_grid(vFig, NaN, v.h_edit_grid_dimensions_x, v.h_edit_grid_dimensions_y);

set(vFig,'name','MRIcroS');
commands.setBackgroundColor(v,[1 1 1]);
drawing.redrawSurface(v);
%end makeGUI()

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
end