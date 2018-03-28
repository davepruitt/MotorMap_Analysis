function MotorMapV5
%% RELEASE NOTES

% MotorMapV5 - created on 8 Jan 2016
% Edited from MotorMapV4 by David Pruitt
% Changes:
%   - You can now manually type in thresholds at each location
%   - You can now load saved maps
%   - You can press "tab" to go to the next location on the map

% END OF RELEASE NOTES

%% Set the entries that will appear in the pop-up menus.
depths = {'1.6','1.8','2.0','1.6-2.0'};                                     %List the possible electrode depths.
amplitudes = cell(length(20:10:200),1);                                     %Create an empty list to hold the current amplitude list.
for i = 20:10:200                                                           %Step through current amplitudes from 20 uA to 200 uA in 20 uA steps.
    amplitudes{i/10} = num2str(i);                                          %Save the amplitude with a units label.
end
body_regions = {'Grasp','Wrist/Digit Extension','Elbow Flexion',...
    'Abduction','Retract','Supination', 'Pronation','Vibrissae','Neck', 'Jaw', ...
    'Hindlimb', 'Trunk', 'Tail', 'No Response'};                     %List the possible activated body regions.
    
%% Create cell arrays to hold depth, current amplitude, and body region values.
handles.x = 0:0.5:6;                                                        %Set the x-axis steps.
handles.y = -4:0.5:5;                                                       %Set the y-axis steps.
handles.depths = cell(length(handles.x),length(handles.y));                 %Create a cell array to hold the stimulation depths.
handles.amps = cell(length(handles.x),length(handles.y));                   %Create a cell array to hold the stimulation amplitudes.
handles.map = cell(length(handles.x),length(handles.y));                    %Create a cell array to hold the activated body region.
handles.notes = cell(length(handles.x),length(handles.y));                  %Create a cell array to hold any notes for the site.
handles.colors = jet(length(body_regions));                                 %Create unique colors for each body region.
handles.colors(handles.colors ~= 1) = ...
    handles.colors(handles.colors ~= 1) + ...
    0.5*(1 - handles.colors(handles.colors ~= 1));                          %Lighten all of the layer colors.        
handles.colors(end,:) = [0 0 0 ];                                           %Make the last region color gray for "No Response".
handles.blind = 0;                                                          %Start with an unblinded map by default.
handles.selected_color = 1;
handles.body_regions = body_regions;

%% Create the figure, axes, listboxes, and buttons.
set(0,'Units','Centimeters');                                               %Set the default system units to centimeters.
pos = get(0,'ScreenSize');                                                  %Grab the screensize.
pos = [0.2*pos(3),0.05*pos(4),0.6*pos(3),0.9*pos(4)];                       %Scale a figure position relative to the screensize.
handles.fig = figure;                                                       %Create a new figure.
set(handles.fig,'units','centimeters',...
    'Position',pos,...
    'MenuBar','none',...
    'name','Motor Map',...
    'numbertitle','off',...
    'PaperPositionMode','auto',...
    'KeyPressFcn', @HandleKeyPress, ...
    'color','w');                                                           %Set the properties of the figure.
handles.fontsize = 0.6*pos(4);                                              %Set the fontsize for all uicontrols.
temp = uicontrol(handles.fig,'style','edit',...
    'string','Notes:',...
    'units','centimeters',...
    'position',[0.1, 0.1, 0.1, 0] + [0, 0, .028, 0.05].*pos,...
    'enable','off',...
    'fontweight','bold',...
    'fontsize',handles.fontsize,...
    'enable','inactive',...
    'horizontalalignment','center',...
    'backgroundcolor',[0.75 0.75 1]);                                       %Make a label for the notes editbox.
a = get(temp,'extent');                                                     %Grab the size of the string in the editbox.
a = 1.1*a(3:4);                                                             %Add some margin around the string.
set(temp,'position',get(temp,'position').*[1,1,0,0]+[0, 0, a]);             %Resize the text label.
b = get(temp,'position');                                                   %Grab the new text label position.
b = b(2) + b(4) + 0.2;                                                      %Calculate the bottom edge of the axes and the save button.
handles.axes = axes('units','centimeters',...
    'position',[0.1, b, pos(3)-0.2, pos(4)-0.1-b],...
    'gridlinestyle',':',...
    'xlim',[0,6],'ylim',[-4,5],...
    'xdir','reverse',...
    'xtick',0:0.5:6,...
    'ytick',-4:0.5:5,...
    'box','on');                                                            %Create an axes object for ploting the map.
handles = DrawMap(handles);                                                 %Create the initial map.
a = get(handles.axes,'position');                                           %Grab the axes new position.
pos(3) = a(3)/0.7 + 0.3;                                                    %Resize the figure width.
set(handles.fig,'position',pos);                                            %Apply the new figure position.
pos = [pos(3:4),pos(3:4)];                                                  %Save the width and height of the figure for later calculations.
b = get(temp,'position');                                                   %Grab the new text label position.
handles.editnotes = uicontrol(handles.fig,'style','edit',...
    'string',[],...
    'units','centimeters',...
    'horizontalalignment','left',...
    'position',[b(1)+b(3)+0.1,b(2),pos(3)-b(1)-b(3)-0.2,b(4)],...
    'fontsize',handles.fontsize,...
    'enable','off',...
    'callback',@EditNotes);                                                 %Make an editox for entering notes about each site.
