function vert_adj_list = vert_adj_list(faces, vertices)
    % Build adjacency list of vertices to faces (represented by indexes in
    %   respective arrays)
    [num_faces, num_vertices] = size(faces);
    vert_adj_list = cell(size(vertices, 1), 1);
    for i = 1:num_faces
        for j = 1:num_vertices
            subcell = vert_adj_list{ faces(i, j) };
            vert_adj_list{ faces(i, j) }{ size(subcell, 2)+1 } = i;
        end
    end
end