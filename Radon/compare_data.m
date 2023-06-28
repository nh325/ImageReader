% File paths
folderName1 = 'radon_wk1';
folderName2 = 'radon_wk8';

% Load the analysis results from the first mat file
load(fullfile(folderName1, 'analysis_results.mat'));
results1 = results;

% Load the analysis results from the second mat file
load(fullfile(folderName2, 'analysis_results.mat'));
results2 = results;

% Preallocate array sizes
numResults1 = numel(results1);
numResults2 = numel(results2);

widthData1 = [];
heightData1 = [];
areaData1 = [];
pseudoFWHMData1 = [];

widthData2 = [];
heightData2 = [];
areaData2 = [];
pseudoFWHMData2 = [];

% Extract the widths, heights, areas, and pseudoFWHM data for each week
for m = 1:numResults1
    roiWidths = results1(m).Width;
    roiHeights = results1(m).Height;
    roiAreas = results1(m).Area;
    roiPseudo = results1(m).PseudoFWHM;
    
    widthData1 = [widthData1; cell2mat(roiWidths)];
    heightData1 = [heightData1; cell2mat(roiHeights)];
    areaData1 = [areaData1; cell2mat(roiAreas)];
    pseudoFWHMData1 = [pseudoFWHMData1; cell2mat(roiPseudo)];
end

for m = 1:numResults2
    roiWidths = results2(m).Width;
    roiHeights = results2(m).Height;
    roiAreas = results2(m).Area;
    roiPseudo = results2(m).PseudoFWHM;
    
    widthData2 = [widthData2; cell2mat(roiWidths)];
    heightData2 = [heightData2; cell2mat(roiHeights)];
    areaData2 = [areaData2; cell2mat(roiAreas)];
    pseudoFWHMData2 = [pseudoFWHMData2; cell2mat(roiPseudo)];
end

% Combine the data from both weeks
widthData = [widthData1; widthData2];
heightData = [heightData1; heightData2];
areaData = [areaData1; areaData2];
pseudoFWHMData = [pseudoFWHMData1; pseudoFWHMData2];

% Create group labels
groupLabels = [repmat({'Results wk1'}, size(widthData1, 1), 1); repmat({'Results wk8'}, size(widthData2, 1), 1)];

% Figure: Box Plots
figure;
subplot(2, 2, 1);
boxplot(widthData', groupLabels);
title('Width Box Plot');
ylabel('Width');

subplot(2, 2, 2);
boxplot(heightData', groupLabels);
title('Height Box Plot');
ylabel('Height');

subplot(2, 2, 3);
boxplot(areaData', groupLabels);
title('Area Box Plot');
ylabel('Area');

subplot(2, 2, 4);
boxplot(pseudoFWHMData', groupLabels);
title('PseudoFWHM Box Plot');
ylabel('PseudoFWHM');
