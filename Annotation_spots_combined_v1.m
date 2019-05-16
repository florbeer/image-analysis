% March 2018, FL 
% Combinding the code for reading in the annotated file and sorting spots
% into annotated cells 
close all;
clear all;
%% define all input folders
%path for annotated images
input_path=('/Volumes/Samsung_T3/Annotated Cases/T16-119468_Piece_02/Annotated/');
%path for spot files
input_path_spots =('/Volumes/Samsung_T3/02-23-2018_Spot Counting Results_updated/T16-119468_Piece_02/Spot counting result/');

tile_name = 'CH83';
file_name = [tile_name,'_Dapi', '-1.tif'];
file_name_Cy3 = [tile_name, '_Cy3N','_SpotDetection.txt'];
file_name_Cy5 = [tile_name, '_Cy5','_SpotDetection.txt'];

imsize = 4096;
%mkdir(input_path, tile_name)
%output_path=([input_path, tile_name, '/']); %Give filepath to EXISTING folder where you want to save the results
%Give filepath to EXISTING folder where you want to save the results
ouput_path_spots = input_path;

%% reading in the files for colored, annotated image and spots
%annotated Image 
annotatedImage = imread([input_path, file_name]);
%spot files 
spots_Cy3 = readtable([input_path_spots, file_name_Cy3]);
spots_Cy5 = readtable([input_path_spots, file_name_Cy5]);

%% Turn the color annotation into matrices
% Identify color that was used for marking cell type
% predefine colors here: 
% green %keratinocytes
% red %dysplastic melanocytes
% blue %fibroblasts
% yellow % normal melanocytes

binary_red = zeros(imsize,imsize);
binary_blue = zeros(imsize,imsize);
binary_green = zeros(imsize,imsize);
binary_orange = zeros(imsize,imsize);

% pick out pixels of certain color and store into vector containing the
% positions of colored pixels
A_red = find ((annotatedImage(:,:,1) == 255)&(annotatedImage(:,:,2) == 0)&(annotatedImage(:,:,3) == 0));
binary_red(A_red) = 1;

A_blue = find ((annotatedImage(:,:,1) == 0)&(annotatedImage(:,:,2) == 0)&(annotatedImage(:,:,3) == 255));
binary_blue(A_blue) = 1;

A_green = find ((annotatedImage(:,:,1) == 0)&(annotatedImage(:,:,2) == 255)&(annotatedImage(:,:,3) == 0));
binary_green(A_green) = 1;

A_orange = find ((annotatedImage(:,:,1) == 255)&(annotatedImage(:,:,2) == 153)&(annotatedImage(:,:,3) == 0));
binary_orange(A_orange) = 1;
%make a list of pixels that are red in form of a structure array
%X_red = regionprops(binary_red,'PixelList');
%%

[binary_red_cells, number_red_cells]  = bwlabel(binary_red,4); 
[binary_blue_cells, number_blue_cells]  = bwlabel(binary_blue,4); 
[binary_green_cells, number_green_cells]  = bwlabel(binary_green,4);
[binary_orange_cells, number_orange_cells]  = bwlabel(binary_orange,4);
%coloredLabels = label2rgb (L, 'hsv', 'k', 'shuffle'); % control plot to
%show that they are all different 
%cellMeasurements = regionprops(binary_red_cells, binary_red, 'all');
cellOutlines_red = regionprops(binary_red_cells, binary_red, 'PixelIdxList','PixelList', 'Centroid');
[cellOutlines_red.color] = deal('red');

cellOutlines_blue = regionprops(binary_blue_cells, binary_blue, 'PixelIdxList','PixelList', 'Centroid');
[cellOutlines_blue.color] = deal('blue');

cellOutlines_green = regionprops(binary_green_cells, binary_green, 'PixelIdxList','PixelList', 'Centroid');
[cellOutlines_green.color] = deal('green');

cellOutlines_orange = regionprops(binary_orange_cells, binary_orange, 'PixelIdxList','PixelList', 'Centroid');
[cellOutlines_orange.color] = deal('orange');

%% Make a list of all the results 
% %concatenate all results
cellOutlines = vertcat(cellOutlines_red, cellOutlines_blue, cellOutlines_green, cellOutlines_orange);
%thisCellsPixel = cellMeasurements(1).PixelIdxList;
%save([output_path, 'cell_outlines', '_',tile_name, '.mat'],'cellOutlines', '-v7.3')

figure
subplot(2,2,1)
imshow(annotatedImage)

subplot(2,2,2) 
imshow(binary_red_cells)

subplot(2,2,3)
imshow(binary_blue_cells)

subplot(2,2,4)
imshow(binary_green_cells)

%% Are the Cy3 spots within the cellOutlines?
% if area in cell is in spot 
% make an entry next to the x,y spot with color and field number 
%spots_Cy3.color = zeros(height(spots_Cy3),1);
tic;
spots_Cy3.cell = zeros(height(spots_Cy3),1);
spots_Cy3.color = cell(height(spots_Cy3),1);
spots_Cy3.tile = cell(height(spots_Cy3),1);
spots_Cy3.tile(:) = {tile_name};

for     j = [1:length(cellOutlines)]
    
    for i = [1:height(spots_Cy3)]
        testX = getfield(cellOutlines,{j}, 'PixelList');
        testZ = ismember([spots_Cy3{i,2},spots_Cy3{i,3}], testX, 'rows');
    
        if sum(testZ) > 0
        spots_Cy3.cell(i) = j;
        spots_Cy3.color(i) = {getfield(cellOutlines,{j}, 'color')};
        end 
    end 
end 
toc;
writetable(spots_Cy3,[ouput_path_spots,tile_name,'_localized_particles_experiment.txt'],'Delimiter','\t');
%% same thing for Cy5 spots
spots_Cy5.cell = zeros(height(spots_Cy5),1);
spots_Cy5.color = cell(height(spots_Cy5),1);
spots_Cy5.tile = cell(height(spots_Cy5),1);
spots_Cy5.tile(:) = {tile_name};
tic;
for     j = [1:length(cellOutlines)]
    
    for i = [1:height(spots_Cy5)]
        %testX = getfield(cellOutlines,{j}, 'PixelList');
        testX = cellOutlines(j).PixelList;
        testZ = ismember([spots_Cy5{i,2},spots_Cy5{i,3}], testX, 'rows');
    
        if sum(testZ) > 0
        spots_Cy5.cell(i) = j;
        spots_Cy5.color(i) = {getfield(cellOutlines,{j}, 'color')};
        end 
    end 
end 
toc;
writetable(spots_Cy5,[ouput_path_spots,tile_name,'_localized_particles_control.txt'],'Delimiter','\t');


