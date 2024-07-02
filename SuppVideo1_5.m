% function FluoroIMGStack_to_AVI_ScaledInts()
clear; close all;
% Important parameters:
filting=0;
TimeDiff = 0.5; % In Hours
TOCROP = 0;

[Filename,Pathname]=uigetfile('*.mat','Select Images to Videoize','./Cutted PNGs','MultiSelect','on');
addpath(Pathname);

VidPath = './';

VidName = 'test';

%%
aviobj = VideoWriter([VidPath, VidName,'.avi'],'Motion JPEG AVI');
aviobj.FrameRate = 15;%20
aviobj.Quality = 100;
open(aviobj);

IMGStack = load(Filename,'Archive');
num_images = size(IMGStack.Archive.IMG,3);
TimeStamps = linspace(0,(num_images-1)*TimeDiff,num_images);
%%
MaxSat = 1.05;
SaturationFactor = [MaxSat*ones(25,1); (linspace(MaxSat,0.99,num_images-25))'];
%%
for i=1:num_images
    IMGfilt = IMGStack.Archive.IMG(:,:,i);
    if isa(IMGfilt,'uint16')
        IMGfilt=histogram_stretch(IMGfilt);
        IMGfilt=uint8(IMGfilt*255.0);
    end
    max_ind(i)=max(max(IMGfilt));
    min_ind(i)=min(min(IMGfilt));
end


for i=1:num_images
    f = IMGStack.Archive.IMG(:,:,i);
    % Filter parameters
    if filting==1
        hsize=75;
        sigma=75;
        IMGfilt=IMGlpfilter(f,hsize,sigma);
    else
        IMGfilt=f;
    end
    if isa(IMGfilt,'uint16')
        Fint8=histogram_stretch(IMGfilt);
        Fint8=uint8(Fint8*255.0);
        IMGfilt=Fint8;
    end
    if numel(max_ind) == 1
        stretched = histogram_stretch(IMGfilt,min_ind,SaturationFactor(i)*max_ind-min_ind);
    else
        stretched = histogram_stretch(IMGfilt,min_ind(i),SaturationFactor(i)*max_ind(i)-min_ind(i));
    end
    stretched = uint8(stretched*255.0);
    
    StretchPlusTStamp = insertText(stretched,[0 0],[sprintf('%.1f',TimeStamps(i)) ' hrs'],'AnchorPoint','LeftTop',...
        'BoxColor','white','fontsize',15);
    writeVideo(aviobj,StretchPlusTStamp);
    clear stretched StretchPlusTStamp;
end
close(aviobj);
clear mov;

