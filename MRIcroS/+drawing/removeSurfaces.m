function v = removeSurfaces(v)
%removeSurfaces remove the surfaces from main screen
%if the objects are on the screen
%otherwise performs no operation
% note: this does not remove the 'surfacePatches' or 'surface' field
%inputs
%	v: the handle to the GUI with the demo objects
%outputs
%	v: returns the handle with the surfaces removed after updating guiData

if(isfield(v, 'surfacePatches'))
	delete(v.surfacePatches);
    v = rmfield(v,'surfacePatches'); %bugfix 16-Oct-2014: remove handle
	guidata(v.hMainFigure, v); %save changes
end

if(isfield(v, 'markerPatches'))
	delete(v.markerPatches);
    v = rmfield(v,'markerPatches'); %bugfix 16-Oct-2014: remove handle
	guidata(v.hMainFigure, v); %save changes
end
