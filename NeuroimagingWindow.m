classdef NeuroimagingWindow
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static)
        function mock_2D_window(handle_grid)
            axes('position', [0.1 0.5 0.3 0.3]);
            hold on;

            sz = 75;
            
            x1 = linspace(1, 5, 5);
            y1 = 5 * ones(1,5);            

            x2 = linspace(3, 6, 4);
            y2_a = 8 * ones(1,4);
            y2_b = 9 * ones(1,4);
            y2_c = 10 * ones(1,4);
            y2_d = 11 * ones(1,4);
            y2_e = 12 * ones(1,4);
            
            xLimits = [];
            xLimits(1) = min(x1);
            xLimits(2) = max(x1);
            xLimits(3) = min(x2);
            xLimits(4) = max(x2);
            yLimits = [];
            yLimits(1) = min(y1);
            yLimits(2) = max(y1);
            yLimits(3) = min(y2_a);
            yLimits(4) = max(y2_a);
            yLimits(5) = min(y2_b);
            yLimits(6) = max(y2_b);
            yLimits(7) = min(y2_c);
            yLimits(8) = max(y2_c);
            yLimits(9) = min(y2_d);
            yLimits(10) = max(y2_d);
            yLimits(11) = min(y2_e);
            yLimits(12) = max(y2_e);
            
            xlim([0 max(xLimits)+1]);
            ylim([0 max(yLimits)+1]);
            
            scatter(x1, y1, sz, 'filled', 'g', 'ButtonDownFcn', {@get_coord, handle_grid});            
            scatter(x2, y2_a, sz, 'filled', 'm', 'ButtonDownFcn', {@get_coord, handle_grid});
            scatter(x2, y2_b, sz, 'filled', 'm', 'ButtonDownFcn', {@get_coord, handle_grid});
            scatter(x2, y2_c, sz, 'filled', 'm', 'ButtonDownFcn', {@get_coord, handle_grid});
            scatter(x2, y2_d, sz, 'filled', 'm', 'ButtonDownFcn', {@get_coord, handle_grid});
            scatter(x2, y2_e, sz, 'filled', 'm', 'ButtonDownFcn', {@get_coord, handle_grid});
            
            hold off;            
        end
    end
    
end

function get_coord(h, e, handle_grid)

    % --- Get coordinates
    x = get(h, 'XData');
    y = get(h, 'YData');

    % --- Get index of the clicked point
    [~, i] = min((e.IntersectionPoint(1)-x).^2 + (e.IntersectionPoint(2)-y).^2);
    disp(strcat('(', num2str(x(i)), ',', num2str(y(i)), ')'));
    
    x(i) = [];
    y(i) = [];
    set(h, 'XData', x);
    set(h, 'YData', y);
    
    update_grid(handle_grid);
end

function update_grid(handle_grid)
    electrode_drop_down = handle_grid.GridElectrodeDropdown;
    selected_index = electrode_drop_down.Value;
    selected_value = electrode_drop_down.String(selected_index,:);
    x_and_y = char(strsplit(selected_value, ','));
    x = str2num(x_and_y(1, 2:end));
    y = str2num(x_and_y(2, 1:end-1));
    global ax_grid;
    axes(ax_grid);
    hold on;
    plot(y, x, '-ob');
    hold off;
    handle_grid.add_marked_electrode(selected_value);
end


