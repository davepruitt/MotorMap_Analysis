function data = ReadMotorMap(file)

%Open the file.
fid = fopen(file);          

%Read all of the lines
text_lines = {};
latest_line = fgetl(fid);
while (ischar(latest_line))
    text_lines{end+1} = latest_line;
    latest_line = fgetl(fid);
end

%Close the file
fclose(fid); 

%Remove the header line
text_lines{1} = [];

%Create variables to hold map variables.
xy = [];
amps = {};
depths = {};
regions = {};

%Iterate through each line of text
for i = 1:length(text_lines)
    %Parse out the coordinate and body region from this line
    line = text_lines{i};
    [x_str, line] = strtok(line);
    [y_str, line] = strtok(line);
    [amp, line] = strtok(line);
    [depth, line] = strtok(line);
    region = strtrim(line);
    
    xy = [xy; str2double(x_str) str2double(y_str)];
    amps{i} = amp;
    depths{i} = depth;
    regions{i} = region;
end

data.depth_labels = unique(depths);         %Find the unique tested depth steps.
data.amp_labels = unique(amps);             %Find the unique tested current amplitude steps.
data.body_labels = unique(regions);         %Find the unique activated body regions.
data.x_steps = unique(xy(:,1));             %Find all the unique x coordinates.
data.y_steps = unique(xy(:,2));             %Find all the unique y coordinates.
%data.x_steps = min(data.x_steps):min(diff(data.x_steps)):max(data.x_steps);     %Set all possible discrete values of x from min to max.
%data.y_steps = min(data.y_steps):min(diff(data.y_steps)):max(data.y_steps);     %Set all possible discrete values of y from min to max.
data.x_steps = 0.5:0.5:5;
data.y_steps = -3:0.5:5;

data.map = nan(length(data.x_steps),length(data.y_steps));        %Create an activated body region map covering the range of x and y values.
data.amps = nan(length(data.x_steps),length(data.y_steps));       %Create a current amplitude map covering the range of x and y values.
data.depths = nan(length(data.x_steps),length(data.y_steps));     %Create an electrode depth map covering the range of x and y values.
for k = 1:length(regions)                   %Step through the activated body region for each coordinate.
    if ~strcmpi(regions{k},'NaN')           %If the body region was specified for this coordinate...
        data.map(xy(k,1) == data.x_steps,xy(k,2) == data.y_steps) = find(strcmpi(regions{k},data.body_labels));   %...mark it on the map.
    end
end
for k = 1:length(amps)                      %Step through the current amplitude for each coordinate.
    if ~strcmpi(amps{k},'NaN')              %If the current amplitude was specified for this coordinate...
        data.amps(xy(k,1) == data.x_steps,xy(k,2) == data.y_steps) = find(strcmpi(amps{k},data.amp_labels));       %...mark it on the map.
    end
end
for k = 1:length(depths)                    %Step through the electrode depth for each coordinate.
    if ~strcmpi(depths{k},'NaN')            %If the electrode depth was specified for this coordinate...
        data.depths(xy(k,1) == data.x_steps,xy(k,2) == data.y_steps) = find(strcmpi(depths{k},data.depth_labels));    %...mark it on the map.
    end
end