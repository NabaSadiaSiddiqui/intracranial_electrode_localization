classdef NeuroimagingWindow
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static)
        function mock_2D_window
            uicontrol('style', 'pushbutton', 'units','normalized', 'position', [0.1 0.5 0.3 0.3], 'string', 'Click here', 'callback', @mock_image_clicked);  
        end
    end
    
end

function mock_image_clicked(src, event)
    global electrode_drop_down;
    selected_index = electrode_drop_down.Value;
    selected_value = electrode_drop_down.String(selected_index,:);
    x_and_y = char(strsplit(selected_value, ','));
    x = str2num(x_and_y(1, 2:end));
    y = str2num(x_and_y(2, 1:end-1));
    hold on;
    plot(y, x, '-ob');
    hold off;
end
