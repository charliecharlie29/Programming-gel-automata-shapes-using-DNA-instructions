% function BilayerFluoroCalculator_v2_GelImg()
clear; close all;
% Important parameters:
ExportPlot = 0;

Basepath = 'C:/Users/';

[Filename,Pathname]=uigetfile('*.mat', 'SELECT THE GELS',Basepath,'MultiSelect','on');


addpath(Pathname);
if ~iscell(Filename)
    FilenameTemp{1} = Filename;
    Filename = FilenameTemp;
end
Filename = Filename';
num_images=numel(Filename);

%%
% TimeDiff = 20/60;15/60
TimeDiff = 30/60;

TimeStamps = linspace(0,(num_images-1)*TimeDiff,num_images); % hrs
% TimeStamps = [0 1.167 linspace(1.5,(num_images-3)*TimeDiff,num_images-2)];
% TimeStamps = [-1 -0.5 linspace(0,(num_images-3)*TimeDiff,num_images-2)];
% TimeStamps = [-0.5 linspace(0,(num_images-2)*TimeDiff,num_images-1)];
%%
for bilayerNum =  1:num_images
    RawDat=load(Filename{bilayerNum});
    IMGData_Doub = double(RawDat.IMG_data);
    
    MaskedIMGThick = IMGData_Doub > 4 * mode(IMGData_Doub(:));%2.25 5
    StdBG = std(IMGData_Doub(~MaskedIMGThick));
    MeanBG = mean(IMGData_Doub(~MaskedIMGThick));
    MaskedIMGThick = IMGData_Doub > MeanBG + 4 *StdBG;%12 %2.55 larger the number, the area smaller3.5 6/5 6/4.95
%     if bilayerNum == 1
%         MaskedIMGThick = IMGData_Doub > MeanBG + 3.2*StdBG;%12
%     end
%      
    MaskedIMGThick=bwareaopen(MaskedIMGThick,700); %700 Remove small objects. Beads are pretty big right now so size can be arbitrary
    MaskedIMG2Bounds=bwboundaries(MaskedIMGThick,4);
    Masked_ConnComps = bwconncomp(MaskedIMGThick,4);
    Areas = regionprops(Masked_ConnComps,'Area');
    if size(Areas,1) ~= 0
        NumComponents = numel(Areas.Area);
        if NumComponents == 0
            ObjAreaSeries = NaN;
        elseif NumComponents > 1 % Have more then 1 object
            TempAreaVals=[];
            for k = 1:NumComponents
                TempAreaVals(k) = Areas.Area;
            end
            [ObjAreaSeries, MaxTVAInd] = max(TempAreaVals);
        else
            ObjAreaSeries = Areas.Area;
        end
    else
        ObjAreaSeries = NaN;
    end
    Archive.Areas(bilayerNum,1) = ObjAreaSeries;
    Archive.IMG(:,:,bilayerNum) = IMGData_Doub;
    MaskedIMGThick = bwmorph(MaskedIMGThick,'majority');
    MaskedIMGThick = bwmorph(MaskedIMGThick,'spur');
    Archive.MaskedIMG(:,:,bilayerNum) = MaskedIMGThick;
    Archive.MaskedBounds{bilayerNum,1} = MaskedIMG2Bounds;
    MaskedIMGThin = bwmorph(MaskedIMGThick,'thin',Inf);
    
    
    %     figure;subplot 131; imshow(IMGData_Doub,[]); subplot 132; imshow(MaskedIMGThick);subplot 133; imshow(MaskedIMGThin);
    if bilayerNum == 22
       1; 
    end
    % Get and Sort Coordinates
    % find bilayer endpoints first
    BilayerEndpointsIMG = bwmorph(MaskedIMGThin,'endpoints');
    BilayerEndpoints = find(BilayerEndpointsIMG == 1);
    XYEnds = [];
    XYCoords = [];
