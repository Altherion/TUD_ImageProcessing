function writeimage(data,savename,outputFileName)
    % Write image

for z = 1:length(data(1, 1, :))
    if z == 1
        imwrite(data(:,:,z),strcat(outputFileName,savename),'Compression','none');
    else
        imwrite(data(:,:,z),strcat(outputFileName,savename),'WriteMode','append','Compression','none');
    end
end
disp(strcat('Saved_3D_image_',savename,'_to_',outputFileName));
end