IM_DAPI = imread('/Volumes/Samsung_T3/Heatmap/CF81_Dapi.tif');
Spot_list = 'path to spot list'; %Needs to be in the format [X, Y, Intensity]
Interpretation = 'Linear'; %Can be linear, Ln, or Log10. Ln and Log10 will need some adjusting
SortList = 'Bottom'; %Can sort detections in order of intensity highest to lowest ('Top'), lowest to highest ('Bottom'), or in order of decetion ('none')
ColorMapName = 'RdYlBu';
UpperColormapCutoff = 0.95;
LowerColormapCutoff = 0.05;

im_height = size(IM_DAPI,1);
im_width = size(IM_DAPI, 2);
SpotRadius = 20;
im_kernel = 20;

if SortList == 'Bottom'
    [~,idx] = sort(Spot_list(:,3)); % sort just the intensities
    Spot_list_sorted = Spot_list(idx,:);   % sort the whole matrix using the sort indices
elseif SortList == 'Top'
    [~,idx] = sort(Spot_list(:,3),'descend'); % sort just the intensities
    Spot_list_sorted = Spot_list(idx,:);   % sort the whole matrix using the sort indices
else
    Spot_list_sorted = Spot_list;
end

if strcmp(Interpretation,'Linear')
    Spot_list_sorted(:,4) = Spot_list_sorted(:,3);
    UpperColorValue = prctile(Spot_list_sorted(:,4),UpperColormapCutoff);
    LowerColorValue = prctile(Spot_list_sorted(:,4),LowerColormapCutoff);
    ColorVectSize = UpperColorValue - LowerColorValue;
    SpotColorMap = cbrewer2(ColorMapName,ColorVectSize,'cubic');
    for i = 1:LowerColorValue
        SpotColorLow(i,1:3) = SpotColorMap(1,:);
    end
    for i = UpperColorValue:max(Spot_list_sorted(:,4))
        SpotColorHigh(i,1:3)= SpotColorMap(end,:);
    end
    SpotColorMapJoined = vertcat(SpotColorLow,SpotColorMap,SpotColorHigh(UpperColorValue:end,:));
    
elseif strcmp(Interpretation,'LN')
    Spot_list_sorted(:,4) = log(Spot_list_sorted(:,3));
    UpperColorValue = ceil(prctile(Spot_list_sorted(:,4),UpperColormapCutoff));
    LowerColorValue = floor(prctile(Spot_list_sorted(:,4),LowerColormapCutoff));
    ColorVectSize = UpperColorValue - LowerColorValue;
    SpotColorMap = cbrewer2(ColorMapName,ColorVectSize,'cubic');
    for i = 1:LowerColorValue
        SpotColorLow(i,1:3) = SpotColorMap(1,:);
    end
    for i = UpperColorValue:ceil(max(Spot_list_sorted(:,4)))
        SpotColorHigh(i,1:3)= SpotColorMap(end,:);
    end
    SpotColorMapJoined = vertcat(SpotColorLow,SpotColorMap,SpotColorHigh(UpperColorValue:end,:));
    
elseif strcmp(Interpretation,'Log')
    Spot_list_sorted(:,4) = log10(Spot_list_sorted(:,3));
    UpperColorValue = ceil(prctile(Spot_list_sorted(:,4),UpperColormapCutoff));
    LowerColorValue = floor(prctile(Spot_list_sorted(:,4),LowerColormapCutoff));
    ColorVectSize = UpperColorValue - LowerColorValue;
    SpotColorMap = cbrewer2(ColorMapName,ColorVectSize,'cubic');
    for i = 1:LowerColorValue
        SpotColorLow(i,1:3) = SpotColorMap(1,:);
    end
    for i = UpperColorValue:ceil(max(Spot_list_sorted(:,4)))
        SpotColorHigh(i,1:3)= SpotColorMap(end,:);
    end
    SpotColorMapJoined = vertcat(SpotColorLow,SpotColorMap,SpotColorHigh(UpperColorValue:end,:));
end

RenderedImage = zeros(im_width, im_height,3);

