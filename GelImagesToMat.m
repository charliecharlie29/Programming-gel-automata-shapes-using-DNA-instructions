% function GelImager_CropAndSortBeads_TSeries()

clear; close all;
% Important parameters:
ExportPlot = 0;
[Filename,Pathname]=uigetfile('*.tif', 'SELECT THE GELS','C:\Users\','MultiSelect','on');
addpath(Pathname);
NumBeads = 12;
MakeFolders = 1;
% IMPORTANT
InitBeadNum = 1;
%%
if iscell(Filename)
    num_images=numel(Filename);
else
    TempF{1} = Filename;
    Filename = TempF;
    num_images=1;
end
TIFdir=[Pathname 'PNGs'];
BeadMatDir = [Pathname 'BeadImgs'];
if MakeFolders == 1
    mkdir(TIFdir);
    mkdir(BeadMatDir);
end
InitImgNum = 1;
UberImg = imread([Pathname Filename{InitImgNum}]);
ffig=figure(1);
imshow(UberImg,[])
title(['Get MB Locs. Img Num:' num2str(InitImgNum)])
[Xpts, Ypts] = getpts(ffig);




for ImgNum = 1:num_images
    UberImg = imread([Pathname Filename{ImgNum}]);
    
    for BeadNum = 1:numel(Xpts)
        UsedBeadNum = InitBeadNum + BeadNum - 1;
        if MakeFolders == 1 && ImgNum == 1
            mkdir(BeadMatDir,['mb_' num2str(UsedBeadNum)]);
        end
        IMG_data = imcrop(UberImg,[Xpts(BeadNum)-150 Ypts(BeadNum)-150 300 300]);%75 150 200 400 for whole 48 well 100 200
        %% Save the Data:
        if MakeFolders == 1
            save([BeadMatDir '\mb_' num2str(UsedBeadNum) '\' Filename{ImgNum}(1:end-4) '_mb' num2str(UsedBeadNum) '.mat'],'IMG_data')
            IMG8bit = histogram_stretch(IMG_data,min(min(IMG_data)),max(max(IMG_data))-min(min(IMG_data))); %stretch the data to make it visible in 8 bit format/png format (actually 0-1)
            imwrite(IMG8bit,[TIFdir '\' Filename{ImgNum}(1:end-4) '_mb' num2str(UsedBeadNum) '.png'],'PNG'); %Write the intensities to a png file
        else
            save([Pathname Filename{ImgNum}(1:end-4) '_mb' num2str(UsedBeadNum) '.mat'],'IMG_data')
            IMG8bit = histogram_stretch(IMG_data,min(min(IMG_data)),max(max(IMG_data))-min(min(IMG_data))); %stretch the data to make it visible in 8 bit format/png format (actually 0-1)
            imwrite(IMG8bit,[Pathname Filename{ImgNum}(1:end-4) '_mb' num2str(UsedBeadNum) '.png'],'PNG'); %Write the intensities to a png file
        end
    end
end