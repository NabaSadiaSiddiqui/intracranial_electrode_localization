classdef GeometryController
    properties(Access = protected)
       surf
       vol
       hdr
    end
    
    methods(Access = public)
        function obj = GeometryController(surf, vol, hdr)
            obj.surf = surf;
            obj.vol = vol;
            obj.hdr = hdr;
        end
        function redraw(this, hAxes)
            this.surf.redraw(hAxes);
        end
        function centroid = marker_by_point(this, P, radius)
            if ~isempty(this.vol)
                centroid = this.marker_by_point_vol(P, radius);
            else
                centroid = this.surf.marker_by_point(P);
            end
        end
    end
    methods(Access = protected)
        function centroid = marker_by_point_vol(this, P, radius)
            % identify 3mm x 3mm x 3mm rhombohedron
            % affine -> linear (dispose of translation)
            lin = this.hdr.mat(1:3, 1:3);
            L = round(radius ./ sqrt(sum(lin.^2, 1))).'; % pixels in respective direction to attain 3mm edge length
            P_prime = round(this.hdr.mat \ [P.'; 1]); % remap click on surf to image coordinate
            lower = P_prime(1:3) - ceil(L./2);
            sample = this.vol(lower(1):lower(1)+L(1)-1, lower(2):lower(2)+L(2)-1, lower(3):lower(3)+L(3)-1);
            
            % weighted average
            weight = zeros(3, 1);
            for i = 1:L(1)
                for j = 1:L(2)
                    for k = 1:L(3)
                        weight = weight + [i; j; k] .* sample(i, j, k);
                    end
                end
            end
            centroidish = this.hdr.mat * [lower + weight ./ sum(sample(:)); 1]; % adjust by predicted offset, and remap to model space
            centroid = centroidish(1:3);
        end
    end
end