b = b(2) + b(4) + 0.1;                                                      %Calculate the bottom edge of the axes and the save button.
a = a(1) + a(3) + 0.2;                                                      %Set the left edge of the uicontrols.

handles.loadbutton = uicontrol(handles.fig,'style','pushbutton',...
    'string', 'Load Data',...
    'units', 'centimeters',...
    'position',[a, b, pos(3)-0.1-a, 0]+[0, 0, 0, 0.02].*pos, ...
    'enable','on',...
    'fontweight','bold',...
    'fontsize',handles.fontsize,...
    'callback',@LoadMap);
b = b + 0.02*pos(4) + 0.1;
handles.savebutton = uicontrol(handles.fig,'style','pushbutton',...
    'string','Save Data',...
    'units','centimeters',...
    'position',[a, b, pos(3)-0.1-a, 0]+[0, 0, 0, 0.02].*pos,...
    'enable','off',...
    'fontweight','bold',...
    'fontsize',handles.fontsize,...
    'callback',@SaveData);                                                  %Make a button for saving the data.
b = b + 0.02*pos(4) + 0.1;                                                  %Calculate the bottom edge of the blind button.
handles.blindbutton = uicontrol(handles.fig,'style','pushbutton',...
    'string','Blind',...
    'units','centimeters',...
    'position',[a, b, pos(3)-0.1-a, 0]+[0, 0, 0, 0.02].*pos,...
    'enable','off',...
    'fontweight','bold',...
    'fontsize',handles.fontsize,...
    'callback',@Blind);                                                     %Make a button for blinding/unblinding the data.
b = b + 0.02*pos(4) + 0.2;                                                  %Calculate the bottom edge of the lowest panel.\
pos(4) = pos(4) - b;                                                        %Recalcalate the remaining height to fit the panels in.
temp = [length(depths), length(amplitudes),length(body_regions)];           %Figure out how many choices there will be for each parameter.
p = uipanel(handles.fig,...
    'units','centimeters',...
    'position',[a, b, pos(3)-0.1-a, (pos(4)-0.3)*temp(3)/sum(temp)],...
    'title','Region',...
    'fontweight','bold',...
    'fontsize',handles.fontsize,...
    'backgroundcolor',get(handles.fig,'color'));                            %Create a panel to hold the depth buttons.
handles.bodybutton = zeros(temp(3),1);                                      %Pre-allocate a matrix to hold uicontrol handles.
for i = 1:temp(3)                                                           %Step through each possible body region.
    handles.bodybutton(i) = uicontrol(p,'style','pushbutton',...
        'string',body_regions{i},...
        'units','normalized',...
        'position',[.05 .95-i*(0.9/temp(3)) .9 (0.9/temp(3))],...
        'enable','off',...
        'fontweight','bold',...
        'fontsize',handles.fontsize,...
        'backgroundcolor',handles.colors(i,:),...
        'callback',{@var_select,'map',body_regions{i}});                    %Make a button for each possible depth.
end
set(handles.bodybutton(i),'foregroundcolor','w');                           %Set the text color for the "No Response" button to white.
b = b + (pos(4)-0.3)*temp(3)/sum(temp) + 0.1;                               %Calculate the bottom edge of the middle panel.
p = uipanel(handles.fig,...
    'units','centimeters',...
    'position',[a, b, pos(3)-0.1-a, (pos(4)-0.3)*temp(2)/sum(temp)],...
    'title','Amplitude',...
    'fontweight','bold',...
    'fontsize',handles.fontsize,...
    'backgroundcolor',get(handles.fig,'color'));                            %Create a panel to hold the depth buttons.
handles.ampbutton = zeros(temp(2),1);                                       %Pre-allocate a matrix to hold uicontrol handles.
for i = 1:temp(2)                                                           %Step through each possible depth.
    handles.ampbutton(i) = uicontrol(p,'style','pushbutton',...
        'string',[amplitudes{i} ' uA'],...
        'units','normalized',...
        'position',[.05 .95-i*(0.9/temp(2)) .9 (0.9/temp(2))],...
        'enable','off',...
        'fontweight','bold',...
        'fontsize',handles.fontsize,...
        'callback',{@var_select,'amps',amplitudes{i}});                     %Make a button for each possible depth.
end
b = b + (pos(4)-0.3)*temp(2)/sum(temp) + 0.1;                               %Calculate the bottom edge of the middle panel.
p = uipanel(handles.fig,...
    'units','centimeters',...
    'position',[a, b, pos(3)-0.1-a, (pos(4)-0.3)*temp(1)/sum(temp)],...
    'title','Depth',...
    'fontweight','bold',...
    'fontsize',handles.fontsize,...
    'backgroundcolor',get(handles.fig,'color'));                            %Create a panel to hold the depth buttons.
