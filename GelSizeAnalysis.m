% function GelImg_GlobThreshSquareSwell()
clear; close all;
%======================
% File Path:
%======================
BasePath = 'C:\Users\';

[Filename,Pathname]=uigetfile('*.mat', 'Select Data to Compare',BasePath,'MultiSelect','on');
addpath(Pathname);

if ~iscell(Filename)
    FilenameTemp{1} = Filename;
    Filename = FilenameTemp;
end
Filename = Filename';

num_images=numel(Filename);
SpecMess = 'SLGlobTh';
%%
%======================
% Time Profile:
%======================
TimeDiff = 0.5; % Imaging interval
TimeStamps = linspace(0,0.5*(numel(Filename)-1),numel(Filename)); % hrs

%%
%======================
% Find Object Outline:
%======================
MaskedObjArea=[];
clear Archive
for ImgNum = 1:num_images
    RawDat=load(Filename{ImgNum});
    IMGData_Doub = imadjust(RawDat.IMG_data);
    
    %======================
    % Important parameters to be adjusted:
    % hsize: usually 55 is best. sometimes using values like 45, 75, or 95 can help,
    % but often will make it worse. very situational
    
    % ThLinVar: user defined vector of numbers for adjusting the threhsold.
    % Put two numbers in the field (can be same number).
    % Goal is to make as large as possible without adding excess background to
    % the object. Chose to vary over the time series because
    % the gels get dimmer/higher background intensity. Numbers can
    % vary wildly. Sometimes need to go as low as "15" for second number.
    % Higher numbers equal higher areas in the end.
    
    % RotateDegrees: if rotation will help (if extra things pointing straight off side of
    % object that will disrupt the extrema analysis). Rotation in degrees to counterclockwise
    hsize=55;%55 %35for am5bis %95 for pegda20k %195 for new imager
    ThLinVar = [linspace(100,200,num_images)];
    RotateDegrees = 0;
    %======================
    
    sigma=110; %110
    FiltDat = IMGlpfilter(IMGData_Doub,hsize,sigma); % low pass filtering of image
    if RotateDegrees ~= 0 % rotate if you need to
        FiltDatTh = imrotate(FiltDat,RotateDegrees);
        IMGData_Doub = imrotate(IMGData_Doub,RotateDegrees);
    else
        FiltDatTh = FiltDat;
    end
    ThFudgeFact = 1.35; %1.35
    MaskedIMG2 = FiltDatTh >= ThFudgeFact* mean(FiltDatTh(:)); % thresholding (rnd 1)
    ThFudgeFact =  mean(FiltDatTh(MaskedIMG2))/ mean(FiltDatTh(~MaskedIMG2))/ThLinVar(ImgNum);
    ThFFSaved(ImgNum,1) = ThFudgeFact;
    MaskedIMG2 = FiltDatTh >= ThFudgeFact * mean(FiltDatTh(:)); % thresholding (rnd 2)
    
    %=========
    % If you have small squares you might need to lower this number.
    % This removes all objects with an area less than this many pixels
    MaskedIMG2=bwareaopen(MaskedIMG2,800);
    %=========
    
    MaskedIMG2Bounds=bwboundaries(MaskedIMG2,8);
    Masked_ConnComps = bwconncomp(MaskedIMG2,8);
    MaskedObjArea{ImgNum,1}=regionprops(Masked_ConnComps,'Area','centroid','extrema','PixelIdxList'); % Make array just in case it detects multiple objects. Also this is why we use regionprops instead of bwarea
    % Save the remaining data into an archive structure
    Archive.IMG(:,:,ImgNum) = IMGData_Doub;
    Archive.MaskedIMG{ImgNum} = MaskedIMG2;
    Archive.AllMaskedBounds{ImgNum,1} = MaskedIMG2Bounds;
    Archive.ConComps{ImgNum,1} = Masked_ConnComps;
