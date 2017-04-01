classdef SkinnedGrid < handle
    properties(Access = public)
        name
        dims
        markers_skinned
    end
    
    methods(Access = public)
        function obj = SkinnedGrid(name, dims, markers_skinned)
            obj.name = name;
            obj.dims = dims;
            obj.markers_skinned = markers_skinned;
        end
    end
end