% Load the analysis results from the first mat file
folderName1 = 'radon_wk1';
load(fullfile(folderName1, 'analysis_results.mat'));
results1 = results;

% Load the analysis results from the second mat file
folderName2 = 'radon_wk8';
load(fullfile(folderName2, 'analysis_results.mat'));
results2 = results;

% Preallocate array sizes
numResults1 = numel(results1);
numResults2 = numel(results2);

widthData1 = NaN(numResults1, 1);
heightData1 = NaN(numResults1, 1);
areaData1 = NaN(numResults1, 1);
pseudoFWHMData1 = NaN(numResults1, 1);

widthData2 = NaN(numResults2, 1);
heightData2 = NaN(numResults2, 1);
areaData2 = NaN(numResults2, 1);
pseudoFWHMData2 = NaN(numResults2, 1);

% Extract the widths, heights, areas, and pseudoFWHM data for each week
for m = 1:numResults1
    roiWidths = results1(m).Width;
    roiHeights = results1(m).Height;
    roiAreas = results1(m).Area;
    roiPseudo = results1(m).PseudoFWHM;
    
    widthData1(m) = mean(cell2mat(roiWidths));
    heightData1(m) = mean(cell2mat(roiHeights));
    areaData1(m) = mean(cell2mat(roiAreas));
    pseudoFWHMData1(m) = mean(cell2mat(roiPseudo));
end

for m = 1:numResults2
    roiWidths = results2(m).Width;
    roiHeights = results2(m).Height;
    roiAreas = results2(m).Area;
    roiPseudo = results2(m).PseudoFWHM;
    
    widthData2(m) = mean(cell2mat(roiWidths));
    heightData2(m) = mean(cell2mat(roiHeights));
    areaData2(m) = mean(cell2mat(roiAreas));
    pseudoFWHMData2(m) = mean(cell2mat(roiPseudo));
end

% Create group labels
groupLabels = {'Results wk1', 'Results wk8'};

% Figure: Box Plots
figure;
subplot(2, 2, 1);
boxplot([widthData1, widthData2], 'Labels', groupLabels);
title('Width Box Plot');
ylabel('Width');

subplot(2, 2, 2);
boxplot([heightData1, heightData2], 'Labels', groupLabels);
title('Height Box Plot');
ylabel('Height');

subplot(2, 2, 3);
boxplot([areaData1, areaData2], 'Labels', groupLabels);
title('Area Box Plot');
ylabel('Area');

subplot(2, 2, 4);
boxplot([pseudoFWHMData1, pseudoFWHMData2], 'Labels', groupLabels);
title('PseudoFWHM Box Plot');
ylabel('PseudoFWHM');