handles.depthbutton = zeros(temp(1),1);                                     %Pre-allocate a matrix to hold uicontrol handles.
for i = 1:temp(1)                                                           %Step through each possible depth.
    handles.depthbutton(i) = uicontrol(p,'style','pushbutton',...
        'string',[depths{i} ' mm'],...
        'units','normalized',...
        'position',[.05 .95-i*(0.9/temp(1)) .9 (0.9/temp(1))],...
        'enable','off',...
        'fontweight','bold',...
        'fontsize',handles.fontsize,...
        'callback',{@var_select,'depths',depths{i}});                       %Make a button for each possible depth.
end
set(handles.fig,'WindowButtonDownFcn',@ButtonDown);                         %Set the buttondown function
objs = get(handles.fig,'children');                                         %Grab all children of the figure.
set(objs,'units','normalized');                                             %Make the units of all figure children normalized.
handles.pos = get(handles.fig,'position');                                  %Grab the figure position.
set(handles.fig,'ResizeFcn',@Resize);                                       %Set the resize function for the figure.
guidata(handles.fig,handles);                                               %Pin the handles structure to the GUI.


%% This function handles key presses in the figure.
function HandleKeyPress(hObject, eventdata)
handles = guidata(hObject);

%Make sure we record the time of the keypress
if (~isfield(handles, 'last_keypress_time'))
    handles.last_keypress_time = 0;
end

%Find the difference in time between the current keypress and the last
%keypress
this_keypress_time = now;
diff_keypress_time = (this_keypress_time - handles.last_keypress_time) * 86400;

%If there is more than 100ms between keypresses, then we will handle the
%current keypress (this is because for the GUI is very slow at refreshing,
%and it will operate better at these speeds)
if (diff_keypress_time > 0.1)

    %Save the current keypress time
    handles.last_keypress_time = this_keypress_time;
    
    %Make sure that the user has at least initially selected a position on
    %the map
    if (isfield(handles, 'current_xy'))
        %Grab the event data
        key_pressed = eventdata.Key;
        modifier_key = eventdata.Modifier;
        
        numerals = {'1','2','3','4','5','6','7','8','9','0'};
        
        %Get the currently selected coordinate
        xy = handles.current_xy;

        if (~isempty(key_pressed))
            %If the user decided to change coordinates using the arrow
            %keys, then select a new coordinate
            if (strcmpi(key_pressed, 'uparrow') == 1)
                xy(2) = xy(2) + 1;
            elseif (strcmpi(key_pressed, 'leftarrow') == 1)
                xy(1) = xy(1) + 1;
            elseif (strcmpi(key_pressed, 'rightarrow') == 1)
                xy(1) = xy(1) - 1;
            elseif (strcmpi(key_pressed, 'downarrow') == 1)
                xy(2) = xy(2) - 1;
            end
            
            %If the user enters a number
            if (any(strcmpi(numerals, key_pressed)))
                current_threshold = handles.amps{handles.current_xy(1), handles.current_xy(2)};
                
                if (isempty(current_threshold) || any(isnan(current_threshold)) || strcmpi('NaN', current_threshold))
                    current_threshold = key_pressed;
                else
                    current_threshold = [current_threshold key_pressed];
                end
                
                handles.amps{handles.current_xy(1), handles.current_xy(2)} = current_threshold;
                
            elseif (strcmpi(key_pressed, 'backspace'))
                current_threshold = handles.amps{handles.current_xy(1), handles.current_xy(2)};
                
                if (isempty(current_threshold) || any(isnan(current_threshold)) || strcmpi('NaN', current_threshold))
                    current_threshold = 'NaN';
                else
                    current_threshold(end) = [];
                    if (isempty(current_threshold))
                        current_threshold = 'NaN';
                    end
                end
                
                handles.amps{handles.current_xy(1), handles.current_xy(2)} = current_threshold;
                
            end
            
            if (strcmpi(key_pressed, 'tab'))
                
                %Disable ALL controls in the figure to prevent default
                %tabbing behavior
                set(vertcat(handles.depthbutton, handles.ampbutton,...
                    handles.bodybutton, handles.savebutton,...
                    handles.blindbutton, handles.editnotes, handles.loadbutton),'enable','off');
                
                %Change the xy coordinate
                xy(1) = xy(1) - 1;
                if (xy(1) < 1)
                    xy(1) = 13;
                    xy(2) = xy(2) - 1;
                end
                
                %Re-enable controls in the figure
                set(vertcat(handles.depthbutton, handles.ampbutton,...
                    handles.bodybutton, handles.savebutton,...
                    handles.blindbutton, handles.editnotes, handles.loadbutton),'enable','on');
                
            end
            
            %Make sure that the coordinate is within the bounds of the map
            if (xy(1) > 13)
                xy(1) = 13;
            elseif (xy(1) < 1)
                xy(1) = 1;
            end

            if (xy(2) > 19)
                xy(2) = 19;
            elseif (xy(2) < 1)
                xy(2) = 1;
            end
            
            %If the user presses "shift" plus an arrow key, then
            %allow the user to multiselect several coordinates
            
            %If the user presses a letter key, then select the body part to
            %use to fill in the selected coordinate of the map
            handles.selected_color = 0;
            if (strcmpi(key_pressed, 'v') == 1)
                handles.selected_color = 1;
            elseif (strcmpi(key_pressed, 'd') == 1)
                handles.selected_color = 2;
            elseif (strcmpi(key_pressed, 'p') == 1)
                handles.selected_color = 3;
            elseif (strcmpi(key_pressed, 's') == 1)
                handles.selected_color = 4;
            elseif (strcmpi(key_pressed, 'f') == 1)
                handles.selected_color = 5;
            elseif (strcmpi(key_pressed, 'h') == 1)
                handles.selected_color = 6;
            elseif (strcmpi(key_pressed, 'k') == 1)
                handles.selected_color = 7;
            elseif (strcmpi(key_pressed, 'n') == 1)
                handles.selected_color = 8;
            end
            
            %Lets fill in the selected area of the map with that item
            if (handles.selected_color > 0)
                %Save the selected value to the specified field for this coordinate.
                val = char(handles.body_regions(handles.selected_color));
                handles.map{handles.current_xy(1),handles.current_xy(2)} = val;
                set(handles.tiles(handles.current_xy(1),handles.current_xy(2)),...
                    'userdata',handles.colors(handles.selected_color, :));
            end
        end

        %Update the map coordinate
        handles.current_xy = xy;
        
        %Update the map
        UpdateMap(handles);
    end

