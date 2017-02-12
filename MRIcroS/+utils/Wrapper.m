classdef Wrapper < handle
    properties(Access=public)
        v
    end
    methods
        function obj = Wrapper(v)
            obj.v = v;
        end
        function v = get(this)
            v = this.v;
        end
        function set(this, v)
            this.v = v;
        end
    end
end