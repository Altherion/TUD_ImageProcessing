function [] = SaveImage(image,outputFolder,filename,fileType)  %% Save image to outputFolder
    %% Saves Images from 'image' to the directory 'outputFolder'.

    if ~exist(strcat(outputFolder,filename), 'dir')
        mkdir(strcat(outputFolder,filename));
    end
    cd(outputFolder)
    outputFileName = strcat(outputFolder,filename,'\');
    Data_Temp = image;
    for w = 1:1:size(Data_Temp,3)
        Saveimage = Data_Temp(:,:,w);
        if ~islogical(Saveimage)
            Saveimage = uint8(Data_Temp(:,:,w));
        end
        if numel(num2str(abs(w))) == 1
        num = '0000';
        elseif numel(num2str(abs(w))) == 2
            num = '000';
        elseif numel(num2str(abs(w))) == 3
            num = '00';  
        elseif numel(num2str(abs(w))) == 4
            num = '0';
        else
            num = '';
        end
        savename = strcat(filename,'-',num,num2str(w),fileType);
        fig = gcf;
        fig.PaperPositionMode = 'auto';
        writeimage(Saveimage,savename,outputFileName)
        clear SaveImage
    end
    close
    clear Data_temp savename fig w 
end