end

guidata(hObject, handles);

%% This function executes when the user presses a mouse button on the figure.
function ButtonDown(hObject,eventdata)
handles = guidata(hObject);                                                 %Grab the handles structure from the GUI.
xy = get(handles.axes,'currentpoint');                                      %Find the xy coordinates of where the user clicked on the GUI.
xy = round(2*xy(1,1:2))/2;                                                  %Round the xy coordinates to the nearest half millimeter.
i = find(xy(1) == handles.x);                                               %Find the index for the rounded x-value.
j = find(xy(2) == handles.y);                                               %Find the index for the rounded y-value.
if ~isempty(i) && ~isempty(j)                                               %If an index was found for the clicked coordinate.
    if ~isfield(handles,'current_xy');                                      %If this is the first clicked indices...
        set(vertcat(handles.depthbutton, handles.ampbutton,...
            handles.bodybutton, handles.savebutton,...
            handles.blindbutton, handles.editnotes),'enable','on');         %Enable all uicontrols.
    end
    handles.current_xy = [i,j];                                             %Save the indices.
    UpdateMap(handles);                                                     %Update the motor map.
end
guidata(hObject,handles);                                                   %Send the handles structure back to the GUI.


%% This function executes when the user presses a variable button.
function var_select(hObject,eventdata,field,val)           
handles = guidata(hObject);                                                 %Grab the handles structure from the GUI.
handles.(field){handles.current_xy(1),handles.current_xy(2)} = val;         %Save the selected value to the specified field for this coordinate.
if strcmpi(field,'map')                                                     %If the user selected a body region.
    set(handles.tiles(handles.current_xy(1),handles.current_xy(2)),...
        'userdata',get(hObject,'backgroundcolor'));                         %Color the tile the same color as the button.
end
UpdateMap(handles);                                                         %Redraw the motor map.
guidata(hObject,handles);                                                   %Resave the handles structure back to the GUI.


%% This function draws the initial motor map in the figure's axes.
function handles = DrawMap(handles)
set(handles.axes,'xdir','reverse','visible','off');                         %Reverse the direction of the x-axis and make it invisible.
hold(handles.axes,'on');                                                    %Hold the axes for multiple plots.
handles.x_label = nan(length(handles.x),1);                                 %Pre-allocate a matrix to hold the x-axis labels.
for i = 1:length(handles.x)                                                 %Step through the x-axis steps.
    line(handles.x(i)*[1,1]-0.25,handles.y([1,end])+[-0.25,0.25],...
        'color','k','linewidth',0.5,'linestyle',':');                       %Draw gridlines at each x-axis step.
    handles.x_label(i) = text(handles.x(i),handles.y(1)-0.3,...
        num2str(handles.x(i),'%1.1f'),'color','k',...
        'fontsize',0.5*handles.fontsize,'verticalalignment','top',...
        'horizontalalignment','center');                                    %Label each gridline.
end
line(handles.x(end)*[1,1]+0.25,handles.y([1,end])+[-0.25,0.25],...
    'color','k','linewidth',0.5,'linestyle',':');                           %Draw the gridline at the last x-axis step.
handles.y_label = nan(length(handles.y),1);                                 %Pre-allocate a matrix to hold the y-axis labels.
for i = 1:length(handles.y)                                                 %Step through the y-axis steps.
    line(handles.x([1,end])+[-0.25,0.25],handles.y(i)*[1,1]-0.25,...
        'color','k','linewidth',0.5,'linestyle',':');                       %Draw gridlines at each y-axis step.
    handles.y_label(i) = text(handles.x(end)+0.3,handles.y(i),...
        num2str(handles.y(i),'%1.1f'),'color','k',...
        'fontsize',0.5*handles.fontsize,'verticalalignment','middle',...
        'horizontalalignment','right');                                     %Label each gridline.
