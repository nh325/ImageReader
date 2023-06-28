% Load the analysis results
folderName = 'radon_results';
load(fullfile(folderName, 'analysis_results.mat'));

% Extract the width, height, area, and pseudoFWHM data from the analysis results
widthData = [];
heightData = [];
areaData = [];
pseudoFWHMData = [];
for m = 1:numel(results)
    frameResults = results(m);
    
    % Exclude width values of 180
    non180Widths = cell2mat(frameResults.Width);
    non180Widths = non180Widths(non180Widths ~= 180);
    
    widthData = [widthData, non180Widths];
    heightData = [heightData, cell2mat(frameResults.Height)];
    areaData = [areaData, cell2mat(frameResults.Area)];
    pseudoFWHMData = [pseudoFWHMData, cell2mat(frameResults.PseudoFWHM)];
end

% Plot the data on separate figures with box plots
figure;
boxplot(widthData);
title('Width Box Plot (excluding 180)');
ylabel('Width');

figure;
boxplot(heightData);
title('Height Box Plot');
ylabel('Height');

figure;
boxplot(areaData);
title('Area Box Plot');
ylabel('Area');

figure;
boxplot(pseudoFWHMData);
title('PseudoFWHM Box Plot');
ylabel('PseudoFWHM');
