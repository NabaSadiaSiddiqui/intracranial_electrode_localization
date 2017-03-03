classdef Grid
    properties(Access = public)
        name
        markers
        h_linkages
        v_linkages
    end
    methods(Access = public)
        function obj = Grid(name, width, height)
            obj.name = name;
            obj.markers = cell(width, height);
            obj.h_linkages = NaN(width-1, height);
            obj.v_linkages = NaN(width, height-1); % fenceposts!
        end
    end
end