end
line(handles.x([1,end])+[-0.25,0.25],handles.y(end)*[1,1]+0.25,...
    'color','k','linewidth',0.5,'linestyle',':');                           %Draw the gridlines at the last y-axis step.
handles.tiles = nan(length(handles.x),length(handles.y));                   %Pre-allocate a matrix to hold the patch object handles.
handles.amptxt = nan(length(handles.x),length(handles.y));                  %Pre-allocate a matrix to hold the amplitude text handles.
handles.depthtxt = nan(length(handles.x),length(handles.y));                %Pre-allocate a matrix to hold the depth text label handles.
for i = 1:length(handles.x);                                                %Step through each x-axis step.
    for j = 1:length(handles.y);                                            %Step through each y-axis step.
        handles.tiles(i,j) = fill(handles.x(i)+0.25*[1,1,-1,-1],...
            handles.y(j)+0.25*[1,-1,-1,1],...
            'w','edgecolor','k','linewidth',0.5,'visible','off');           %Create a patch object for each grid tile.
        handles.depthtxt(i,j) = text(handles.x(i),handles.y(j)+0.2,...
            '','color','k','fontsize',0.5*handles.fontsize,...
            'verticalalignment','top','horizontalalignment','center');      %Label the stimulation depth on each tile.
        handles.amptxt(i,j) = text(handles.x(i),handles.y(j)-0.2,...
            '','color','k','fontsize',0.5*handles.fontsize,...
            'verticalalignment','bottom','horizontalalignment','center');   %Label the stimulation amplitude on each tile.
    end
end
text(handles.x(1)-0.3,mean(handles.y),'< Caudal    -    Rostral >',...
    'fontsize',handles.fontsize,'rotation',90,...
    'verticalalignment','top','horizontalalignment','center');              %Label the y-axis.
text(mean(handles.x),handles.y(end)+0.3,'< Lateral    -    Medial >',...
    'fontsize',handles.fontsize,'verticalalignment','bottom',...
    'horizontalalignment','center');                                        %Label the x-axis.
drawnow;                                                                    %Update the axes.
objs = get(handles.axes,'children');                                        %Grab all children of the axes.
xy = [0, 0; 0, 0];                                                          %Keep track of the minimum and maximum x- and y-values.
for i = 1:length(objs)                                                      %Step through all of the axes' children.
    if strcmpi(get(objs(i),'type'),'line')                                  %If the object is a line...
        xy(1,1) = min([xy(1,1), get(objs(i),'xdata')]);                     %Adjust the minimum x-value.
        xy(1,2) = max([xy(1,2), get(objs(i),'xdata')]);                     %Adjust the maximum x-value.
        xy(2,1) = min([xy(2,1), get(objs(i),'ydata')]);                     %Adjust the minimum y-value.
        xy(2,2) = max([xy(2,2), get(objs(i),'ydata')]);                     %Adjust the maximum y-value.
    elseif strcmpi(get(objs(i),'type'),'text')                              %Otherwise, if the object is text...
    	temp = get(objs(i),'extent');                                       %Grab the extent of the text object.
        xy(1,1) = min([xy(1,1), temp(1), temp(1) - temp(3)]);               %Adjust the minimum x-value.
        xy(1,2) = max([xy(1,2), sum(temp([1,3]))]);                         %Adjust the maximum x-value.
        xy(2,1) = min([xy(2,1), temp(2)]);                                  %Adjust the minimum y-value.
        xy(2,2) = max([xy(2,2), sum(temp([2,4]))]);                         %Adjust the maximum y-value.
    end
end
set(handles.axes,'xlim',xy(1,:) + [-0.1,0.1],...
    'ylim',xy(2,:) + [-0.1,0.1]);                                           %Set the y- and x-axis limits of the axes.
xy = range(xy(1,:))/range(xy(2,:));                                         %Calculate the x- to y-axis ratio.
pos = get(handles.axes,'position');                                         %Grab the axes position.
pos(3) = xy*pos(4);                                                         %Scale the width to the height by the calculated ration.
set(handles.axes,'position',pos);                                           %Adjust the position of the axes.
drawnow;                                                                    %Update the axes.


%% This function updates the motor map in the figure's axes.
function UpdateMap(handles)
a = handles.current_xy(1);                                                  %Grab the x-value index.
b = handles.current_xy(2);                                                  %Grab the y-value index.
set(handles.fig,'currentaxes',handles.axes);                                %Set the current axes to the figure axes.
fontsize = min(cell2mat(get(handles.x_label,'fontsize')));                  %Grab the current fontsize for all axis labels.
set(vertcat(handles.x_label,handles.y_label),'fontweight','normal',...
    'fontsize',fontsize,'edgecolor','none');                                %Set all x- and y-axis labels to normal fontweight and fontsize
set([handles.x_label(a), handles.y_label(b)],'fontweight','bold',...
    'fontsize',1.5*fontsize,'edgecolor','r','margin',2,'linewidth',2);      %Set the x- and y-axis label for the selected tile to bold fontweight and bigger font.