for i = 1:length(Spot_list_sorted(:,4))
    if and(Spot_list_sorted(i,2)-SpotRadius > 0,Spot_list_sorted(i,1)-SpotRadius > 0)
        if and(Spot_list_sorted(i,2)+SpotRadius < im_width,Spot_list_sorted(i,1)-SpotRadius < im_height)
            RenderedImage(Spot_list_sorted(i,2)-SpotRadius:Spot_list_sorted(i,2)+SpotRadius,Spot_list_sorted(i,1)-SpotRadius:Spot_list_sorted(i,1)+SpotRadius,1) = ...
                SpotColorMapJoined(round(Spot_list_sorted(i,4)),1);
            RenderedImage(Spot_list_sorted(i,2)-SpotRadius:Spot_list_sorted(i,2)+SpotRadius,Spot_list_sorted(i,1)-SpotRadius:Spot_list_sorted(i,1)+SpotRadius,2) = ...
                SpotColorMapJoined(round(Spot_list_sorted(i,4)),2);
            RenderedImage(Spot_list_sorted(i,2)-SpotRadius:Spot_list_sorted(i,2)+SpotRadius,Spot_list_sorted(i,1)-SpotRadius:Spot_list_sorted(i,1)+SpotRadius,3) = ...
                SpotColorMapJoined(round(Spot_list_sorted(i,4)),3);
        else
            RenderedImage(Spot_list_sorted(i,2)-SpotRadius:Spot_list_sorted(i,2),Spot_list_sorted(i,1)-SpotRadius:Spot_list_sorted(i,1),1) = ...
                SpotColorMapJoined(round(Spot_list_sorted(i,4)),1);
            RenderedImage(Spot_list_sorted(i,2)-SpotRadius:Spot_list_sorted(i,2),Spot_list_sorted(i,1)-SpotRadius:Spot_list_sorted(i,1),2) = ...
                SpotColorMapJoined(round(Spot_list_sorted(i,4)),2);
            RenderedImage(Spot_list_sorted(i,2)-SpotRadius:Spot_list_sorted(i,2),Spot_list_sorted(i,1)-SpotRadius:Spot_list_sorted(i,1),3) = ...
                SpotColorMapJoined(round(Spot_list_sorted(i,4)),3);
        end
    else
        if and(Spot_list_sorted(i,2)+SpotRadius < im_width,Spot_list_sorted(i,1)-SpotRadius < im_height)
            RenderedImage(Spot_list_sorted(i,2):Spot_list_sorted(i,2)+SpotRadius,Spot_list_sorted(i,1):Spot_list_sorted(i,1)+SpotRadius,1) = ...
                SpotColorMapJoined(round(Spot_list_sorted(i,4)),1);
            RenderedImage(Spot_list_sorted(i,2):Spot_list_sorted(i,2)+SpotRadius,Spot_list_sorted(i,1):Spot_list_sorted(i,1)+SpotRadius,2) = ...
                SpotColorMapJoined(round(Spot_list_sorted(i,4)),2);
            RenderedImage(Spot_list_sorted(i,2):Spot_list_sorted(i,2)+SpotRadius,Spot_list_sorted(i,1):Spot_list_sorted(i,1)+SpotRadius,3) = ...
                SpotColorMapJoined(round(Spot_list_sorted(i,4)),3);
        else
            RenderedImage(Spot_list_sorted(i,2):Spot_list_sorted(i,2),Spot_list_sorted(i,1):Spot_list_sorted(i,1),1) = ...
                SpotColorMapJoined(round(Spot_list_sorted(i,4)),1);
            RenderedImage(Spot_list_sorted(i,2):Spot_list_sorted(i,2),Spot_list_sorted(i,1):Spot_list_sorted(i,1),2) = ...
                SpotColorMapJoined(round(Spot_list_sorted(i,4)),2);
            RenderedImage(Spot_list_sorted(i,2):Spot_list_sorted(i,2),Spot_list_sorted(i,1):Spot_list_sorted(i,1),3) = ...
                SpotColorMapJoined(round(Spot_list_sorted(i,4)),3);
        end
    end
end

RenderedImageOut = imgaussfilt(RenderedImage,im_kernel);
imshow(RenderedImageOut);