classdef MotorMap
    %MOTORMAP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        
        Vibrissa = 1;
        Face = 2;
        DistalForelimb = 3;
        ProximalForelimb = 4;
        Shoulder = 5;
        Neck = 6;
        Hindlimb = 7;
        NoResponse = 8;
        TotalResponses = 9;
        TotalForelimb = 10;
        TotalHead = 11;
        RFA = 12;
        CFA = 13;
        
        PlotStyleNormal = 0;
        PlotStylePoints = 1;
%         PlotColorsNormal = [ ...
%             0.1 0.3 0.5; ... %Vibrissa
%             0.45 0.5 0.8; ... %Face/Jaw
%             0.1 0.5 0.2; ... %Distal
%             0.4 0.5 0.2; ... %Proximal
%             0.85 0.95 0.95; ... %Shoulder
%             0.85 0.85 0.95; ... %Neck
%             1 0.55 0; ... %Hindlimb
%             0 0 0; %No Response
%             ];
        PlotColorsNormal = [ ...
            0.4 0.65 0.3; ... %Vibrissa    
            0.2 0.45 0.1; ... %Face/Jaw
            0.23 0.47 0.83; ... %Distal
            0.06 0.33 0.79; ... %Proximal
            0.43 0.61 0.91; ... %Shoulder
            0.57 0.75 0.48; ... %Neck
            0.86 0.4 0.4; ... %Hindlimb
            0 0 0; %No Response
            ];
        
        MapStrings = {'Vibrissa', 'Face', 'Distal Forelimb', 'Proximal Forelimb', ...
            'Shoulder', 'Neck', 'Hindlimb', 'No Response', 'Any Response', 'Forelimb', 'Face/Head', 'RFA', 'CFA'};
        
        MapAPCoordinates = [-4.0 -3.5 -3.0 -2.5 -2.0 -1.5 -1.0 -0.5 0.0 0.5 1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0];
        MapMLCoordinates = [0.0 0.5 1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 5.5 6.0];
        
    end
    
    properties
        
        MapData
        MapAmplitudes
        MapFile
        IsProbabilityMap
        ProbabilityMapBodyPart
        
    end
    
    methods
        
        function obj = MotorMap ( map_data, varargin )
            
            %Handle optional input parameters
            p = inputParser;
            p.CaseSensitive = false;
            
            defaultIsProbabilityMap = 0;
            defaultIsSimpleMatrix = 0;
            defaultFile = '';
            defaultProbabilityMapBodyPart = MotorMap.DistalForelimb;
            
            addOptional(p, 'IsProbabilityMap', defaultIsProbabilityMap, @isnumeric);
            addOptional(p, 'File', defaultFile);
            addOptional(p, 'IsSimpleMatrix', defaultIsSimpleMatrix, @isnumeric);
            addOptional(p, 'ProbabilityMapBodyPart', defaultProbabilityMapBodyPart, @isnumeric);
            parse(p, varargin{:});
            
            obj.IsProbabilityMap = p.Results.IsProbabilityMap;
            obj.MapFile = p.Results.File;
            obj.ProbabilityMapBodyPart = p.Results.ProbabilityMapBodyPart;
            is_simple_matrix = p.Results.IsSimpleMatrix;
            
            if (~is_simple_matrix)
                %We will enter this condition of the if-statement if the
                %data is coming from a map file and is a structure.
                %Basically, if it comes from the ReadMotorMap() function.
                data = map_data.map;
                amplitudes = map_data.amps;
                
                xsize = size(data, 1);
                ysize = size(data, 2);

                dest_xsize = length(MotorMap.MapMLCoordinates);
                dest_ysize = length(MotorMap.MapAPCoordinates);

                obj.MapData = nan(dest_xsize, dest_ysize);
                obj.MapAmplitudes = nan(dest_xsize, dest_ysize);

                for x=1:xsize
                    for y = 1:ysize

                        map_value = data(x, y);
                        
                        amp_index = amplitudes(x, y);
                        
                        if (~isnan(amp_index) && ~isempty(amp_index) && isscalar(amp_index))
                            amp_value = str2double(map_data.amp_labels{amp_index});
                        else
                            amp_value = NaN;
                        end
                        
                        if (~isnan(map_value))
                            string_from_map_data = strtrim(map_data.body_labels{map_value});
                            dest_xval = map_data.x_steps(x) * 2 + 1;
                            dest_yval = map_data.y_steps(y) * 2 + 9;

                            for j=1:MotorMap.NoResponse
                                if (~isempty(strfind(string_from_map_data, obj.MapStrings{j})))
                                    obj.MapData(dest_xval, dest_yval) = j;
                                    obj.MapAmplitudes(dest_xval, dest_yval) = amp_value;
                                end
                            end

                        end

                    end
                end
            else
                %If it is a simple matrix
                obj.MapData = map_data;
            end
            
        end
        
        function num_responses = RetrieveData ( obj, varargin )
            p = inputParser;
            p.CaseSensitive = false;
            
            defaultDataItem = MotorMap.DistalForelimb;
            addOptional(p, 'MuscleType', defaultDataItem, @isnumeric);
            parse(p, varargin{:});
            data_item = p.Results.MuscleType;
            
            if (data_item <= MotorMap.NoResponse)
                num_responses = length(find(obj.MapData == data_item));
            else
                if (data_item == MotorMap.TotalForelimb)
                    num_responses = length(find(obj.MapData == MotorMap.DistalForelimb)) + ...
                        length(find(obj.MapData == MotorMap.ProximalForelimb)) + ...
                        length(find(obj.MapData == MotorMap.Shoulder));
                elseif (data_item == MotorMap.TotalHead)
                    num_responses = length(find(obj.MapData == MotorMap.Vibrissa)) + ...
                        length(find(obj.MapData == MotorMap.Neck)) + ...
                        length(find(obj.MapData == MotorMap.Face));
                elseif (data_item == MotorMap.TotalResponses)
                    num_responses = 0;
                    for i=1:(MotorMap.NoResponse-1)
                        num_responses = num_responses + length(find(obj.MapData == i));
                    end
                elseif (data_item == MotorMap.RFA)
                    anterior_indices = find(MotorMap.MapAPCoordinates >= 2.0);
                    anterior_map = obj.MapData(:, anterior_indices);
                    num_responses = length(find(anterior_map == MotorMap.DistalForelimb)) + ...
                        length(find(anterior_map == MotorMap.ProximalForelimb)) + ...
                        length(find(anterior_map == MotorMap.Shoulder));
                elseif (data_item == MotorMap.CFA)
                    posterior_indices = find(MotorMap.MapAPCoordinates >= 2.0);
                    posterior_map = obj.MapData(:, posterior_indices);
                    num_responses = length(find(posterior_map == MotorMap.DistalForelimb)) + ...
                        length(find(posterior_map == MotorMap.ProximalForelimb)) + ...
                        length(find(posterior_map == MotorMap.Shoulder));
                else
                    num_responses = 0;
                end
            end
            
        end
        
        function PlotMap ( obj, varargin )
            
            %Handle optional input parameters
            p = inputParser;
            p.CaseSensitive = false;
            
            defaultPlotStyle = obj.PlotStyleNormal;
            defaultPlotNoResponses = 0;
            defaultPlotEdgeLines = 1;
            defaultSignificanceMap = [];
            defaultNoResponsesWithXMarker = 0;
            defaultPlotGridLines = 1;
            defaultPlotLegend = 0;
            defaultSimplifyMap = 0;
            defaultPlotInterpolatedHeatMap = 1;
            addOptional(p, 'PlotStyle', defaultPlotStyle, @isnumeric);
            addOptional(p, 'PlotNoResponseSites', defaultPlotNoResponses, @isnumeric);
            addOptional(p, 'PlotEdgeLines', defaultPlotEdgeLines, @isnumeric);
            addOptional(p, 'SignificanceMap', defaultSignificanceMap);
            addOptional(p, 'NoResponsesWithXMarker', defaultNoResponsesWithXMarker, @isnumeric);
            addOptional(p, 'PlotGridLines', defaultPlotGridLines, @isnumeric);
            addOptional(p, 'PlotLegend', defaultPlotLegend, @isnumeric);
            addOptional(p, 'SimplifyMap', defaultSimplifyMap, @isnumeric);
            addOptional(p, 'PlotInterpolatedHeatMap', defaultPlotInterpolatedHeatMap, @isnumeric);
            parse(p, varargin{:});
            plot_style = p.Results.PlotStyle;
            plot_no_responses = p.Results.PlotNoResponseSites;
            plot_edge_lines = p.Results.PlotEdgeLines;
            significance_map = p.Results.SignificanceMap;
            no_responses_with_x = p.Results.NoResponsesWithXMarker;
            plot_grid_lines = p.Results.PlotGridLines;
            plot_legend = p.Results.PlotLegend;
            simplify_map = p.Results.SimplifyMap;
            plot_interpolated_heat_map = p.Results.PlotInterpolatedHeatMap;
            
            %Plot the map
            f.fig = figure('units', 'centimeters', ...
                'position', [1 3 16 22], ...
                'color', 'w');
            f.axes = axes('parent', f.fig, ...
                'units', 'centimeters', ...
                'position', [2 2 13 19]);
            set(gca, 'clipping', 'off');

            f.colors = obj.PlotColorsNormal;
            hold on;

            if (plot_style == obj.PlotStyleNormal)
                
                x_size = size(obj.MapData, 1);
                y_size = size(obj.MapData, 2);
                
                %Draw grid lines
                if (plot_grid_lines)
                    max_xval = length(MotorMap.MapMLCoordinates)+1;
                    max_yval = length(MotorMap.MapAPCoordinates)+1;
                    for y = 1:max_yval
                        line([0 max_xval], [y y], 'LineStyle', ':', 'Color', [0.7 0.7 0.7]);
                    end
                    for x = 1:max_xval
                        line([x x], [0 max_yval], 'LineStyle', ':', 'Color', [0.7 0.7 0.7]);
                    end
                end
                
                %Plot the legend
                if (plot_legend)
                    set(gcf, 'position', [1 3 23 22]);
                    xval_legend = length(MotorMap.MapMLCoordinates)+2.1;
                    top_yval = length(MotorMap.MapAPCoordinates)+0.1;
                    
                    if (~simplify_map)
                        rectangle('Position', [xval_legend top_yval 0.8 0.8], 'FaceColor', MotorMap.PlotColorsNormal(MotorMap.Vibrissa, :));
                        rectangle('Position', [xval_legend top_yval-1 0.8 0.8], 'FaceColor', MotorMap.PlotColorsNormal(MotorMap.Face, :));
                        rectangle('Position', [xval_legend top_yval-2 0.8 0.8], 'FaceColor', MotorMap.PlotColorsNormal(MotorMap.Neck, :));
                        rectangle('Position', [xval_legend top_yval-3 0.8 0.8], 'FaceColor', MotorMap.PlotColorsNormal(MotorMap.DistalForelimb, :));
                        rectangle('Position', [xval_legend top_yval-4 0.8 0.8], 'FaceColor', MotorMap.PlotColorsNormal(MotorMap.ProximalForelimb, :));
                        rectangle('Position', [xval_legend top_yval-5 0.8 0.8], 'FaceColor', MotorMap.PlotColorsNormal(MotorMap.Shoulder, :));
                        rectangle('Position', [xval_legend top_yval-6 0.8 0.8], 'FaceColor', MotorMap.PlotColorsNormal(MotorMap.Hindlimb, :));

                        text(xval_legend+1, top_yval+0.5, MotorMap.MapStrings(MotorMap.Vibrissa), 'FontSize', 18);
                        text(xval_legend+1, top_yval-0.5, MotorMap.MapStrings(MotorMap.Face), 'FontSize', 18);
                        text(xval_legend+1, top_yval-1.5, MotorMap.MapStrings(MotorMap.Neck), 'FontSize', 18);
                        text(xval_legend+1, top_yval-2.5, MotorMap.MapStrings(MotorMap.DistalForelimb), 'FontSize', 18);
                        text(xval_legend+1, top_yval-3.5, MotorMap.MapStrings(MotorMap.ProximalForelimb), 'FontSize', 18);
                        text(xval_legend+1, top_yval-4.5, MotorMap.MapStrings(MotorMap.Shoulder), 'FontSize', 18);
                        text(xval_legend+1, top_yval-5.5, MotorMap.MapStrings(MotorMap.Hindlimb), 'FontSize', 18);
                    else
                        rectangle('Position', [xval_legend top_yval 0.8 0.8], 'FaceColor', MotorMap.PlotColorsNormal(MotorMap.Vibrissa, :));
                        rectangle('Position', [xval_legend top_yval-1 0.8 0.8], 'FaceColor', MotorMap.PlotColorsNormal(MotorMap.DistalForelimb, :));
                        rectangle('Position', [xval_legend top_yval-2 0.8 0.8], 'FaceColor', MotorMap.PlotColorsNormal(MotorMap.Hindlimb, :));
                        text(xval_legend+1, top_yval+0.5, MotorMap.MapStrings(MotorMap.TotalHead), 'FontSize', 18);
                        text(xval_legend+1, top_yval-0.5, MotorMap.MapStrings(MotorMap.TotalForelimb), 'FontSize', 18);
                        text(xval_legend+1, top_yval-1.5, MotorMap.MapStrings(MotorMap.Hindlimb), 'FontSize', 18);
                    end
                end
                
                if (obj.IsProbabilityMap)
                    %colors = flipud(jet(100));
                    colors = jet(100);
                    colormap(colors);
                end
                
                for x = 1:x_size
                    for y = 1:y_size
                        
                        if (obj.IsProbabilityMap)
                            
                            if (plot_interpolated_heat_map)
                                
                                probability_map = obj.MapData;
                                interpolated_data = interp2(probability_map, 5);
                                interpolated_data = interpolated_data';
                                interpolated_data = interpolated_data * 100;
                                
                                %min_x = min(MotorMap.MapAPCoordinates);
                                %max_x = max(MotorMap.MapAPCoordinates);
                                %min_y = min(MotorMap.MapMLCoordinates);
                                %max_y = max(MotorMap.MapMLCoordinates);
                                
                                min_x = 1;
                                max_x = length(MotorMap.MapAPCoordinates) + 1;
                                min_y = 1;
                                max_y = length(MotorMap.MapMLCoordinates) + 1;
                                
                                rectangle('Position', [0 0 max_y+0.1 max_x+0.1], 'FaceColor', colors(1, :));
                                image('YData', [min_x max_x], 'XData', [min_y max_y], 'CData', interpolated_data);
                                
                                
                                
                            else
                                
                                probability = obj.MapData(x, y);
                                override_edge_color = 0;
                                if (~isempty(significance_map))
                                    if (significance_map(x, y) > 0)
                                        if (probability == 0)
                                            rectangle('Position', [x y 1 1], 'FaceColor', [1 1 1], 'EdgeColor', [1 0 0]);
                                        else
                                            override_edge_color = 1;
                                        end
                                    end
                                end

                                if (probability > 0)
                                    fill_color = colors(round(probability * 100), :);
                                    edge_color = [0 0 0];
                                    if (~plot_edge_lines)
                                        edge_color = fill_color;
                                    end

                                    if (override_edge_color)
                                        edge_color = [1 0 0];
                                        fill_color = [1 0 0];
                                    end

                                    rectangle('Position', [x y 1 1], 'FaceColor', fill_color, 'EdgeColor', edge_color);
                                end
                                
                            end
                            

                            
                        else
                            data_point = obj.MapData(x, y);

                            if (~isnan(data_point))
                                if ((data_point == MotorMap.NoResponse && plot_no_responses) || data_point ~= MotorMap.NoResponse)
                                    
                                    if (simplify_map)
                                        if (data_point == MotorMap.Vibrissa || ...
                                            data_point == MotorMap.Face || ...
                                            data_point == MotorMap.Neck)
                                            fill_color = f.colors(MotorMap.Vibrissa, :);
                                        elseif (data_point == MotorMap.DistalForelimb || ...
                                            data_point == MotorMap.ProximalForelimb || ...
                                            data_point == MotorMap.Shoulder)
                                            fill_color = f.colors(MotorMap.DistalForelimb, :);
                                        else
                                            fill_color = f.colors(data_point, :);
                                        end
                                    else
                                        fill_color = f.colors(data_point, :);    
                                    end
                                    
                                    edge_color = [0 0 0];
                                    if (~plot_edge_lines)
                                        edge_color = fill_color;
                                    end
                                    
                                    
                                    if (data_point == MotorMap.NoResponse && no_responses_with_x)
                                        line([x+0.4 x+0.6], [y+0.4 y+0.6], 'Color', 'k', 'LineWidth', 2);
                                        line([x+0.4 x+0.6], [y+0.6 y+0.4], 'Color', 'k', 'LineWidth', 2);
                                    else
                                        rectangle('Position', [x y 1 1], 'FaceColor', fill_color, 'EdgeColor', edge_color);
                                    end
                                end
                            end
                        end
                    end
                end
                
                set(gca, 'xlim', [0 14]);
                set(gca, 'xtick', [1.5 11.5]);
                set(gca, 'xticklabel', {'0' '5'});
                
                set(gca, 'ylim', [0 20]);
                set(gca, 'ytick', [1.5 9.5 19.5]);
                set(gca, 'yticklabel', {'-4' '0' '5'});
                
                set(gca, 'fontsize', 18);
                set(gca, 'fontweight', 'bold');
                
                xlabel('Lateral', 'fontsize', 18);
                ylabel('Anterior', 'fontsize', 18);
                
                %Arrow next to the xlabel
                line([8.5 11], [-1.6 -1.6], 'Color', [0 0 0], 'LineWidth', 2);
                line([10.75 11], [-1.5 -1.6], 'Color', [0 0 0], 'LineWidth', 2);
                line([10.75 11], [-1.7 -1.6], 'Color', [0 0 0], 'LineWidth', 2);
                
                %Arrow next to the ylabel
                line([-1.25 -1.25], [12 14.5], 'Color', [0 0 0], 'LineWidth', 2);
                line([-1.15 -1.25], [14.25 14.5], 'Color', [0 0 0], 'LineWidth', 2);
                line([-1.35 -1.25], [14.25 14.5], 'Color', [0 0 0], 'LineWidth', 2);
                
                if (obj.IsProbabilityMap)
                    colorbar();
                end
                
            else
                %Not normal plot style
                %TO DO: this code
                disp('Error: code has not yet been written to plot in this style');
            end
            
            
        end
        
        function PlotMap2 ( obj, varargin )
            
            %Handle optional input parameters
            p = inputParser;
            p.CaseSensitive = false;
            
            defaultPlotStyle = obj.PlotStyleNormal;
            defaultPlotNoResponses = 0;
            defaultPlotEdgeLines = 1;
            defaultSignificanceMap = [];
            defaultNoResponsesWithXMarker = 0;
            defaultPlotGridLines = 1;
            defaultPlotLegend = 0;
            defaultSimplifyMap = 0;
            defaultPlotInterpolatedHeatMap = 1;
            defaultAxes = 0;
            defaultLegendForelimbOnly = 0;
            defaultBregmaIndicatorColor = [0.5 0.5 0.5];
            defaultLegendLocation = 0;
            addOptional(p, 'PlotStyle', defaultPlotStyle, @isnumeric);
            addOptional(p, 'PlotNoResponseSites', defaultPlotNoResponses, @isnumeric);
            addOptional(p, 'PlotEdgeLines', defaultPlotEdgeLines, @isnumeric);
            addOptional(p, 'SignificanceMap', defaultSignificanceMap);
            addOptional(p, 'NoResponsesWithXMarker', defaultNoResponsesWithXMarker, @isnumeric);
            addOptional(p, 'PlotGridLines', defaultPlotGridLines, @isnumeric);
            addOptional(p, 'PlotLegend', defaultPlotLegend, @isnumeric);
            addOptional(p, 'SimplifyMap', defaultSimplifyMap, @isnumeric);
            addOptional(p, 'PlotInterpolatedHeatMap', defaultPlotInterpolatedHeatMap, @isnumeric);
            addOptional(p, 'Axes', defaultAxes);
            addOptional(p, 'BregmaIndicatorColor', defaultBregmaIndicatorColor);
            addOptional(p, 'LegendForelimbOnly', defaultLegendForelimbOnly);
            addOptional(p, 'LegendLocation', defaultLegendLocation);
            parse(p, varargin{:});
            plot_style = p.Results.PlotStyle;
            plot_no_responses = p.Results.PlotNoResponseSites;
            plot_edge_lines = p.Results.PlotEdgeLines;
            significance_map = p.Results.SignificanceMap;
            no_responses_with_x = p.Results.NoResponsesWithXMarker;
            plot_grid_lines = p.Results.PlotGridLines;
            plot_legend = p.Results.PlotLegend;
            simplify_map = p.Results.SimplifyMap;
            plot_interpolated_heat_map = p.Results.PlotInterpolatedHeatMap;
            map_plot_axes = p.Results.Axes;
            bregma_circle_color = p.Results.BregmaIndicatorColor;
            legend_forelimb_only = p.Results.LegendForelimbOnly;
            legend_location = p.Results.LegendLocation;
            
            %Grab the figure that the user passed in, or create a new figure.
            axes_width = 5.8;
            axes_height = 7.66;
            
            figure_class = class(map_plot_axes);
            if (strcmpi(figure_class, 'matlab.graphics.axis.Axes'))
                %map_position = get(map_plot_axes, 'position');
                %set(map_plot_axes, ...
                %    'units', 'centimeters', ...
                %    'position', [map_position(1) map_position(2) axes_width axes_height]);
            else
                %Plot the map
                f.fig = figure('units', 'centimeters', ...
                    'position', [1 3 16 22], ...
                    'color', 'w');
                f.axes = axes('parent', f.fig, ...
                    'units', 'centimeters', ...
                    'position', [2 2 13 19]);
                set(gca, 'clipping', 'off');

                f.colors = obj.PlotColorsNormal;
                hold on;
            end
            
            f.colors = obj.PlotColorsNormal;
            
            if (plot_style == obj.PlotStyleNormal)
                
                x_size = size(obj.MapData, 1);
                y_size = size(obj.MapData, 2);
                
                %Draw grid lines
                if (plot_grid_lines)
                    max_xval = length(MotorMap.MapMLCoordinates)+1;
                    max_yval = length(MotorMap.MapAPCoordinates)+1;
                    for y = 1:max_yval
                        line([0 max_xval], [y y], 'LineStyle', ':', 'Color', [0.7 0.7 0.7]);
                    end
                    for x = 1:max_xval
                        line([x x], [0 max_yval], 'LineStyle', ':', 'Color', [0.7 0.7 0.7]);
                    end
                end
                
                if (plot_legend)
                    xval_legend = length(MotorMap.MapMLCoordinates)-4.5;
                    top_yval = length(MotorMap.MapAPCoordinates)-1;
                    
                    if (~simplify_map)
                        rectangle('Position', [xval_legend top_yval 0.8 0.8], 'FaceColor', MotorMap.PlotColorsNormal(MotorMap.Vibrissa, :));
                        rectangle('Position', [xval_legend top_yval-1 0.8 0.8], 'FaceColor', MotorMap.PlotColorsNormal(MotorMap.Face, :));
                        rectangle('Position', [xval_legend top_yval-2 0.8 0.8], 'FaceColor', MotorMap.PlotColorsNormal(MotorMap.Neck, :));
                        rectangle('Position', [xval_legend top_yval-3 0.8 0.8], 'FaceColor', MotorMap.PlotColorsNormal(MotorMap.DistalForelimb, :));
                        rectangle('Position', [xval_legend top_yval-4 0.8 0.8], 'FaceColor', MotorMap.PlotColorsNormal(MotorMap.ProximalForelimb, :));
                        rectangle('Position', [xval_legend top_yval-5 0.8 0.8], 'FaceColor', MotorMap.PlotColorsNormal(MotorMap.Shoulder, :));
                        rectangle('Position', [xval_legend top_yval-6 0.8 0.8], 'FaceColor', MotorMap.PlotColorsNormal(MotorMap.Hindlimb, :));

                        text(xval_legend+1, top_yval+0.5, MotorMap.MapStrings(MotorMap.Vibrissa), 'FontSize', 18);
                        text(xval_legend+1, top_yval-0.5, MotorMap.MapStrings(MotorMap.Face), 'FontSize', 18);
                        text(xval_legend+1, top_yval-1.5, MotorMap.MapStrings(MotorMap.Neck), 'FontSize', 18);
                        text(xval_legend+1, top_yval-2.5, MotorMap.MapStrings(MotorMap.DistalForelimb), 'FontSize', 18);
                        text(xval_legend+1, top_yval-3.5, MotorMap.MapStrings(MotorMap.ProximalForelimb), 'FontSize', 18);
                        text(xval_legend+1, top_yval-4.5, MotorMap.MapStrings(MotorMap.Shoulder), 'FontSize', 18);
                        text(xval_legend+1, top_yval-5.5, MotorMap.MapStrings(MotorMap.Hindlimb), 'FontSize', 18);
                    else
                        
                        if (legend_location == 1)
                            top_yval = 5;
                        end
                        
                        if (~legend_forelimb_only)
                            rectangle('Position', [xval_legend top_yval 0.8 0.8], 'FaceColor', MotorMap.PlotColorsNormal(MotorMap.Vibrissa, :));
                            rectangle('Position', [xval_legend top_yval-1 0.8 0.8], 'FaceColor', MotorMap.PlotColorsNormal(MotorMap.DistalForelimb, :));
                            rectangle('Position', [xval_legend top_yval-2 0.8 0.8], 'FaceColor', MotorMap.PlotColorsNormal(MotorMap.Hindlimb, :));
                            text(xval_legend+1, top_yval+0.5, MotorMap.MapStrings(MotorMap.TotalHead), 'FontSize', 8);
                            text(xval_legend+1, top_yval-0.5, MotorMap.MapStrings(MotorMap.TotalForelimb), 'FontSize', 8);
                            text(xval_legend+1, top_yval-1.5, MotorMap.MapStrings(MotorMap.Hindlimb), 'FontSize', 8);
                        else
                            rectangle('Position', [xval_legend top_yval 0.8 0.8], 'FaceColor', MotorMap.PlotColorsNormal(MotorMap.DistalForelimb, :));
                            text(xval_legend+1, top_yval+0.5, MotorMap.MapStrings(MotorMap.TotalForelimb), 'FontSize', 8);
                        end
                    end
                end
                
                if (obj.IsProbabilityMap)
                    %colors = flipud(jet(100));
                    colors = jet(100);
                    %colors = flipud(hot(100));
                    colormap(colors);
                end
                
                for x = 1:x_size
                    for y = 1:y_size
                        
                        if (obj.IsProbabilityMap)
                            
                            if (plot_interpolated_heat_map)
                                
                                probability_map = obj.MapData;
                                interpolated_data = interp2(probability_map, 5);
                                interpolated_data = interpolated_data';
                                interpolated_data = interpolated_data * 100;
                                
                                %min_x = min(MotorMap.MapAPCoordinates);
                                %max_x = max(MotorMap.MapAPCoordinates);
                                %min_y = min(MotorMap.MapMLCoordinates);
                                %max_y = max(MotorMap.MapMLCoordinates);
                                
                                min_x = 1;
                                max_x = length(MotorMap.MapAPCoordinates) + 1;
                                min_y = 1;
                                max_y = length(MotorMap.MapMLCoordinates) + 1;
                                
                                %rectangle('Position', [0 0 max_y+0.1 max_x+0.1], 'FaceColor', colors(1, :));
                                image('YData', [min_x max_x], 'XData', [min_y max_y], 'CData', interpolated_data);
                                
                                
                                
                            else
                                
                                probability = obj.MapData(x, y);
                                override_edge_color = 0;
                                if (~isempty(significance_map))
                                    if (significance_map(x, y) > 0)
                                        if (probability == 0)
                                            rectangle('Position', [x y 1 1], 'FaceColor', [1 1 1], 'EdgeColor', [1 0 0]);
                                        else
                                            override_edge_color = 1;
                                        end
                                    end
                                end

                                if (probability > 0)
                                    fill_color = colors(round(probability * 100), :);
                                    edge_color = [0 0 0];
                                    if (~plot_edge_lines)
                                        edge_color = fill_color;
                                    end

                                    if (override_edge_color)
                                        edge_color = [1 0 0];
                                        fill_color = [1 0 0];
                                    end

                                    rectangle('Position', [x y 1 1], 'FaceColor', fill_color, 'EdgeColor', edge_color);
                                end
                                
                            end
                            

                            
                        else
                            data_point = obj.MapData(x, y);

                            if (~isnan(data_point))
                                if ((data_point == MotorMap.NoResponse && plot_no_responses) || data_point ~= MotorMap.NoResponse)
                                    
                                    if (simplify_map)
                                        if (data_point == MotorMap.Vibrissa || ...
                                            data_point == MotorMap.Face || ...
                                            data_point == MotorMap.Neck)
                                            fill_color = f.colors(MotorMap.Vibrissa, :);
                                        elseif (data_point == MotorMap.DistalForelimb || ...
                                            data_point == MotorMap.ProximalForelimb || ...
                                            data_point == MotorMap.Shoulder)
                                            fill_color = f.colors(MotorMap.DistalForelimb, :);
                                        else
                                            fill_color = f.colors(data_point, :);
                                        end
                                    else
                                        fill_color = f.colors(data_point, :);    
                                    end
                                    
                                    edge_color = [0 0 0];
                                    if (~plot_edge_lines)
                                        edge_color = fill_color;
                                    end
                                    
                                    
                                    if (data_point == MotorMap.NoResponse && no_responses_with_x)
                                        line([x+0.4 x+0.6], [y+0.4 y+0.6], 'Color', 'k', 'LineWidth', 1);
                                        line([x+0.4 x+0.6], [y+0.6 y+0.4], 'Color', 'k', 'LineWidth', 1);
                                    else
                                        rectangle('Position', [x y 1 1], 'FaceColor', fill_color, 'EdgeColor', edge_color);
                                    end
                                end
                            end
                        end
                    end
                end
                
                set(gca, 'xlim', [0 14]);
                set(gca, 'xtick', [1.5 11.5]);
                set(gca, 'xticklabel', {'0' '5'});
                
                set(gca, 'ylim', [0 20]);
                set(gca, 'ytick', [1.5 9.5 19.5]);
                set(gca, 'yticklabel', {'-4' '0' '5'});
                
                %Bregma circle
                rectangle('Position', [1.25 9.25 0.5 0.5], 'Curvature', [1 1], 'EdgeColor', bregma_circle_color, 'FaceColor', bregma_circle_color);
                
                %lateral_edge = 12.5;
                %x_arrow_start = lateral_edge - 0.25;
                
                %Horizontal line from bregma
                %line([1.5 lateral_edge], [9.5 9.5], 'LineStyle', '--', 'Color', bregma_circle_color, 'LineWidth', 1);
                %line([x_arrow_start lateral_edge], [9.75 9.5], 'Color', bregma_circle_color, 'LineWidth', 1);
                %line([x_arrow_start lateral_edge], [9.25 9.5], 'Color', bregma_circle_color, 'LineWidth', 1);
                
                %Vertical line from bregma
                %line([1.5 1.5], [9.5 19.5], 'LineStyle', '--', 'Color', bregma_circle_color, 'LineWidth', 1);
                %line([1.25 1.5], [19.25 19.5], 'Color', bregma_circle_color, 'LineWidth', 1);
                %line([1.75 1.5], [19.25 19.5], 'Color', bregma_circle_color, 'LineWidth', 1);
                
                if (obj.IsProbabilityMap && plot_legend)
                    colorbar();
                end
                
            end
            
            
        end
        
        
        function PlotPenetrationSites ( obj, varargin )
            
            %Handle optional input parameters
            p = inputParser;
            p.CaseSensitive = false;
            
            defaultAxes = 0;
            defaultBregmaIndicatorColor = [0.5 0.5 0.5];
            addOptional(p, 'Axes', defaultAxes);
            addOptional(p, 'BregmaIndicatorColor', defaultBregmaIndicatorColor);
            parse(p, varargin{:});
            map_plot_axes = p.Results.Axes;
            bregma_circle_color = p.Results.BregmaIndicatorColor;
            
            %Grab the figure that the user passed in, or create a new figure.
            axes_width = 5.8;
            axes_height = 7.66;
            
            figure_class = class(map_plot_axes);
            if (strcmpi(figure_class, 'matlab.graphics.axis.Axes'))
                %map_position = get(map_plot_axes, 'position');
                %set(map_plot_axes, ...
                %    'units', 'centimeters', ...
                %    'position', [map_position(1) map_position(2) axes_width axes_height]);
            else
                %Plot the map
                f.fig = figure('units', 'centimeters', ...
                    'position', [1 3 16 22], ...
                    'color', 'w');
                f.axes = axes('parent', f.fig, ...
                    'units', 'centimeters', ...
                    'position', [2 2 13 19]);
                set(gca, 'clipping', 'off');

                f.colors = obj.PlotColorsNormal;
                hold on;
            end
            
            f.colors = obj.PlotColorsNormal;

            x_size = size(obj.MapData, 1);
            y_size = size(obj.MapData, 2);

            for x = 1:x_size
                for y = 1:y_size

                    rectangle('Position', [(x+0.35) (y+0.35) 0.3 0.3], 'Curvature', [1 1], 'EdgeColor', 'k', 'FaceColor', 'k');

                end
            end

            set(gca, 'xlim', [0 14]);
            set(gca, 'xtick', [1.5 11.5]);
            set(gca, 'xticklabel', {'0' '5'});

            set(gca, 'ylim', [0 20]);
            set(gca, 'ytick', [1.5 9.5 19.5]);
            set(gca, 'yticklabel', {'-4' '0' '5'});

            %Bregma circle
            %rectangle('Position', [1.25 9.25 0.5 0.5], 'Curvature', [1 1], 'EdgeColor', bregma_circle_color, 'FaceColor', bregma_circle_color);
                
            
            
        end
        
        
        
        
    end
    
end




























