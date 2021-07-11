function [DataImages] = GetImagesFromFile2(location,filetype)
%% Change on 2020-12-14
% - Script now checks if supplied images are in rgb, and converts them to grayscale if so.
% - Script now checks if all files in the directory begin their name with a letter. 
% All files that do not start with a letter are removed from processing.
%% Set current folder, which contains files
cd(location)
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Open Files
files = dir(); % Detect all files
clear file_names
for xx = 1:numel(files) ; file_names{xx,1} = files(xx).name ; end % Store file names
clear xx 
file_names = file_names(3:end,1); % Generate array of file names
clear scriptpath; disp('Folder located')
index = find(contains(file_names,filetype)); % Find png files
pngfile = string(file_names(index)); % Store files in 'pngfile'
%% Check if letter on first index.
num_files = length(pngfile);
files_real = zeros(num_files,1); 
for i = 1:1:num_files
    str = isletter(char(pngfile(num_files-i+1)));
    if str(1) == 0 % if first index is not a letter
        files_real(i) = 1;
        pngfile(num_files-i+1) = [];
    end
    clear str
end
clear files_real
num_files = length(pngfile);
%% Read images
image = imread(char(pngfile(1)));
DataImages = zeros(size(image,1),size(image,2),num_files);
%% Check if rgb and convert to grayscale if necessary.
if size(image,3) == 1
    for w = 1:1:num_files
        DataImages(:,:,w) = imread(char(pngfile(w)));
    end
elseif size(image,3) == 3
    for w = 1:1:num_files
        DataImages(:,:,w) = rgb2gray(imread(char(pngfile(w))));
    end
end
end