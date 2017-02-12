function [E1, E2] = tri_planes(faces, vertices)
    E1 = vertices(faces(:,2),:)-vertices(faces(:,1),:);
    E2 = vertices(faces(:,3),:)-vertices(faces(:,1),:);
end