set(handles.tiles,'visible','off');                                         %Make all tiles invisible by default.
for i = 1:length(handles.x)                                                 %Step through the tiles by column.
    for j = 1:length(handles.y)                                             %Step through the tiles by row.
        if ~isempty(handles.map{i,j})                                       %If there's a body region set for this coordinate...
            if handles.blind == 0 || ...
                    strcmpi(handles.map{i,j},'No Response')                 %If we're not blinded or there was a response at this coordinate...
try
                set(handles.tiles(i,j),'visible','on',...
                    'facecolor',get(handles.tiles(i,j),'userdata'));        %Set the color of the tile.
catch
    e
end
            else                                                            %Otherwise, if we are blinded...
                set(handles.tiles(i,j),'facecolor',[0.5 0.5 0.5],...
                    'visible','on');                                        %Color the tile gray.
            end
        end
        if ~isempty(handles.depths{i,j})                                    %If there's a depth set for this coordinate...
            set(handles.depthtxt(i,j),'string',handles.depths{i,j});        %Show the depth in the text object.
        end
        if ~isempty(handles.amps{i,j})                                      %If there's an amplitude set for this coordinate...
            set(handles.amptxt(i,j),'string',handles.amps{i,j});            %Show the amplitude in the text object.
        end
    end
end
set(handles.tiles,'linewidth',0.5,'edgecolor','k');                         %Set all tiles to have a black edge.
set(handles.tiles(a,b),'linewidth',2,'edgecolor','r','visible','on');       %Set the currently selected tile to have a thick red edge.
uistack([handles.depthtxt(a,b),handles.amptxt(a,b),handles.tiles(a,b)],...
    'top');                                                                 %Move the currently selected tile to the top of the stack.
set(handles.editnotes,'string',handles.notes{a,b});                         %Show the notes for this site in the editbox.


%% This function executes whenever the user enters notes into the notes editbox.
function EditNotes(hObject,eventdata)
handles = guidata(hObject);                                                 %Grab the handles structure from the GUI.
handles.notes{handles.current_xy(1),handles.current_xy(2)} = ...
    get(hObject,'string');                                                  %Save the text entered into the editbox.
guidata(hObject,handles);                                                   %Resave the handles structure back to the GUI.


%% This function executes whenever the user presses the Blind/Unblind button.
function Blind(hObject,eventdata)
handles = guidata(hObject);                                                 %Grab the handles structure from the GUI.
if handles.blind == 0                                                       %If we're not currently blinded...
    handles.blind = 1;                                                      %Set the blind field to 1.
    set(handles.blindbutton,'string','Unblind');                            %Set the string on the blind button to "Blind".
else                                                                        %Otherwise...
    handles.blind = 0;                                                      %Set the blind field to zero.
    set(handles.blindbutton,'string','Blind');                              %Set the string on the blind button to "Blind".
end
UpdateMap(handles);                                                         %Update the map.
guidata(hObject,handles);                                                   %Resave the handles structure back to the GUI.


%% This function executes when the user hits the "Save Data" Button.
function SaveData(hObject,eventdata)
handles = guidata(hObject);                                                 %Grab the handles structure from the GUI.
ratname = inputdlg('What is this rat''s name?','Rat Name');                 %Ask the user what the rat's name is.
if isempty(ratname)                                                         %If the didn't enter a rat name.
    warndlg('YOU MUST SPECIFY A RAT NAME TO SAVE THE DATA!',...
        'NO NAME ENTERED!');                                                %Show a warning dialog.
    return                                                                  %Skip execution of the rest of the function
