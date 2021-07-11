%
% Generate_avi - Script to convert .avi into images
% Version      - V1.00
% Edits        - n.v.t.         
% 
% The .avi video is converted to the set image format.
%
% Input:    1. videoName: .avi video (or other, see "doc VideoReader").
%           2. startTime: The starting time in seconds of the video.
%           3. frameLength: The total number of frames starting from
%           startTime that is obtained. 
% Output: desired image format
% (https://nl.mathworks.com/help/matlab/ref/imwrite.html)
%
%   Author: E.J.G. Sewalt
%   Created: 2019-11-22
%   Update: 2020-02-06
    % Rewritten to a function instead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [imgArray, frameRate] = Generate_img(videoName,startFrame,frameLength)
%% for the entire video set 'startTime' to 0
    % Obtain and Read video
    v = VideoReader(videoName);
    % Get index
    frameRate = v.FrameRate;
    duration = v.Duration;
    numFrames = frameLength - startFrame;
    if numFrames > frameLength
        numFrames = frameLength;
    end
    disp(strcat("Found ", num2str(numFrames), " frames for analysis"));
    % Initiate storage array for images
    imgArray = zeros(v.Height,v.Width,numFrames);

    % Loop through and obtain images
    for i = 1:1:numFrames
        if startFrame*(1/frameRate)+(i-1)*(1/frameRate) > duration
            break
        end
        v.CurrentTime = startFrame*(1/frameRate)+(i-1)*(1/frameRate); % Set time of frame
        f = readFrame(v); % Read single frame from video
        if size(f,3) == 3
            f = rgb2gray(f);
        end
        imgArray(:,:,i) = f; % Store current frame in imgArray
    end
end