end
%======================
% Get Hydrogel Areas, Boundaries, and Side Lengths:
%======================
% Extract the area and the object boundaries. If more than one object was
% found from the mask, pick the one with a centroid in the middle of the image.
% This works well unless the background object is a ring around the center...
ObjAreaSeries=[];
ImgCenter = size(IMGData_Doub)/2;
isCurledIndicator = zeros(numel(Archive.ConComps),1);
ClustPtsDist=[];
ExtremPts=[];
for ImgNum = 1:num_images
    NumComponents = Archive.ConComps{ImgNum}.NumObjects;
    TempAreaVals = [];
    if NumComponents == 0
        ObjAreaSeries(ImgNum,:) = 0;
        Archive.MaskedBounds{ImgNum,1} = NaN;
        ExtremPts{ImgNum} = [NaN NaN];
    elseif NumComponents > 1 % Have more then 1 object
        TempDist2Center = [];
        for k = 1:NumComponents
            TempDist2Center(k) = pdist2(ImgCenter,MaskedObjArea{ImgNum}(k).Centroid);
        end
        [~, MInd]= min(TempDist2Center);
        ObjAreaSeries(ImgNum,:) = MaskedObjArea{ImgNum}(MInd).Area;
        Archive.MaskedBounds{ImgNum,1} = Archive.AllMaskedBounds{ImgNum}{MInd};
        
        ExtremPts{ImgNum} = MaskedObjArea{ImgNum}(MInd).Extrema;
    else
        ObjAreaSeries(ImgNum,:) = MaskedObjArea{ImgNum}.Area;
        Archive.MaskedBounds{ImgNum,1} = Archive.AllMaskedBounds{ImgNum}{1};
        
        ExtremPts{ImgNum} = MaskedObjArea{ImgNum}.Extrema;
    end
    ExtrPtsOrig = ExtremPts{ImgNum};
    %Check Orientation
    if pdist2(ExtrPtsOrig(1,:),[0,0]) < pdist2(ExtrPtsOrig(1,:),[size(IMGData_Doub,1),0])
        ExAct = ExtrPtsOrig([1 3 5 7],:);
    else
        ExAct = ExtrPtsOrig([2 4 6 8],:);
    end
    CDP = pdist2(ExAct,ExAct);
    % Assume Extrema go in order (clockwise or counter clockwise, doesn't matter)
    TempC = CDP([2,4,7,12]); % Index style since easier
    TempAv = mean(TempC(:));
    TempSt = std(TempC(:));
    ExtremPts{ImgNum} = ExAct;
    ClustPtsDist = TempC';
    % Temporary adjustments here in case the hydrogel curls. Need something
    % better because this isn't quite right?
    if TempSt > 125/30.42 % Assume curling is going on, arbitrary number here for numerator
        Archive.ClustPtsArch.AvgClustPtsDist(ImgNum,1) = max(ClustPtsDist) * 30.42;
        isCurledIndicator(ImgNum) = 1;
    else
        Archive.ClustPtsArch.AvgClustPtsDist(ImgNum,1) = mean(ClustPtsDist) * 30.42;
    end
    Archive.ClustPtsArch.StdClustPtsDist(ImgNum,1) = std(ClustPtsDist) * 30.42;
    Archive.ClustPtsArch.ClusterDist{ImgNum,1} = ClustPtsDist;
    Archive.ClustPtsArch.ExtrPts{ImgNum,1} = ExtremPts{ImgNum};
    Archive.ClustPtsArch.ExtrPtsOrig{ImgNum,1} = ExtrPtsOrig;
    
end
% Convert total number of pixels to square microns, use the ruler image
CalibObjAreas = ObjAreaSeries*(30.42)^2; 
CalibSideLengths = Archive.ClustPtsArch.AvgClustPtsDist;
Archive.ClustPtsArch.isItCurled = isCurledIndicator;

%% Save the Data:
close all;
SlashInds = regexp(Pathname,'/');

SaveDir = Pathname(1:SlashInds(end-1));
save([SaveDir SpecMess 'AreaCalc_' Filename{1}(1:end-4) '_' num2str(yyyymmdd(datetime))])
% save([SaveDir 'AreaCalc_' Filename(1:end-4)])
disp(Filename{1}(1:end-4));
%% Check plot/results if necessary
NumIms = size(Archive.IMG,3);%num_images;
SpecificImgsToPlot = [];
ImsToPlot = [SpecificImgsToPlot round(linspace(1,NumIms, 8-numel(SpecificImgsToPlot)))];
BWLineWidth=1;
figure('units','normalized','outerposition',[0 0 1 1]);
set(gcf,'renderer','painters')
for ImageNumber = 1:8
    PlotImNum = ImsToPlot(ImageNumber);
    subplot(2,4,ImageNumber);
    imshow(Archive.IMG(:,:,PlotImNum),[min(min(Archive.IMG(:,:,PlotImNum))) max(max(Archive.IMG(:,:,PlotImNum)))]);
    hold on
    ThisBound=Archive.MaskedBounds{PlotImNum};
    plot(ThisBound(:,2),ThisBound(:,1),'g','LineWidth',BWLineWidth);
    plot(Archive.ClustPtsArch.ExtrPtsOrig{PlotImNum}(:,1),Archive.ClustPtsArch.ExtrPtsOrig{PlotImNum}(:,2),'bo','MarkerSize',10,'LineWidth',1.5)
    plot(Archive.ClustPtsArch.ExtrPts{PlotImNum}(:,1),Archive.ClustPtsArch.ExtrPts{PlotImNum}(:,2),'rv','MarkerSize',15,'LineWidth',2)
    hold off
    title(num2str(PlotImNum));
end
%% Plot Data
figure('units','normalized','outerposition',[0 0 1 1]);
set(gcf,'renderer','painters')
subplot 121
P1 = plot(CalibObjAreas,'-','linewidth',1.5);
ylabel('Particle Area ({\mu}m^2)')
xlabel('IMG Number')
set(gca,'FontName','Arial','FontSize',20,'FontWeight','Bold')
axis square
subplot 122
P1 = plot((CalibObjAreas-CalibObjAreas(1))./CalibObjAreas(1)*100,'-','linewidth',1.5);
ylabel('Relative Particle Area (%)')
xlabel('IMG Number')
set(gca,'FontName','Arial','FontSize',20,'FontWeight','Bold')
axis square

figure('units','normalized','outerposition',[0 0 1 1]);
set(gcf,'renderer','painters')
subplot 121
P1 = plot(CalibSideLengths,'-','linewidth',1.5);
ylabel('Side Length ({\mu}m')
xlabel('IMG Number')
set(gca,'FontName','Arial','FontSize',20,'FontWeight','Bold')
axis square
subplot 122

P1 = plot((CalibSideLengths-CalibSideLengths(1))./CalibSideLengths(1),'-','linewidth',1.5);
ylabel('{\Delta}L/L_0')
xlabel('IMG Number')
set(gca,'FontName','Arial','FontSize',20,'FontWeight','Bold')
axis square