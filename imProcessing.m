% Image processing script for particle/droplet analysis
% Author: E.J.G. Sewalt
% Creation date: 2020-21-02
%   Update: 2021-06-24 by E.J.G. Sewalt
% =============
%IMPROCESSING Droplet and particle velocimetry and morphometry script
%   imProcessing.m handles each aspect from the processing of a video, the
%   analysis of the images, and saving the resulting properties. The
%   regionprops module of MATLAB's ImageProcessing Toolbox is the core of
%   this script that handles the droplet/particle detection. Both grayscale
%   and RGB are supported. RGB videos are converted to grayscale for furter
%   processing.
%
%   Input and settings
%   ---------------
%   folder	-   Locate the folder that contains the .avi file, output of 
%               this script will also be stored there. Only the first .avi
%               file in the folder will be processed.
folder = 'C:\Users\esewalt\Documents\test';
%   scriptfolder	-   Locate the folder that contains the supporting 
%                   MATLAB scripts. (Default = '\Supplementary_scripts')
scriptfolder = '\Supplementary_scripts';
%   acqSet  -   Acquisition settings used for image acquisition from the 
%               .avi file. A [2 x 1] array that specifies the
%               start and end frame of the .avi file. (Default = [0, 512] 
%               - thus, starting at frame 0 until frame 512 frames, for a 
%               total of 512 frames)
acqSet = [3701, 4106];
%   imThresh    -   The frame number that is used for finding the 
%               thresholding value for binarization (Default = 1)
imThresh = 1;
%   frameTime   - Defines the framerate for converting frame number to
%               time. (Default = N/A.)
frameTime = 1/100;
%   horzIndent  -	The num of pixels objects should clear from the 
%               horizontal edges. This prevents detecting objects that are
%               only partially in the frame. (Default = 5)
horzIndent = 5; 
%   vertIndent  -	The num of pixels objects should clear from the
%               vertical edges This prevents detecting objects that are
%               only partially in the frame. (Default = 5)
vertIndent = 5; 
%
%   Detection parameters
%   ---------------
%   minObjectSize   -	Minimum size for found objects in px. If a detected
%                   object is smaller than the mean of the bouncingbox x 
%                   and y size it is taken out of the analysis. 
%                   (Default = N/A)
minObjectSize = 5; 
%   sizeMatchFactor -	Allowed area offset (in %) for recogniton of
%                   objects over multiple frames. A larger area difference
%                   between two objects will signal	that the two objects 
%                   are distinct. (Default = 10)
sizeMatchFactor = 10; 
%   distMatchFactor -	Allowed distance factor as factor of the mean of
%                   boundingbox. For recogniton of objects over multiple 
%                   frames. A larger distance between two object centroids 
%                   than the (DISTMATCHFACTOR * mean(BOUNDINGBOXSIZE))will 
%                   signal that the two objects are distinct. (Default = 1)
distMatchFactor = 1; 
%   Optional arguments
%   ---------------
%   importAvi   -	If 1, imports .AVI file and converts to images. 
%               If not 1, finds already saved images. (Default = 1)
importAvi = 1;
%   imgType     -	Image format for output images (Default = '.tiff')
imgType = '.tiff';
%   fileName    -	Filename for saved images (Default = 'image')
fileName = 'image';
%   invert      -   Inverts the intensity of the image (Objects should be 
%                   ligther than background) (Default = 0)
invert = 0;
%   showLiveImages  -  If 1, displays the images and acquired objects
%                   during acquisition. (Default = 1)
showLiveImages = 1;
% =============
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialize
addpath(genpath(scriptfolder))  % Supplementary script directory
cd(folder)  % DIR: .AVI directory

%% Acquire Images
% Get .avi
if importAvi == 1
    % Detect files
    files = dir(folder); % Detects all files in current directory
    % Find first .avi file
    j = 0; i = 0;
    while j == 0
    	i = i + 1;
        if (contains(files(i).name,'.avi'))
            file_avi = files(i);
            j = j + 1;
        end
        if i == length(files)
            j = j + 1;
        end
    end
    clear j i files scriptfolder % Cleanup
    % Convert to img
    [imgArray, ~] = Generate_img(file_avi.name,acqSet(1),acqSet(2)); % Generates images from selected .avi
    SaveImage(imgArray,strcat(folder,'/'),fileName,imgType);
end
% Acquire images from directory
if importAvi ~= 1
	try 
        imgArray = GetImagesFromFile(strcat(folder,'/',fileName),imgType);
    catch
        imageExpection = MException('imProcessing:BadIndex','No images found for importing');
        throw(imageExpection);
    end
