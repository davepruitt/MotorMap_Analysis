classdef MotorMapSet
    
    properties
        
        Maps
        Group
        GroupName
        
    end
    
    methods
        
        function obj = MotorMapSet(file_list)
            for i=1:length(file_list)
                if (~isempty(file_list{i}))
                    map_data = ReadMotorMap(file_list{i});
                    maps(i) = MotorMap(map_data, 'File', file_list(i));
                end
            end
            
            obj.Maps = maps;
        end
        
        function numeric_array = RetrieveDataset (obj, varargin)
            p = inputParser;
            p.CaseSensitive = false;
            
            defaultDataItem = MotorMap.DistalForelimb;
            addOptional(p, 'MuscleType', defaultDataItem, @isnumeric);
            parse(p, varargin{:});
            data_item = p.Results.MuscleType;
            
            numeric_array = nan(length(obj.Maps), 1);
            for i = 1:length(obj.Maps)
                numeric_array(i) = obj.Maps(i).RetrieveData('MuscleType', data_item);
            end
        end
        
        function obj = RetrieveProbabilityMap (obj, varargin)
            
            %Handle optional input parameters
            p = inputParser;
            p.CaseSensitive = false;
            
            defaultBodyPart = MotorMap.TotalForelimb;
            defaultNormalize = 1;
            addOptional(p, 'BodyPart', defaultBodyPart, @isnumeric);
            addOptional(p, 'Normalize', defaultNormalize, @isnumeric);
            parse(p, varargin{:});
            body_part = p.Results.BodyPart;
            normalize_result = p.Results.Normalize;
            
            %Body part list
            body_part_list = [];
            if (body_part == MotorMap.TotalForelimb)
                body_part_list = [MotorMap.DistalForelimb MotorMap.ProximalForelimb MotorMap.Shoulder];
            elseif (body_part == MotorMap.TotalHead)
                body_part_list = [MotorMap.Vibrissa MotorMap.Neck MotorMap.Face];
            elseif (body_part == MotorMap.TotalResponses)
                body_part_list = 1:(MotorMap.NoResponse-1);
            else
                body_part_list = body_part;
            end
            
            map_matrix = zeros(length(MotorMap.MapMLCoordinates), length(MotorMap.MapAPCoordinates));
            for i=1:length(obj.Maps)
                for x=1:size(obj.Maps(i).MapData, 1)
                    for y=1:size(obj.Maps(i).MapData, 2)
                        datapoint = obj.Maps(i).MapData(x, y);
                        if (~isnan(datapoint))
                            found = ~isempty(find(body_part_list == datapoint));
                            if (found)
                                map_matrix(x, y) = map_matrix(x, y) + 1;
                            end
                        end
                    end
                end
            end
            
            if (normalize_result)
                map_matrix = map_matrix / length(obj.Maps);
            end
            
            obj = MotorMap(map_matrix, 'IsProbabilityMap', 1, 'IsSimpleMatrix', 1);
        end
        
    end
    
end

