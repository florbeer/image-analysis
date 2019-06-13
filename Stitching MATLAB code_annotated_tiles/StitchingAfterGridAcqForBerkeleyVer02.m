close all;
clear all;

%% User Parameters (In/Out File location, File name, DownSample Factor, Text size & intensity)

ParentPath = '/Volumes/Samsung_T3/Annotated Cases/T16-119468_Piece_02/Annotated/';  %Location of HF images 
OutputPath = '/Volumes/Samsung_T3/Annotated Cases/T16-119468_Piece_02/Annotated/';      %Desired location of Montage image
FileName_SelectedZone = '/Volumes/Samsung_T3/Annotated Cases/T16-119468_Piece_02/Annotated/T16-119468.txt'; %Need to generate a file of FOV list using '_AcqList.txt' file in AcqData folder
FileNameSuffix = 'Dapi-1'; %'Cy5_HF' or 'Dapi'
FileNameExt = 'tif';
dsf= 4;                 %downsample factor
iSizeTextMask = 512;    %Max text size: 256
iFontSize = 10;        %Max font Size: 120
iTextIntVal = 5;        %Weighting factor * Intensity of Text    %For Cy3 or Cy5, iTextIntVal = 20;     %For DAPI, iTextIntVal = 5; 
OutputFileName = 'Dapi_Test_03.tif'; %Final name of Montage Image

ImageType = 3;          %Gray Image: 1,   RGB Color Image: 3

%%
Isize = 4096;
iSizeTile = Isize / dsf;

fid = fopen(FileName_SelectedZone, 'r');
n = 1;
while (1)
    A = fgetl(fid);
    
    if (A == -1)
        break;
    end
    
    Digit1 = (int32(A(1)) - int32('A'));
    Digit2 = (int32(A(2)) - int32('A'));

    StopIdx1(n,1) = Digit1 * 26 + Digit2;
    StopIdx2(n,1) = str2num(A(3:end));
    
    n = n+1;
end
fclose(fid);

StopIdx1Max = max(StopIdx1);
StopIdx1Min = min(StopIdx1);
StopIdx2Max = max(StopIdx2);
StopIdx2Min = min(StopIdx2);

n = 1;
for i = StopIdx1Min : StopIdx1Max
    StopOnAxis1{n,1} = sprintf('%c%c', int32('A') + floor(double(i)/26), int32('A') + mod(i,26));    
    n = n+1;
end

n = 1;
for i = StopIdx2Min : StopIdx2Max
    StopOnAxis2(n,1) = i;
    n = n+1;
end

Nrow = size(StopOnAxis2,1);
Ncol = size(StopOnAxis1,1);

%%
k = 1;
clear M;
for i = 1:Nrow
    for j = 1:Ncol
        
        FovName = sprintf('%s%d', StopOnAxis1{j}, StopOnAxis2(i));
        filename = sprintf('%s/%s_%s.%s', ParentPath, FovName, FileNameSuffix, FileNameExt);
        
        if (exist(filename, 'file') == 2)
            ATemp = imread(filename,'tif');
            RowSizeA = size(ATemp, 1);                
            ColSizeA = size(ATemp, 2);
            CropStartRow = (RowSizeA - Isize)/2+1;
            CropStartCol = (ColSizeA - Isize)/2+1;
            AA = ATemp(CropStartRow:CropStartRow+Isize-1, CropStartCol:CropStartCol+Isize-1, :);
        else            
            AA = zeros([Isize, Isize, ImageType], 'uint16');
        end
        
        A = AA(1:dsf:Isize, 1:dsf:Isize, :);
        
        TextMask = MakeTextMask(iSizeTextMask, iSizeTextMask, iFontSize, FovName);
        TextMask = cast(TextMask, class(A));
        [iSizeTextMaskRow, iSizeTextMaskCol] = size(TextMask);
        iStartRow = 1;
        iStartCol = 1;
        iStartRowForTextMask = round(iStartRow + (iSizeTile - iSizeTextMaskRow) / 2);
        iStartColForTextMask = round(iStartCol + (iSizeTile - iSizeTextMaskCol) / 2);    

        for m = 1:ImageType
            A(iStartRowForTextMask:iStartRowForTextMask+iSizeTextMaskRow-1, iStartColForTextMask:iStartColForTextMask+iSizeTextMaskCol-1, m) ...
                = A(iStartRowForTextMask:iStartRowForTextMask+iSizeTextMaskRow-1, iStartColForTextMask:iStartColForTextMask+iSizeTextMaskCol-1, m) ...
                + iTextIntVal*TextMask;

            BorderLine = 16383; %Borderline Intensity
            A(1,1:end,m) = BorderLine; 
            A(end,1:end,m) = BorderLine; 
            A(1:end,1,m) = BorderLine; 
            A(1:end,end,m) = BorderLine;
        end
        
        M((i-1)*(Isize/dsf)+1:i*(Isize/dsf), (j-1)*(Isize/dsf)+1:j*(Isize/dsf), :) = A;
        k = k+1;
    end
end

%% 8bit, PNG File format, Intensity Adjustment
% t0 = clock;
% M8bit = uint8(255.0 * (double(M) / 65000)); %Max Intensity Normalization(65000 to 255)
% M8bit = uint8(double(M));
% M8bit = uint8(M);
% imwrite(M8bit,[OutputPath,'\Dapi_GuideMap_DS4.png']); %Output file name
% etime(clock,t0)


%% 16bit, Tiff File format
t0 = clock;
filename = [OutputPath, '/', OutputFileName]; %Output file name
imwrite(M, filename);
etime(clock,t0)