end
imgArray = uint8(imgArray);

%% Pre-processing
% Select analysis region
figure; 
title('Select the measuring area');
hold on;
[~, rectBox] = imcrop(imgArray(:,:,1));
imgArray = uint8(CropImage(imgArray,rectBox)); close;

% Inversion if necessary
if invert == 1
    imgArray = 256 - imgArray;
end

% Optimize contrast
for i = 1:1:size(imgArray,3)
    imgArray(:,:,i) = imadjust(imgArray(:,:,i));
end

% Background removal
imgBackground = uint8(mean(imgArray,3));
imgArray = RemoveBackround(imgArray,imgBackground);

%% Binarization & perimeter detection
imgBIN = logical(false(size(imgArray,1),size(imgArray,2),size(imgArray,3))); % Allocate
objPerimeter = imgBIN; % Allocate
threshStart = graythresh(imgArray(:,:,imThresh));  % Compute first guess threshold using Otsu's method
threshold = FindThreshold(imgArray(:,:,imThresh),threshStart); % Find Threshold, takes image and starting threshold
for i = 1:1:size(imgArray,3)
   imgBIN(:,:,i) = imbinarize(imgArray(:,:,i),threshold); % Binarize the images
end
for i = 1:1:size(imgArray,3)
    imgBIN(:,:,i) = imfill(imgBIN(:,:,i),'holes'); % Fills holes in regions
end

%% Detection (with regionprops)
outputData = struct; first = true;
for i = 1:1:size(imgArray,3)
    objectsTemp = regionprops('struct',imgBIN(:,:,i),'Centroid','BoundingBox','Area'); % Determine object properties
    lim = size(objectsTemp,1);
    clearObj = false;
    for j = 1:1:lim
        k = lim-(j-1);
        % If object smaller than minimumsize, delete from array.
        if mean(objectsTemp(k).BoundingBox(3),objectsTemp(k).BoundingBox(4)) < minObjectSize
            clearObj = true;
        end
        % If object touches edges of measurement range, remove. (To prevent detecting particles only partly in sight)
        if (~clearObj)
            if (objectsTemp(k).Centroid(1) - 0.5*objectsTemp(k).BoundingBox(3)) <= horzIndent || (objectsTemp(k).Centroid(1) + 0.5*objectsTemp(k).BoundingBox(3)) >= size(imgBIN,2)-horzIndent
                clearObj = true;
            elseif (objectsTemp(k).Centroid(2) - 0.5*objectsTemp(k).BoundingBox(4)) <= vertIndent || (objectsTemp(k).Centroid(2) + 0.5*objectsTemp(k).BoundingBox(4)+3) >= size(imgBIN,1)-vertIndent
                clearObj = true;
            end
        end
        if clearObj
        	objectsTemp(k) = '';
            clearObj = false;
        end
    end
    %% Save to array files from objectsTemp, add time and frame number
    if size(objectsTemp,2) ~= 0 && size(objectsTemp,1) ~= 0
        j = 0; done = false;
        while ~done
            j = j + 1;
            if first
                outputData(end).numFrame = i;
                first = false;
            else
                outputData(end + 1).numFrame = i;
            end
            outputData(end).numTime = (i-1)*frameTime;
            outputData(end).DropID = 0;
            outputData(end).Centroid = objectsTemp(j).Centroid;
            outputData(end).BoundingBox = objectsTemp(j).BoundingBox;
            outputData(end).Area = objectsTemp(j).Area;
            outputData(end).Velocity = 0;
            if j == size(objectsTemp,1)
                done = true;
            end
        end
    end
    clear j k lim objectsTemp
end

%% Analysis
ObjException = MException('imProcessing:BadIndex','No objects detected for analysis. Please check the settings of MINOBJSIZE and whether thresholding has been done successfully');
try
    dropID = outputData(1).numFrame >= outputData(1).numFrame;
    clear dropID
catch causeExpection
    throw(ObjException)
