function delete_grid(src, event, handles)
%VIEW_GRIDS Summary of this function goes here
%   Detailed explanation goes here
    grid_add();
    
    global grids;
    grid_list = {};
    for grid = grids
        grid_list = [grid_list, {grid.name}];
    end
    
    [s,v] = listdlg('PromptString', 'Select a grid to delete',...
                'SelectionMode', 'single',...
                'ListString', grid_list);
    
    if v == 1
        grids(s) = [];
    end
end

