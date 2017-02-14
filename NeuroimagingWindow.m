classdef NeuroimagingWindow
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static)
        function mock_2D_window
            axes('position', [0.1 0.5 0.3 0.3]);
            hold on;

            sz = 75;
            
            x1 = linspace(1, 5, 5);
            y1 = 5 * ones(1,5);            
            scatter(x1, y1, sz, 'filled', 'g', 'ButtonDownFcn', @get_coord);            

            x2 = linspace(3, 6, 4);
            y2 = 8 * ones(1,4);
            scatter(x2, y2, sz, 'filled', 'm', 'ButtonDownFcn', @get_coord);
            y2 = 9 * ones(1,4);
            scatter(x2, y2, sz, 'filled', 'm', 'ButtonDownFcn', @get_coord);
            y2 = 10 * ones(1,4);
            scatter(x2, y2, sz, 'filled', 'm', 'ButtonDownFcn', @get_coord);
            y2 = 11 * ones(1,4);
            scatter(x2, y2, sz, 'filled', 'm', 'ButtonDownFcn', @get_coord);
            y2 = 12 * ones(1,4);
            scatter(x2, y2, sz, 'filled', 'm', 'ButtonDownFcn', @get_coord);
            
            hold off;            
        end
    end
    
end

function get_coord(h, e)

    % --- Get coordinates
    x = get(h, 'XData');
    y = get(h, 'YData');

    % --- Get index of the clicked point
    [~, i] = min((e.IntersectionPoint(1)-x).^2 + (e.IntersectionPoint(2)-y).^2);
    disp(strcat('(', num2str(x(i)), ',', num2str(y(i)), ')'));
    
    global electrode_drop_down;
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
end


