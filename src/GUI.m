function varargout = GUI(varargin)
% GUI MATLAB code for GUI.fig
%      GUI, by itself, creates a new GUI or raises the existing
%      singleton*.
%
%      H = GUI returns the handle to a new GUI or the handle to
%      the existing singleton*.
%
%      GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI.M with the given input arguments.
%
%      GUI('Property','Value',...) creates a new GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to runbutton (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GUI

% Last Modified by GUIDE v2.5 23-May-2020 03:27:00

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @GUI_OpeningFcn, ...
    'gui_OutputFcn',  @GUI_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before GUI is made visible.
function GUI_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GUI (see VARARGIN)

% movegui('center');
hObject.WindowState = 'maximized';

set(handles.selectedIm, 'visible', 'off');
set(handles.segIm, 'visible', 'off');
setappdata(handles.selectedIm, 'cs', 0);
setappdata(handles.selectedIm, 'rs', 0);
set(handles.drawButton, 'enable', 'off');
set(handles.radiusSlider, 'enable', 'off');
setappdata(handles.figure1, 'imgLoaded', false);
setappdata(handles.figure1, 'nOL', 3);

% show reminder
remindTxt = 'Load an image to start';
set(handles.remindStr, 'String', remindTxt);

% Choose default command line output for GUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GUI_OutputFcn(~, ~, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function roiRButton_Callback(~, eventdata, handles)
remindTxt = 'Press the CROP IMAGE to get the roi NOW';
set(handles.remindStr, 'String', remindTxt);


function runButton_Callback(hObject, ~, handles)

if ~isempty(getappdata(handles.selectedIm, 'image'))
    remindTxt = 'Please wait while running';
    set(handles.remindStr, 'String', remindTxt);
    setappdata(handles.figure1, 'useKMeans', false);
    votes = 4;
    
    % get the image
    img = getappdata(handles.selectedIm, 'image');
    
    % preprocess
    option = [get(handles.openDisableCheckbox, 'Value'),...
        get(handles.openRadiusSlider, 'Value')];
    img = preprocess(img, option);
    
    % segmentation & show segmented image
    if get(handles.clusterRButton, 'value')
        blockSize = [50 50];
        nOL = getappdata(handles.figure1, 'nOL');
        %         imgSeg = kmeansCluster(img,blockSize, nOL,tVote);
        [ballotBox1,ballotBox2] = vote(img,blockSize,nOL,get(handles.autoThreshCheckbox,'Value'));
        imgSeg1 = false(size(ballotBox1)); imgSeg2 = imgSeg1;
        imgSeg1(ballotBox1 >= votes) = 1;
        imgSeg2(ballotBox2 >= votes) = 1;
        imgSeg = imgSeg1&imgSeg2;
        setappdata(handles.figure1, 'ballotBox1', ballotBox1);
        setappdata(handles.figure1, 'ballotBox2', ballotBox2);
        setappdata(handles.figure1, 'useKMeans', true);
    else
        set(handles.remindStr, 'String', 'Computing...'); drawnow;
        imgSeg = otsuBinarize(img);
    end
    
    if get(handles.semiAutoRButton, 'value')
        % Overlay the image
        mask = getappdata(handles.selectedIm, 'mask');
        circles = getappdata(handles.selectedIm, 'l_cs');
        num_p = size(circles, 1);
        circles_x = circles(1:num_p,1);
        circles_y = circles(1:num_p,2);
        circles_r = getappdata(handles.selectedIm, 'l_rs');
        [imgx, imgy] = size(img);
        overlayIm = zeros(imgx, imgy);
        [cols, rows] = meshgrid(1:imgx,1:imgy);
        for i = 1 : num_p
            overlayIm = overlayIm | logical((rows-circles_x(i)).^2 + (cols - circles_y(i)).^2 <= circles_r(i).^2)';
        end
        overlayIm = overlayIm & mask;
        imgSeg = imgSeg & (~mask) | overlayIm;
    end
    
    % Display the results
    axes(handles.segIm);
    image2 = imshow(imgSeg, 'Parent', handles.segIm); impixelinfo; drawnow;
    setappdata(handles.segIm, 'imgSeg', imgSeg);
    set(image2,'ButtonDownFcn',{@segIm_ButtonDownFcn, handles});
    
    if strcmp(get(handles.CompareTool, 'State'), 'on')
        point = getappdata(handles.figure1, 'comparingCircleCenter');
        if ~isempty(point)
            circleB = viscircles(point, (handles.segIm.XLim(2)-handles.segIm.XLim(1))/22, 'Color', 'r'); drawnow;
            circleCompared = getappdata(handles.figure1, 'circleCompared');
            setappdata(handles.figure1, 'circleCompared', {circleCompared{1}, circleB});
        end
    end
    
    % Count using Cell Size Estimation
    set(handles.remindStr, 'String', 'Counting...');
    set(handles.result1Str, 'String', '...'); drawnow;
    [numMin,numMax] = colonyCount(imgSeg);
    str1 = [num2str(round(numMin)), ' to ',  num2str(round(numMax))];
    
    set(handles.result1Str, 'String', str1);
    set(handles.remindStr, 'String', 'Finished');
    set(gca,{'xlim','ylim'}, getappdata(handles.figure1, 'original_zoom_level'))
    
    % Disable voteSlider when uses Otsu
    if getappdata(handles.figure1, 'useKMeans')
        status = 'on';
    else
        status = 'off';
    end
    set(handles.voteSlider, 'Visible', status);
    set(handles.voteSlider, 'Value', votes);
    set(handles.voteText, 'Visible', status);
    set(handles.voteText, 'String', ['Threshold of Votes = ' num2str(votes)]);
    
    set(handles.recountButton, 'Visible', 'off');
end


function SaveFig_Callback(hObject, eventdata, handles)
[fname, pname] = uiputfile('*.fig');

if ~(isequal(fname, 0) || isequal(pname, 0))
    saveas(gcf, fullfile(pname,fname));
end

function Save_Callback(hObject, eventdata, handles)


function SaveSegIm_Callback(hObject, eventdata, handles)
imgSeg = getimage(handles.segIm);
if ~isempty(imgSeg)
    [fname, pname] = uiputfile('*.bmp;*.jpg;*.png;*.jpeg;*.tif');
    if ~(isequal(fname, 0) || isequal(pname, 0))
        imwrite(imgSeg, fullfile(pname, fname));
    end
else
    warndlg('No segmented image found!');
end

function SaveSelectedIm_Callback(hObject, eventdata, handles)
if ~isempty(getappdata(handles.selectedIm, 'image'))
    [fname, pname] = uiputfile('*.bmp;*.jpg;*.png;*.jpeg;*.tif');
    if ~(isequal(fname, 0) || isequal(pname, 0))
        imwrite(getimage(handles.selectedIm), fullfile(pname, fname));
    end
else
    warndlg('No selected image found!');
end


function cropButton_Callback(hObject, eventdata, handles)
img = getappdata(handles.selectedIm, 'image');
img_ori = getappdata(handles.selectedIm, 'oriIm');
if ~isempty(img)
    % Whole image button not selected
    if get(handles.roiRButton, 'value')
        % ROI radio button selected
        roi = drawcircle();
        setappdata(handles.selectedIm, 'radius', []);
        setappdata(handles.selectedIm, 'center', []);
        remindTxt = 'select the ROI and DOUBLE CLICK to crop';
        set(handles.remindStr, 'String', remindTxt);
    else
        % Auto Detection radio button selected
        [center, radius, rect] = dishSeg(img);
        img = imcrop(img, rect);
        img_ori = imcrop(img_ori, rect);
        setappdata(handles.selectedIm, 'image', img);
        setappdata(handles.selectedIm, 'oriIm', img_ori);
        axes(handles.selectedIm); imshow(img_ori);
        roi = drawcircle('Center', center, 'Radius', radius);
        remindTxt = 'Adjust the ROI (or not) and DOUBLE CLICK to crop';
        set(handles.remindStr, 'String', remindTxt);
    end
    
    l = addlistener(roi,'ROIClicked', @(src,evt)roiSelect(src,evt,handles));
    uiwait(handles.figure1);
    delete(l);
    setappdata(handles.selectedIm, 'cs', 0);
    setappdata(handles.selectedIm, 'rs', 0);
    setappdata(handles.selectedIm, 'l_cs', []);
    setappdata(handles.selectedIm, 'l_rs', []);
    set(get(handles.segIm, 'children'), 'visible', 'off');
    set(handles.result1Str, 'String', []);
    
    set(handles.cropButton, 'enable', 'off');
    remindTxt = 'Choose the DEGREE';
    set(handles.remindStr, 'String', remindTxt);
end

function roiSelect(src,evt,varargin)
handles = varargin{1};
img = getappdata(handles.selectedIm, 'image');
img_ori = getappdata(handles.selectedIm, 'oriIm');
center = getappdata(handles.selectedIm, 'center');
radius = getappdata(handles.selectedIm, 'radius');
evname = evt.EventName;

switch(evname)
    case{'ROIClicked'}
        if isequal(center,src.Center) && isequal(radius,src.Radius)
            mask = createMask(src);
            img(~mask) = 0;
            rect = [src.Center(1)-src.Radius, src.Center(2)-src.Radius, src.Radius*2, src.Radius*2];
            img = imcrop(img, rect);
            img_ori = imcrop(img_ori, rect);
            setappdata(handles.selectedIm, 'image', img);
            setappdata(handles.selectedIm, 'oriIm', img_ori);
            axes(handles.selectedIm);
            image1 = imshow(img_ori,'Parent',handles.selectedIm);impixelinfo;
            viscircles(size(img_ori)/2, radius, 'Color', 'b');
            uiresume(handles.figure1);
            set(image1,'ButtonDownFcn',{@selectedIm_ButtonDownFcn,handles});
            setappdata(handles.figure1, 'original_zoom_level', get(gca,{'xlim','ylim'}));
            setappdata(handles.figure1, 'radius', radius);
        else
            setappdata(handles.selectedIm, 'center', src.Center);
            setappdata(handles.selectedIm, 'radius', src.Radius);
        end
end


function CellCir_ClickedCallback(hObject, eventdata, handles)
if strcmp(get(hObject,'State'),'on')
    set(handles.CompareTool, 'State', 'off');
    pan(handles.selectedIm,'off');
    zoom(handles.selectedIm,'off');
    set(handles.figure1, 'Pointer', 'custom', 'PointerShapeCData',...
        generate_pointer([16,16], get(handles.radiusSlider,...
        'Value')), 'PointerShapeHotSpot', [16,16]);
end


function CellCir_OffCallback(hObject, eventdata, handles)
set(handles.figure1, 'Pointer', 'arrow');

% --- Executes on mouse press over axes background.
function selectedIm_ButtonDownFcn(~, ~, handles)
if strcmp(get(handles.CompareTool, 'State'), 'on')
    point = get(handles.selectedIm,'CurrentPoint');
    point = point(1,1:2);
    setappdata(handles.figure1, 'comparingCircleCenter', point);
    circleCompared = getappdata(handles.figure1, 'circleCompared');
    if ~isempty(circleCompared)
        delete(circleCompared{1});
        delete(circleCompared{2});
    end
    circleA = viscircles(point, (handles.selectedIm.XLim(2)-handles.selectedIm.XLim(1))/22, 'Color', 'r');
    axes(handles.segIm);
    circleB = viscircles(point, (handles.segIm.XLim(2)-handles.segIm.XLim(1))/22, 'Color', 'r');
    setappdata(handles.figure1, 'circleCompared', {circleA, circleB});
end

if ~strcmp(get(handles.CellCir,'State'),'on')
    return;
end

% Start Labelling

c = getappdata(handles.selectedIm, 'c');
r = getappdata(handles.selectedIm, 'r');

if isempty(c) || isempty(r)
    % No ROI
    return
end

point = get(handles.selectedIm,'CurrentPoint');
point = point(1,1:2);
if (point(1)-c(1))^2 + (point(2)-c(2))^2 >= r^2
    return;
end
cs = getappdata(handles.selectedIm, 'l_cs');
rs = getappdata(handles.selectedIm, 'l_rs');
cs = [cs; point];

w = ceil(getpixelposition(handles.selectedIm));
w = w(3);
x = handles.selectedIm.XLim(2)-handles.selectedIm.XLim(1);
r_pointer = get(handles.radiusSlider, 'Value');
r_new = r_pointer * x / w;

rs = [rs r_new];
handles.v = viscircles(cs, rs, 'Color', 'b');
set(handles.v,'PickableParts','none');
setappdata(handles.selectedIm, 'l_cs', cs);
setappdata(handles.selectedIm, 'l_rs', rs);
set(handles.v,'HitTest','off');


function drawButton_Callback(hObject, eventdata, handles)
if ~isempty(getappdata(handles.selectedIm, 'image'))
    remindTxt = "Draw the ROI and Circle the cells using the CIRCLE IN TOOLBAR. Then RUN";
    set(handles.remindStr, 'String', remindTxt);
    roi = drawcircle();
    setappdata(handles.selectedIm, 'r', []);
    setappdata(handles.selectedIm, 'c', []);
    k = addlistener(roi,'ROIClicked', @(src,evt)roiDraw(src,evt,handles));
    uiwait(handles.figure1);
    delete(k);
end


function roiDraw(src,evt,varargin)
handles = varargin{1};
center = getappdata(handles.selectedIm, 'c');
radius = getappdata(handles.selectedIm, 'r');
evname = evt.EventName;

switch(evname)
    case{'ROIClicked'}
        if isequal(center,src.Center) && isequal(radius,src.Radius)
            mask = createMask(src);
            setappdata(handles.selectedIm, 'mask', mask);
            img = getappdata(handles.selectedIm,'image');
            img_ori = getappdata(handles.selectedIm, 'oriIm');
            if isequal(size(img), size(img_ori))
                % The image doesn't get cropped
                img = img_ori;
            end
            
            % Get previous zoom level
            zoom_level = get(gca,{'xlim','ylim'});
            
            uiresume(handles.figure1);
            image1 = imshow(img, 'Parent', handles.selectedIm);
            h = viscircles(center, radius);
            set(image1,'ButtonDownFcn',{@selectedIm_ButtonDownFcn,handles});
            set(h,'PickableParts','none');
            set(h,'HitTest','off');
            radius = getappdata(handles.figure1, 'radius');
            viscircles(size(img)/2, radius, 'Color', 'b');
            
            % Return to the previous zoom level
            set(gca,{'xlim','ylim'}, zoom_level)
        else
            setappdata(handles.selectedIm, 'c', src.Center);
            setappdata(handles.selectedIm, 'r', src.Radius);
        end
end


% --- Executes on slider movement.
function radiusSlider_Callback(hObject, eventdata, handles)
slider_value = get(hObject, 'Value');
set(handles.radiusText, 'String', ['Radius = ' num2str(slider_value)]);
set(handles.figure1, 'Pointer', 'custom', 'PointerShapeCData',...
    generate_pointer([16,16], get(handles.radiusSlider,...
    'Value')), 'PointerShapeHotSpot', [16,16]);
if strcmp(get(handles.CellCir,'State'),'off')
    set(handles.CellCir,'State','on')
end


% --- Executes during object creation, after setting all properties.
function radiusSlider_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
set(hObject, 'Min', 2);
set(hObject, 'Max', 15);
set(hObject, 'Value', 8);
set(hObject, 'SliderStep', [1/13 , 1/13]);


% --- Executes on button press in loadImButton.
function loadImButton_Callback(hObject, eventdata, handles)
remindTxt = 'Load an image to start';
set(handles.remindStr, 'String', remindTxt);
axes(handles.selectedIm);
[fname,pname] = uigetfile({'*.bmp;*.jpg;*.png;*.jpeg;*.tif'},...
    'Pick an image', '../data/');
str = [pname fname];
if isequal(fname, 0) || isequal(pname, 0)
    return;
else
    img_ori = imread(str);
    if size(img_ori,3) == 3
        img_ori = rgb2gray(img_ori);
    end
    setappdata(handles.selectedIm, 'oriIm', img_ori);
    setappdata(handles.selectedIm, 'cs', 0);
    setappdata(handles.selectedIm, 'rs', 0);
    setappdata(handles.selectedIm, 'l_cs', []);
    setappdata(handles.selectedIm, 'l_rs', []);
    set(handles.autoRButton, 'value', 1);
    set(handles.clusterRButton, 'value', 1);
    set(get(handles.segIm, 'children'), 'visible', 'off');
    set(handles.result1Str, 'String', []);
    set(handles.cropButton, 'enable', 'on');
    set(handles.drawButton, 'enable', 'off');
    set(handles.radiusSlider, 'enable', 'off');
    
    % Resize image width to 3120
    img_ori = imresize(img_ori, 3120 / size(img_ori,2));
    setappdata(handles.selectedIm, 'oriIm', img_ori);
    
    handles.image1 = imshow(img_ori,'Parent',handles.selectedIm); drawnow;
    
    % top-hat filtering
    se = strel('disk',90);
    img = imtophat(img_ori, se);
    setappdata(handles.selectedIm, 'image', img);
    
    %     setappdata(handles.selectedIm, 'image', img_ori);
    
    setappdata(handles.figure1, 'imgLoaded', true);
    setappdata(handles.figure1, 'original_zoom_level', get(gca,{'xlim','ylim'}));
    
    remindTxt = 'Press the CROP IMAGE Button NOW to get the ROI';
    set(handles.remindStr, 'String', remindTxt);
    set(handles.recountButton, 'Visible', 'off');
end


% --- Executes on button press in autoRButton.
function autoRButton_Callback(hObject, eventdata, handles)
set(handles.drawButton, 'enable', 'off');
set(handles.radiusSlider, 'enable', 'off');
remindTxt = 'Choose the METHOD and RUN';
set(handles.remindStr, 'String', remindTxt);

% --- Executes on button press in semiAutoRButton.
function semiAutoRButton_Callback(hObject, eventdata, handles)
if getappdata(handles.figure1, 'imgLoaded') == false
    return
end

set(handles.drawButton, 'enable', 'on');
set(handles.radiusSlider, 'enable', 'on');
remindTxt = 'Operate the LABEL MANUALLY section';
set(handles.remindStr, 'String', remindTxt);
set(handles.radiusText, 'String', ['Radius = ' num2str(get(handles.radiusSlider, 'Value'))]);


function AutoDetectionRButton_Callback(hObject, eventdata, handles)
remindTxt = 'Press the CROP IMAGE to get the roi NOW';
set(handles.remindStr, 'String', remindTxt);


% --- Executes on scroll wheel click while the figure is in focus.
function figure1_WindowScrollWheelFcn(hObject, eventdata, handles)
if ~strcmp(get(handles.radiusSlider, 'enable'), 'on')
    return
end

value = get(handles.radiusSlider, 'Value');

switch(eventdata.VerticalScrollCount)
    case -1
        % Mouse wheel roll up
        if value < get(handles.radiusSlider, 'Max')
            set(handles.radiusSlider, 'Value', value + 1);
            set(handles.radiusText, 'String', ['Radius = ' num2str(value+1)]);
        end
    case 1
        % Mouse wheel roll down
        if value > get(handles.radiusSlider, 'Min')
            set(handles.radiusSlider, 'Value', value - 1);
            set(handles.radiusText, 'String', ['Radius = ' num2str(value-1)]);
        end
end

if strcmp(get(handles.CellCir,'State'),'on')
    set(handles.figure1, 'Pointer', 'custom', 'PointerShapeCData',...
        generate_pointer([16,16], get(handles.radiusSlider,...
        'Value')), 'PointerShapeHotSpot', [16,16]);
end


% --- Executes on key press with focus on figure1 or any of its controls.
function figure1_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if ~strcmp(get(handles.radiusSlider, 'enable'), 'on')
    return
end

value = get(handles.radiusSlider, 'Value');

switch(eventdata.Key)
    case 'q'
        if value < get(handles.radiusSlider, 'Max')
            set(handles.radiusSlider, 'Value', value + 1);
            set(handles.radiusText, 'String', ['Radius = ' num2str(value+1)]);
        end
    case 'e'
        if value > get(handles.radiusSlider, 'Min')
            set(handles.radiusSlider, 'Value', value - 1);
            set(handles.radiusText, 'String', ['Radius = ' num2str(value-1)]);
        end
end

if strcmp(get(handles.CellCir,'State'),'on')
    set(handles.figure1, 'Pointer', 'custom', 'PointerShapeCData',...
        generate_pointer([16,16], get(handles.radiusSlider,...
        'Value')), 'PointerShapeHotSpot', [16,16]);
end


function voteSlider_Callback(hObject, eventdata, handles)
votes = get(hObject, 'Value');
set(handles.voteText, 'String', ['Threshold of Votes = ' num2str(votes)]);
ballotBox1 = getappdata(handles.figure1, 'ballotBox1');
ballotBox2 = getappdata(handles.figure1, 'ballotBox2');
imgSeg1 = false(size(ballotBox1)); imgSeg2 = imgSeg1;
imgSeg1(ballotBox1 >= votes) = 1;
imgSeg2(ballotBox2 >= votes) = 1;
imgSeg = imgSeg1 & imgSeg2;
% imgSeg = imerode(imgSeg, strel('disk',1));
axes(handles.segIm);
image2 = imshow(imgSeg, 'Parent', handles.segIm); impixelinfo;
set(image2,'ButtonDownFcn',{@segIm_ButtonDownFcn, handles});
setappdata(handles.segIm, 'imgSeg', imgSeg);
set(handles.recountButton, 'Visible', 'on');

if strcmp(get(handles.CompareTool, 'State'), 'on')
    % Redisplay comparing circle
    point = getappdata(handles.figure1, 'comparingCircleCenter');
    circleB = viscircles(point, (handles.segIm.XLim(2)-handles.segIm.XLim(1))/22, 'Color', 'r');
    circleCompared = getappdata(handles.figure1, 'circleCompared');
    setappdata(handles.figure1, 'circleCompared', {circleCompared{1}, circleB});
end


function voteSlider_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

set(hObject, 'Min', 1);
set(hObject, 'Max', 9);
set(hObject, 'Value', 4);
set(hObject, 'SliderStep', [1/8 , 1/8]);
set(hObject, 'Visible', 'off');


function CompareTool_OnCallback(hObject, eventdata, handles)
set(handles.CellCir, 'State', 'off');


function CompareTool_OffCallback(hObject, eventdata, handles)
circleCompared = getappdata(handles.figure1, 'circleCompared');
if ~isempty(circleCompared)
    delete(circleCompared{1});
    delete(circleCompared{2});
end


function segIm_ButtonDownFcn(~, ~, handles)
if strcmp(get(handles.CompareTool, 'State'), 'on')
    point = get(handles.segIm,'CurrentPoint');
    point = point(1,1:2);
    circleCompared = getappdata(handles.figure1, 'circleCompared');
    setappdata(handles.figure1, 'comparingCircleCenter', point);
    if ~isempty(circleCompared)
        delete(circleCompared{1});
        delete(circleCompared{2});
    end
    circleB = viscircles(point, (handles.segIm.XLim(2)-handles.segIm.XLim(1))/22, 'Color', 'r');
    axes(handles.selectedIm);
    circleA = viscircles(point, (handles.selectedIm.XLim(2)-handles.selectedIm.XLim(1))/22, 'Color', 'r');
    setappdata(handles.figure1, 'circleCompared', {circleA, circleB});
end


function recountButton_Callback(hObject, eventdata, handles)
set(handles.remindStr, 'String', 'Counting...');
set(handles.result1Str, 'String', '...'); drawnow;
[numMin,numMax] = colonyCount(getimage(handles.segIm));
set(handles.remindStr, 'String', 'Finished');
set(handles.result1Str, 'String', [num2str(round(numMin)), ' to ',  num2str(round(numMax))]);
set(hObject, 'Visible', 'off');


function clusterRButton_Callback(hObject, eventdata, handles)
set(handles.autoThreshCheckbox, 'Enable', 'on');


function threshRButton_Callback(hObject, eventdata, handles)
set(handles.autoThreshCheckbox, 'Enable', 'off');


function openDisableCheckbox_Callback(hObject, eventdata, handles)
if get(hObject, 'Value') ~= 0
    % Disable Opening
    set(handles.openRadiusSlider, 'Enable', 'off');
else
    set(handles.openRadiusSlider, 'Enable', 'on');
end


function openRadiusSlider_Callback(hObject, eventdata, handles)
radius = get(hObject, 'Value');
set(handles.openRadiusText, 'String', ['Radius = ' num2str(radius)]);


function openRadiusSlider_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

set(hObject, 'Min', 1);
set(hObject, 'Max', 7);
set(hObject, 'Value', 4);
set(hObject, 'SliderStep', [1/6 , 1/6]);
