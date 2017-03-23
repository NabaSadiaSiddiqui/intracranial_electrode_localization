classdef FloatingControl < handle
    properties(Access = public)
        h % graphics handle for this object
        float = [0 0] % bottom-left
        area % [ length (px), length (%-parent-length) ]
        offset % [ length (px), length (%-parent-length) ]
        children = [] % offsetChildren graphics handles
    end
    methods(Access = public)
        function obj = FloatingControl(varargin)
            obj.h = varargin{1};
            
            if size(varargin{2}, 2) == 1
                % no relative portion: set to 0
                obj.offset = [ varargin{2}, [ 0; 0 ] ];
            else
                obj.offset = varargin{2};
            end
            
            if size(varargin{3}, 2) == 1
                % no relative portion: set to 0
                obj.area = [ varargin{3}, [ 0; 0 ] ];
            else
                obj.area = varargin{3};
            end
            
            if(length(varargin) > 3)
                obj.children = varargin{4};
                for i = 1:length(obj.children)
                    set(obj.children(i).h, 'Parent', obj.h);
                end
            end
            obj.float = obj.offset(:,2) < 0 | obj.offset(:,2) == 0 & obj.offset(:,1) < 0;
        end
        function this = add_child(this, child)
            this.children = [ this.children, child ];
            set(child, 'Parent', this.h);
        end
        function reposition(this, hFig)
            this.sub_reposition([hFig.Position(3:4).', [ 1.0; 1.0 ]], false);
        end
    end
    methods(Access = protected)
        function sub_reposition(this, parent_area, denormalize_flag)
            sgn_float = this.float.*2 - 1; % {0, 1} -> {-1, 1}
            norm_offset = abs(this.float - this.offset(:, 2)); % normalized to parent area
        
%                 this.area(:, 2) .* ([ 1; 1 ] - this.offset(:, 2)) ...
%                     ... % bound area by the offset and the walls
            
            if ~denormalize_flag && ...
               isequal(this.offset(:, 1), [ 0; 0 ]) && ...
               isequal(this.area(:, 1), [ 0; 0 ])
                % no pixel component: use normalized units
                adjusted_area = parent_area(:,2) .* ...
                    this.area(:,2) .* (norm_offset + (this.area(:,2) > 0) .* ([ 1; 1 ] - 2 * norm_offset));
                adjusted_offset = parent_area(:,2) .* norm_offset - max(-adjusted_area, 0);
                set(this.h, 'Units', 'normalized');
                set(this.h, 'Position', [ adjusted_offset; adjusted_area ]);
                parent_area(:, 2) = adjusted_area; % update for children
            else
                if ~denormalize_flag
                    parent_area(:, 1) = parent_area(:, 1) .* parent_area(:, 2); % apply fractional to absolute
                end
                px_offset = parent_area(:,1) .* norm_offset + this.offset(:,1);
                px_area = this.area(:,2) .* (px_offset + (this.area(:,2) > 0) .* (parent_area(:,1) - 2 * px_offset)) + ...
                    this.area(:,1); % adjust pixels
                
                adjusted_offset = px_offset - max(-px_area, 0);
                setpixelposition(this.h, [ adjusted_offset; abs(px_area) ]);
                parent_area(:, 1) = px_area; % update for children
                denormalize_flag = true;
            end
            for i = 1:length(this.children)
                this.children(i).sub_reposition(parent_area, denormalize_flag);
            end
        end
    end
end