end
filename = ['MAP_' upper(ratname{1}) '_' datestr(now,'yyyyddmm')];          %Create a filename from the rat's name.
[filename,savepath] = uiputfile({'*.txt','Text File (*.txt)'},...
    'Save Motor Map as Text Data',[pwd '\' filename]);                      %Show the user a dialog box to confirm the data directory.
if filename(1) ~= 0                                                         %If the subject entered a filename...
    fid = fopen([savepath '\' filename],'wt');                              %Open a binary file for text writing.
    fprintf(fid,'%s\t','medial-lateral_(mm)');                              %Write the column #1 label.
    fprintf(fid,'%s\t','rostral-caudal_(mm)');                              %Write the column #2 label.
    fprintf(fid,'%s\t','current_amplitude_(uV)');                           %Write the column #3 label.
    fprintf(fid,'%s\t','depth_(mm)');                                       %Write the column #4 label.
    fprintf(fid,'%s\t','activated_body_region');                            %Write the column #5 label.
    fprintf(fid,'%s\n','notes');                                            %Write the column #6 label.
    figtext = {'Notes:'};                                                   %Create a cell array to hold text and notes for each tile.
    for i = 1:size(handles.map,1)                                           %Step through the map horizontally.
        for j = 1:size(handles.map,2)                                       %Step through the map vertically.
            if ~isempty(handles.depths{i,j}) || ...
                    ~isempty(handles.amps{i,j})  || ...
                    ~isempty(handles.map{i,j})                              %If there's any data for this coordinate.
                fprintf(fid,'%2.1f\t',handles.x(i));                        %Write column #1: x coordinate (medial-lateral).
                fprintf(fid,'%2.1f\t',handles.y(j));                        %Write column #2: y coordinate (rostral-caudal).
                if ~isempty(handles.amps{i,j})                              %If there's amplitude data for this coordinate...
                    fprintf(fid,'%s\t',handles.amps{i,j});                  %Write column #3: current amplitude (uV).
                else                                                        %Otherwise, if there's no amplitude data for this coordinate...
                    fprintf(fid,'%s\t','NaN');                              %Write a NaN placeholder in column #3.
                end
                if ~isempty(handles.depths{i,j})                            %If there's depth data for this coordinate...
                    fprintf(fid,'%s\t',handles.depths{i,j});                %Write column #4: stimulation depth (um).
                else                                                        %Otherwise, if there's no amplitude data for this coordinate.
                    fprintf(fid,'%s\t','NaN');                              %Write a NaN placeholder in column #4.
                end
                if ~isempty(handles.map{i,j})                               %If there's body region map data for this coordinate...
                    fprintf(fid,'%s\t',handles.map{i,j});                   %Write column #5: body region activated.
                else                                                        %Otherwise, if there's no amplitude data for this coordinate.
                    fprintf(fid,'%s\t','NaN');                              %Write a NaN placeholder in column #5.
                end
                if ~isempty(handles.notes{i,j})                             %If there's notesfor this coordinate...
                    fprintf(fid,'%s\n',handles.map{i,j});                   %Write column #6: notes.
                else                                                        %Otherwise, if there's no notes for this coordinate.
                    fprintf(fid,'\n');                                      %Simply print a carriage return.
                end
            end
            if ~isempty(handles.notes{i,j})                                 %If there's body region map data for this coordinate...
                figtext{end+1} = ['(' num2str(handles.x(i),'%2.1f')...
                    'mm,' num2str(handles.y(j),'%2.1f') 'mm): ' ...
                    handles.notes{i,j}];                                    %Add the x- and y-coordinates to the text.
            end
        end
    end
    fclose(fid);                                                            %Close the text file.
    temp = handles;                                                         %Copy the handles structure to a temporary matrix.
    temp.blind = 0;                                                         %Don't blind the printed map.
    temp.fig = figure('units','inches',...
        'Position',[0.5,0.25,10,8],...
        'name','Motor Map PDF',...
        'numbertitle','off',...
        'color','w',...
        'papersize',[11,8.5],...
        'paperposition',[0.5,0.25,10,8]);                                   %Create a temporary figure.
    temp.axes = axes('parent',temp.fig,'position',[0 0 1 1],...
        'visible','off');                                                   %Draw axes on the temporary figure.
    temp = DrawMap(temp);                                                   %Create the initial map.
    for i = 1:length(handles.x)                                             %Step through each tile column.
        for j = 1:length(handles.y)                                         %Step through each tile row.
            set(temp.tiles(i,j),'userdata',...
                get(handles.tiles(i,j),'userdata'));                        %Match the 'UserData' property of the tiles between the two figures.
        end
    end
    UpdateMap(temp);                                                        %Update the map.
    set(temp.tiles,'linewidth',0.5,'edgecolor','k');                        %Set all tiles to have a black edge.
    fontsize = min(cell2mat(get(temp.x_label,'fontsize')));                 %Grab the current fontsize for all axis labels.
    set(vertcat(temp.x_label,temp.y_label),'fontweight','normal',...
        'fontsize',fontsize,'edgecolor','none');                            %Set all x- and y-axis labels to normal fontweight and fontsize.
    set(temp.axes,'position',[0,0,1,1]);                                    %Re-expand the axes.
    objs = get(temp.axes,'children');                                       %Grab all children of the axes.
    objs(~strcmpi(get(objs,'type'),'text')) = [];                           %Kick out all non-text objects.
    xy = [0, 0; 0, 0];                                                      %Keep track of the minimum and maximum x- and y-values.
    for i = 1:length(objs)                                                  %Step through all of the axes' children.
        pos = get(objs(i),'extent');                                        %Grab the extent of the text object.
        xy(1,1) = min([xy(1,1), pos(1), pos(1) - pos(3)]);                  %Adjust the minimum x-value.
        xy(1,2) = max([xy(1,2), sum(pos([1,3]))]);                          %Adjust the maximum x-value.
        xy(2,1) = min([xy(2,1), pos(2)]);                                   %Adjust the minimum y-value.
        xy(2,2) = max([xy(2,2), sum(pos([2,4]))]);                          %Adjust the maximum y-value.
    end    
    if length(figtext) > 1                                                  %If there's any notes...
        text(xy(1,1)-0.25,xy(2,2),figtext,...
            'horizontalalignment','left','verticalalignment','top',...
            'fontsize',0.75*temp.fontsize);                                 %Show the notes to the right of the figure.
    end
    regions = {'Vibrissa','Distal Forelimb','Proximal Forelimb',...
        'Shoulder','Face','Hindlimb','Neck','No Response'};                 %List the possible activated body regions.
    colors = jet(length(regions));                                          %Create unique colors for each body region.
    colors(handles.colors ~= 1) = colors(handles.colors ~= 1) + ...
        0.5*(1 - colors(colors ~= 1));                                      %Lighten all of the layer colors.        
    colors(end,:) = [0 0 0];                                                %Make the last region color gray for "No Response".
    for i = 1:length(regions)                                               %Step through each body region.
        fill(xy(1,1)-0.25-0.4*[1 1 0 0 1],xy(2,1) + 0.35*[0 1 1 0 0] + ...
            (length(regions)-i)*0.4,colors(i,:));                           %Create tiles to show a color key.
        text(xy(1,1)-0.8,xy(2,1)+0.2+0.4*(length(regions)-i),regions{i},...
            'horizontalalignment','left','verticalalignment','middle',...
            'fontsize',0.75*temp.fontsize);                                 %Label each box.
    end
    set(temp.axes,'ylim',xy(2,:) + [-0.1,0.1],...
        'xlim',[xy(1,2)+0.1-10*(range(xy(2,:)+0.2))/8, xy(1,2)+0.1]);       %Set the y- and x-axis limits of the axes.
	drawnow;                                                                %Update the figure immediately.
    print(temp.fig,[savepath '\' filename(1:end-4)],'-dpdf');               %Save the current image as a PDF file.
    pause(0.5);                                                             %Pause for half a second.
else                                                                        %If the user didn't enter a filename...
    warndlg('YOU DIDN''T ENTER A FILENAME! THE DATA IS NOT SAVED!',...
        'DATA NOT SAVED!');                                                 %Show a warning dialog.
end


%% This function executes when the user resizes the figure.
function Resize(hObject,eventdata)
handles = guidata(hObject);                                                 %Grab the handles structure from the GUI.
ratio = handles.pos(3)/handles.pos(4);                                      %Calculate the original height to width ratio.
pos = get(handles.fig,'position');                                          %Grab the new figure position.
if handles.pos(4) ~= pos(4)                                                 %If the user changed the height.
    pos(3) = pos(4)*ratio;                                                  %Scale the width by the height.
else                                                                        %Otherwise...
    pos(4) = pos(3)/ratio;                                                  %Scale the height by the width.
end
set(handles.fig,'position',pos);                                            %Apply the scaled position to the figure.
handles.pos = pos;                                                          %Save the new position.
ratio = 0.6*pos(4)/handles.fontsize;                                        %Calculate ratio of the new fontsize to the old.
objs = get(handles.axes,'children');                                        %Grab all children of the axes.
objs(~strcmpi(get(objs,'type'),'text')) = [];                               %Kick out all non-text objects.
for i = 1:length(objs)                                                      %Step through each object.
    set(objs(i),'fontsize',ratio*get(objs(i),'fontsize'));                  %Reset the fontsize on all axes text objects.
end
handles.fontsize = 0.6*pos(4);                                              %Set the fontsize for all uicontrols.
objs = get(handles.fig,'children');                                         %Grab all the children of the figure.
set(objs(strcmpi(get(objs,'type'),'uicontrol') | ...
    strcmpi(get(objs,'type'),'uipanel')),'fontsize',handles.fontsize);      %Reset the fontsize of all uicontrols to the specified.
objs(~strcmpi(get(objs,'type'),'uipanel')) = [];                            %Kick out all non-uipanel objects.
for i = 1:length(objs)                                                      %Step through each object.
    set(get(objs(i),'children'),'fontsize',handles.fontsize);               %Reset the fontsize on all panel buttons.
end
objs = vertcat(get(objs(strcmpi(get(objs,'type'),'uipanel')),'children'));
guidata(hObject,handles);                                                   %Resave the handles structure back to the GUI.

%% This function loads a saved map
function LoadMap (hObject, eventdata)

handles = guidata(hObject);

%handles = DrawMap(handles);

[file path] = uigetfile('*.txt');
saved_map = ReadMotorMap([path file]);

body_regions = {'Vibrissa','Distal Forelimb','Proximal Forelimb',...
    'Shoulder','Face','Hindlimb','Neck','No Response'};                     %List the possible activated body regions.

for i = 1:size(saved_map.map, 1)
    for j = 1:size(saved_map.map, 2)
        
        index = saved_map.map(i,j);
        if (isscalar(index) && ~isnan(index))
            label = saved_map.body_labels{index};
            
            saved_x = saved_map.x_steps(i);
            saved_y = saved_map.y_steps(j);
            new_x = find(handles.x == saved_x, 1, 'first');
            new_y = find(handles.y == saved_y, 1, 'first');
            
            handles.map{new_x, new_y} = label;

            body_region_color = find(strcmpi(body_regions, label) == 1, 1, 'first');
            set(handles.tiles(new_x,new_y),'userdata',handles.colors(body_region_color, :));

            handles.amps{new_x, new_y} = saved_map.amps(i, j);
            handles.depths{new_x, new_y} = saved_map.depths(i, j);
        end
        
    end
end

handles.current_xy(1) = 1;
handles.current_xy(2) = 1;

set(vertcat(handles.depthbutton, handles.ampbutton,...
            handles.bodybutton, handles.savebutton,...
            handles.blindbutton, handles.editnotes),'enable','on');

UpdateMap(handles);

guidata(hObject,handles);
