end
dropID = 0;
dropIsMatch = false;
% for each frame number from 2 to end, check the previous frame and compare
for i = 1:1:size(outputData,2)
    dropID = dropID + 1;
    outputData(i).DropID = dropID;
    dropIsMatch = false;
    % find each object at previous frame (i-1);
    for j = 1:1:size(outputData,2)
        if outputData(j).numFrame >= outputData(i).numFrame
            break
        elseif outputData(j).numFrame == outputData(i).numFrame - 1
            % Check if matching size and distance
            if (outputData(i).Area > (1-(sizeMatchFactor/100))*outputData(j).Area) || (outputData(i).Area < (1+(sizeMatchFactor/100))*outputData(j).Area)
                xdis = abs(outputData(i).Centroid(1) - outputData(j).Centroid(1));
                ydis = abs(outputData(i).Centroid(2) - outputData(j).Centroid(2));
                if (sqrt(xdis^2+ydis^2) <= distMatchFactor*(mean(outputData(i).BoundingBox(3:4))))
                    dropIsMatch = true;
                end
            end
            break % Break and save j for dropmatching
        else
            continue
        end
    end
    if (dropIsMatch)
        outputData(i).DropID = outputData(j).DropID;
        dropID = dropID - 1;
        outputData(j).Velocity = sqrt(xdis^2+ydis^2)/frameTime; % Give velocity to previous droplet
        outputData(i).Velocity = NaN;
    else
        outputData(i).Velocity = NaN; % is not-a-number if no velocity detected
    end
    clear j 
end
close

%% Plotting
% Loop through images, plot image, plot objects
figure(1)
for i = 1:1:outputData(end).numFrame
    subplot(1,2,1);
    imshow(imgArray(:,:,i))
    title(strcat("Frame: ", num2str(i)));
    subplot(1,2,2);
    imshow(imgBIN(:,:,i))
    hold on 
    %% Find the objects in frame i
    x = 0;
    for j = 1:1:size(outputData,2)
        if outputData(j).numFrame > i
            break
        elseif outputData(j).numFrame == i
            r = rectangle('Position',outputData(j).BoundingBox);
            r.EdgeColor = 'green';
        else
            continue
        end
    end
    if showLiveImages == 1
        figure(1)
    end
    hold off
end

%% Make Table for saving
varNames = {'Frame','Time','DropID','MajorAxis','MinorAxis','Area','Velocity'};
T = table(outputData(1).numFrame,outputData(1).numTime,outputData(1).DropID,outputData(1).BoundingBox(3),outputData(1).BoundingBox(4),outputData(1).Area,outputData(1).Velocity,'Variablenames',varNames);
for i = 2:1:size(outputData,2)
   T1 = table(outputData(i).numFrame,outputData(i).numTime,outputData(i).DropID,outputData(i).BoundingBox(3),outputData(i).BoundingBox(4),outputData(i).Area,outputData(i).Velocity,'Variablenames',varNames);
   Tnew = [T;T1]; % Append table
   T = Tnew;
   clear T1 Tnew   
end
tableUnits = ["-","s","-","px","px","px","px2","px/s"]; % units
tableUnits = char(tableUnits);
if ~exist(strcat(folder,'\OUTPUT'), 'dir')
    mkdir(strcat(folder,'\OUTPUT'));
end
outputSheetFolder = strcat(folder,'\OUTPUT');
cd(outputSheetFolder);
sheetname = strcat(fileName,'_output');
writetable(T,sheetname);
% write units
f = fopen('TableUnits.txt','wt');
fwrite(f,tableUnits);
fclose(f);

close all
disp("done");

%% Supporting functions
function [images] = RemoveBackround(images,background)
% Removes the background 'background' from the image stack 'images'.
    for i = 1:1:size(images,3)
       images(:,:,i) = images(:,:,i) - background;
    end
end
function [croppedImages] = CropImage(images,box)
    % Crops the 'images' using the edges of 'box'
    b(1) = floor(box(1)); b(2) = floor(box(2)); b(3) = ceil(box(3)); b(4) = ceil(box(4));
    croppedImages = zeros(b(4)+1,b(3)+1,size(images,3));
    for i = 1:1:size(images,3)
        croppedImages(:,:,i) = images(b(2):(b(2)+b(4)),b(1):(b(1)+b(3)),i);
    end
end
function [threshold] = FindThreshold(image,threshold)
    found = false;
    while (~found)
        subplot(1,2,1)
        title('Grayscale image');
        imshow(image);
        subplot(1,2,2)
        title('Binarized image');
        imshow(imbinarize(image,threshold));
        if threshold <= 0.05 
            dlg = questdlg('Is the object recognizable?',...
            'Gray Level',...
            'OK', 'Too much white', 'OK');
        elseif threshold >= 0.95 
            dlg = questdlg('Is the object recognizable?',...
            'Gray Level',...
            'Too much black', 'OK', 'OK');
        else
            dlg = questdlg('Is the object recognizable?',...
            'Gray Level',...
            'Too much black', 'OK', 'Too much white', 'OK');
        end
        switch dlg
            case 'Too much black'
                threshold = threshold - 0.03;
            case 'Too much white'
                threshold = threshold + 0.03;
            case 'OK'
                found = true;
        end
    end
end