%     EndPointIndex = 1;
    if ~isempty(BilayerEndpoints)
        iter = 1;
        while numel(BilayerEndpoints) > 2
            sedisk=strel('disk',7);
            MaskedThickEnds=imdilate(MaskedIMGThin,sedisk);
            MaskedIMGThin = bwmorph(MaskedThickEnds,'thin',Inf);
            BilayerEndpointsIMG = bwmorph(MaskedIMGThin,'endpoints');
            BilayerEndpoints = find(BilayerEndpointsIMG == 1);
            iter = iter + 1;
            if iter > 50
               break; 
            end
        end
    end
    LineCoords = find(MaskedIMGThin == 1);
   
        
    if isempty(BilayerEndpoints)
        BilayerEndpoints = LineCoords(1);
    elseif numel(BilayerEndpoints) > 2
        
        1;
    end
    
    [XYCoords(:,1),XYCoords(:,2)]=ind2sub([size(MaskedIMGThin,1),size(MaskedIMGThin,2)],LineCoords);
    [XYEnds(:,1),XYEnds(:,2)]=ind2sub([size(MaskedIMGThin,1),size(MaskedIMGThin,2)],BilayerEndpoints);
    XYdst = [XYCoords(:,1)-XYEnds(1,1),XYCoords(:,2)-XYEnds(1,2)];
    EndPointIndex = find(sum(abs(XYdst),2) == 0);
    
    Archive.ThinMask(:,:,bilayerNum) = MaskedIMGThin;
    %     dXY = max(XYEnds) - min(XYEnds);
    %     if dXY(1) > dXY(2) % X-coord is wider (vertical gel)
    %         [~,sxyIndices] = sort(XYCoords(:,1));
    %         XYCoords(:,1) = XYCoords(sxyIndices,1);
    %         XYCoords(:,2) = XYCoords(sxyIndices,2);
    %     else % horizontal gel
    %         [~,sxyIndices] = sort(XYCoords(:,2));
    %         XYCoords(:,1) = XYCoords(sxyIndices,1);
    %         XYCoords(:,2) = XYCoords(sxyIndices,2);
    %     end
    
    distCoords = pdist2(XYCoords,XYCoords);
    sxyIndices = NaN(numel(LineCoords),1);
    sxyIndices(1) = EndPointIndex;
    
    for coor = 2:numel(LineCoords)%[EndPointIndex+1:numel(LineCoords) 1:EndPointIndex-1]
        distCoords(:,sxyIndices(coor-1)) = Inf;
        [~,closestIdx] = min(distCoords(sxyIndices(coor-1),:));
        sxyIndices(coor) = closestIdx;
    end
    XYCoords = XYCoords(sxyIndices,:);
    
    Archive.XYCoords{bilayerNum} = XYCoords;
    % Calculate Gel contour length (2 methods)
    % Method 1:
    contourLengthMeth1 = size(XYCoords,1);
    
    % Method 2:
    contourLengthMeth2 = sum(sqrt(sum(diff(XYCoords).^2,2)));
    Archive.contourLengthM1(bilayerNum,1) = contourLengthMeth1 * 30.42/1000; % px -> mm
    Archive.contourLengthM2(bilayerNum,1) = contourLengthMeth2 * 30.42/1000; % px -> mm
    
    
    %     %% Rolling Line fitting:
    %     numPointsToFit = 30;
    %     edgePTF = round(numPointsToFit/2)-1;
    %     PTFCounter = round(numPointsToFit/2);
    %     calcCurvature=[];
    %     calcCurvature= NaN*ones(numel(LineCoords),1);
    %     while PTFCounter <= numel(LineCoords)-edgePTF
    %         XTemp = XYCoords(PTFCounter-edgePTF:PTFCounter+edgePTF,2);
    %         YTemp = XYCoords(PTFCounter-edgePTF:PTFCounter+edgePTF,1);
    %         FitCoeffs = polyfit(XTemp,YTemp,3);
    %         fitAct = FitCoeffs(1)*XTemp.^3 + FitCoeffs(2)*XTemp.^2+FitCoeffs(3)*XTemp+FitCoeffs(4);
    %         fitPrime = 3*FitCoeffs(1)*XYCoords(PTFCounter,2)^2 + 2*FitCoeffs(2)*XYCoords(PTFCounter,2)+FitCoeffs(3);
    %         fitDoublePrime = 6*FitCoeffs(1)*XYCoords(PTFCounter,2) + 2*FitCoeffs(2);
    %         calcCurvature(PTFCounter,1) = abs(fitDoublePrime)/(1+fitPrime^2)^(3/2);
    %         PTFCounter = PTFCounter + 1;
    %     end
    % Circle based fitting:
    if numel(LineCoords) > 180
        numPointsToFit = 55;
    else 
        numPointsToFit = 30;
    end
    edgePTF = round(numPointsToFit/2)-1;
    PTFCounter = round(numPointsToFit/2);
    calcCurvature= NaN*ones(numel(LineCoords),1);
    while PTFCounter <= numel(LineCoords)-edgePTF-1
        XYTemp = [XYCoords(PTFCounter-edgePTF:PTFCounter+edgePTF+1,1) XYCoords(PTFCounter-edgePTF:PTFCounter+edgePTF+1,2)];
        % Use Taubin Method, see file exchange (Nikolai Chernov)
        centroid = mean(XYTemp);
        % compute moments
        Mxx = 0;
        Myy = 0;
        Mxy = 0;
        Mxz = 0;
        Myz = 0;
        Mzz = 0;
        for datPoint = 1:numPointsToFit
            Xi = XYTemp(datPoint,1) - centroid(1);
            Yi = XYTemp(datPoint,2) - centroid(2);
            Zi = Xi^2 + Yi^2;
            
            Mxy = Mxy + Xi*Yi;
            Mxx = Mxx + Xi^2;
            Myy = Myy + Yi^2;
            Mxz = Mxz + Xi*Zi;
            Myz = Myz + Yi*Zi;
            Mzz = Mzz + Zi^2;
        end
        % Normalize moments
        Mxx = Mxx/numPointsToFit;
        Myy = Myy/numPointsToFit;
        Mxy = Mxy/numPointsToFit;
        Mxz = Mxz/numPointsToFit;
        Myz = Myz/numPointsToFit;
        Mzz = Mzz/numPointsToFit;
        
        % Compute Coefficients
        Mz = Mxx + Myy;
        Cov_xy = Mxx*Myy - Mxy^2;
        A3 = 4*Mz;
        A2 = -3*Mz^2 - Mzz;
        A1 = Mzz*Mz + 4*Cov_xy*Mz - Mxz^2 - Myz^2 - Mz^3;
        A0 = Mxz^2*Myy + Myz^2*Mxx - Mzz*Cov_xy - 2*Mxz*Myz*Mxy + Mz^2*Cov_xy;
        A22 = 2*A2;
        A33 = 3*A3;
        
        xnew = 0;
        ynew = 1e+20;
        epsilon = 1e-12;
        IterMax = 20;
        % Now run Newton's method to find best
        for circIter = 1:IterMax
            yold = ynew;
            ynew = A0 + xnew*(A1 + xnew*(A2 + xnew*A3));
            if abs(ynew) > abs(yold)
                disp('Newton-Taubin goes wrong direction: |ynew| > |yold|');
                xnew = 0;
                break;
            end
            Dy = A1 + xnew*(A22 + xnew*A33);
            xold = xnew;
            xnew = xold - ynew/Dy;
            if (abs((xnew-xold)/xnew) < epsilon)
                break;
            end
            if (circIter >= IterMax)
                disp('Newton-Taubin will not converge');
                xnew = 0;
            end
            if (xnew<0.)
                fprintf(1,'Newton-Taubin negative root:  x=%f\n',xnew);
                xnew = 0;
            end
        end
        % Compute Circle parameters [center points, radius]
        DET = xnew^2 - xnew*Mz + Cov_xy;
        circCenter = [Mxz*(Myy-xnew)-Myz*Mxy, Myz*(Mxx-xnew)-Mxz*Mxy]/DET/2;
        circParameters = [circCenter + centroid, sqrt(circCenter*circCenter'+Mz)];
        
        AllCircParams(PTFCounter-edgePTF,:) = circParameters;
        
        
        calcCurvature(PTFCounter) = 1/circParameters(3);
        PTFCounter = PTFCounter + 1;
    end
    Archive.PixelCurvatures{bilayerNum} = calcCurvature;
    % Remove non-reasonables
    TempNM = nanmean(calcCurvature);
    TempNSt = nanstd(calcCurvature);
    reasonableCurvatures = calcCurvature;
    if TempNSt < TempNM
        reasLowBound = TempNM - 2*TempNSt;
        reasHighBound = TempNM + 2*TempNSt;
    else
        reasHighBound = TempNM + 2*TempNSt;
        reasonableCurvatures = reasonableCurvatures(reasonableCurvatures < reasHighBound);
        TempNM = nanmean(reasonableCurvatures);
        TempNSt = nanstd(reasonableCurvatures);
        reasLowBound = TempNM - 2*TempNSt;
        reasHighBound = TempNM + 2*TempNSt;
    end
    reasonableCurvatures = calcCurvature(calcCurvature > reasLowBound);
    % Convert to 1/mm
    ConvertedCurvatures = reasonableCurvatures / 30.42 * 1000; % um/px on Andor scope - 1x Mag
    
    
    Archive.AverageCurvatures(bilayerNum,1) = nanmean(ConvertedCurvatures);
    
end
%% Saving
close all;
SlashInds = regexp(Pathname,'\');

SaveDir = Pathname(1:SlashInds(end-1));
save([SaveDir 'BilayerCurvCalc_Rev5' Filename{1}(1:end-4) '_' num2str(yyyymmdd(datetime)) '.mat'])
disp(Filename{1}(1:end-4));
%% Check plot/results if necessary
NumIms = size(Archive.IMG,3);%num_images;
if NumIms > 16
    SpecificImgsToPlot = [7 52];
    ImsToPlot = [SpecificImgsToPlot round(linspace(1,NumIms, 8-numel(SpecificImgsToPlot)))];
    BWLineWidth=1;
    figure('units','normalized','outerposition',[0 0 1 1]);
    set(gcf,'renderer','painters')
    for ImageNumber = 1:8
        PlotImNum = ImsToPlot(ImageNumber);
        subplot(2,4,ImageNumber);
        imshow(Archive.IMG(:,:,PlotImNum),[min(min(Archive.IMG(:,:,PlotImNum))) max(max(Archive.IMG(:,:,PlotImNum)))]);
        hold on
        for k=1:length(Archive.MaskedBounds{PlotImNum})
            ThisBound=Archive.MaskedBounds{PlotImNum}{k};
            plot(ThisBound(:,2),ThisBound(:,1),'g','LineWidth',BWLineWidth);
        end
        plot(Archive.XYCoords{PlotImNum}(:,2),Archive.XYCoords{PlotImNum}(:,1),'r','LineWidth',BWLineWidth);
        hold off
        title(num2str(PlotImNum));
    end
elseif num_images > 8
    % Plot the first 8
    BWLineWidth=1;
    figure('units','normalized','outerposition',[0 0 1 1]);
    set(gcf,'renderer','painters')
    for ImageNumber = 1:8
        subplot(2,4,ImageNumber);
        imshow(Archive.IMG(:,:,ImageNumber),[min(min(Archive.IMG(:,:,ImageNumber))) max(max(Archive.IMG(:,:,ImageNumber)))]);
        hold on
        for k=1:length(Archive.MaskedBounds{ImageNumber})
            ThisBound=Archive.MaskedBounds{ImageNumber}{k};
            plot(ThisBound(:,2),ThisBound(:,1),'g','LineWidth',BWLineWidth);
        end
        hold off
        title(num2str(ImageNumber));
    end
    % Plot the remaining
    figure('units','normalized','outerposition',[0 0 1 1]);
    set(gcf,'renderer','painters')
    for ImageNumber = 9:num_images
        subplot(2,4,ImageNumber-8);
        imshow(Archive.IMG(:,:,ImageNumber),[min(min(Archive.IMG(:,:,ImageNumber))) max(max(Archive.IMG(:,:,ImageNumber)))]);
        hold on
        for k=1:length(Archive.MaskedBounds{ImageNumber})
            ThisBound=Archive.MaskedBounds{ImageNumber}{k};
            plot(ThisBound(:,2),ThisBound(:,1),'g','LineWidth',BWLineWidth);
        end
        hold off
        title(num2str(ImageNumber));
    end
else
    ImageNumber = size(Archive.IMG,3);%num_images;
    BWLineWidth=1;
    figure('units','normalized','outerposition',[0 0 1 1]);
    set(gcf,'renderer','painters')
    scol = ceil(num_images / 2);
    switch ceil(num_images / 2)
        case 1
            srow = 1;
            scol = num_images;
        case 2
            srow = 2;
        case 3
            srow = 2;
        case 4
            srow = 2;
    end
    for ImageNumber = 1:num_images
        subplot(srow,scol,ImageNumber);
        imshow(Archive.IMG(:,:,ImageNumber),[min(min(Archive.IMG(:,:,ImageNumber))) max(max(Archive.IMG(:,:,ImageNumber)))]);
        hold on
        for k=1:length(Archive.MaskedBounds{ImageNumber})
            ThisBound=Archive.MaskedBounds{ImageNumber}{k};
            plot(ThisBound(:,2),ThisBound(:,1),'g','LineWidth',BWLineWidth);
        end
        hold off
        title(num2str(ImageNumber));
    end
end
% %%
% IMNum = 24;
% figure;
% imshow(Archive.IMG(:,:,IMNum),[]);
% hold on
% plot(Archive.XYCoords{IMNum}(:,2),Archive.XYCoords{IMNum}(:,1),'g','LineWidth',1);
% hold off

%%
figure;subplot 121;plot(Archive.contourLengthM2);ylabel('contour length')
subplot 122;plot(Archive.AverageCurvatures);ylabel('curvature')



