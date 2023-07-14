files = 'e4baseline/lowMag/C1-AVG_20221017_M171_baseline_25x_stack1L_zoom1pt3_780_895um_2umsteps_3fps_14.tif';

% Read TIFF file
stack = tiffreadVolume(files);
numChan = size(stack, 3);

stepSize = 40;
radius = 20;
windowSize = 50;

% Specify the slice number
m = 1;
if m > size(stack, 3) % Make sure slice exists
    error('Invalid frame index.');
end

frame = double(stack(:, :, m));
figure; imshow(frame, []);
numSlices = size(stack, 3);
numFrames = numSlices;

% Save data
folderName = 'radon_E4_M171_baseline_lowMag';
[~, baseFileName, ~] = fileparts(files);
csvFileName = fullfile(folderName, [baseFileName '_data']);
figureFileName = fullfile(folderName, [baseFileName '_ROI']);

% Create the folder if it does not exist
if ~exist(folderName, 'dir')
    mkdir(folderName);
end

% Function to draw the circle ROI
drawROI = @(frame, centerX, centerY, radius) drawcircle('Center', [centerX, centerY], 'Radius', radius);

% Function to perform Radon transform
performRadonTransform = @(maskedFrame) radon(maskedFrame, linspace(0, 180, 180));

% Function to smooth the curve using a moving average filter
smoothCurve = @(curve, windowSize) movmean(curve, windowSize);

% Function to analyze the curve
analyzeCurveFunction = @(stdDoubled) [findPseudoFWHM(stdDoubled), findDegree(stdDoubled)];

% Calculate the maximum number of ROIs
maxNumROIs = 0;

% Initialize counter for the number of ROIs
roiCounter = 0;

% Initialize the mask for all ROIs
roiMaskAll = zeros(size(frame));

% First iteration to calculate maximum heights
idx = 1;
maxHeights = [];
for centerY = radius:stepSize:size(frame, 1)-radius
    for centerX = radius:stepSize:size(frame, 2)-radius
        maxNumROIs = maxNumROIs + 1;
        figure('Visible', 'off');  % Create a new invisible figure
        imshow(frame, []); % Display the image in the current figure

        roi = drawROI(frame, centerX, centerY, radius);
        roiMask = createMask(roi);
        close(gcf); % Close the current figure after creating the mask
        maskedFrame = frame .* roiMask;

        % Perform Radon Transform
        R = performRadonTransform(maskedFrame);
 
        % Calculate standard deviation curve
        stdDev = std(R);   

        % Store the maximum height
        height = max(stdDev);
        maxHeights(idx) = height;
        idx = idx + 1;
    end
end

% Calculate the threshold as the average height of all ROI standard deviation curves
threshold = mean(maxHeights);
disp(threshold)
% Preallocate arrays for ROI-specific analysis results
roiWidths = cell(1, maxNumROIs);
roiDegree = cell(1, maxNumROIs);
% Initialize structural arrays to store analysis results
results = struct('Width', roiWidths, 'Degree', roiDegree);

% Second iteration to save ROIs above the threshold
for centerY = radius:stepSize:size(frame, 1)-radius
    for centerX = radius:stepSize:size(frame, 2)-radius
        % Create the ROI
        figure('Visible', 'off');  % Create a new invisible figure
        imshow(frame, []);
        roi = drawROI(frame, centerX, centerY, radius);
        roiMask = createMask(roi);
        close(gcf);
        maskedFrame = frame .* roiMask;

        % Perform Radon Transform
        R = performRadonTransform(maskedFrame);

        % Calculate standard deviation curve
        stdDev = std(R);
        height = max(stdDev);

        % Check if the maximum height is above the threshold
        if height > threshold
            % Calculate data
            stdDoubled = [stdDev stdDev];
            smoothedCurve = smoothCurve(stdDoubled, windowSize);
            normalizeStdDev = (smoothedCurve - min(smoothedCurve)) / (max(smoothedCurve) - min(smoothedCurve));        
            
            analysisResult = analyzeCurveFunction(normalizeStdDev);
            pseudoFWHM = analysisResult(1);
            degree = analysisResult(2);
            if degree > 180
                degree = degree - 180;
            end

            % Store the analysis results for the current ROI
            roiCounter = roiCounter + 1;
            roiWidths{roiCounter} = pseudoFWHM;
            roiDegree{roiCounter} = degree;

            % Update the mask for all ROIs
            roiMaskAll = roiMaskAll + roiMask;

           
        end
    end
end

% Trim empty cells from the analysis results
roiWidths = roiWidths(1:roiCounter);
roiDegree = roiDegree(1:roiCounter);
disp(roiDegree)

% Apply the mask to the original frame
frameWithROIs = frame .* roiMaskAll;
figure;
imshow(frameWithROIs, []);

% Save the figure with ROIs
saveas(gcf, figureFileName);

% Filter out non-numeric values
degreeDataNumeric = cellfun(@(x) isnumeric(x) && ~isempty(x), roiDegree);
widthDataNumeric = cellfun(@(x) isnumeric(x) && ~isempty(x), roiWidths);

% Create a table to store the analysis results
dataTable = table([roiDegree{degreeDataNumeric}]', [roiWidths{widthDataNumeric}]', 'VariableNames', {'Degree', 'Width'});

% Save the data table to a CSV file
writetable(dataTable, csvFileName);

% Calculate the average degree and width
averageDegree = mean([roiDegree{degreeDataNumeric}]);
averageWidth = mean([roiWidths{widthDataNumeric}]);

% Calculate the standard deviation of degree and width
stdDegree = std([roiDegree{degreeDataNumeric}]);
stdWidth = std([roiWidths{widthDataNumeric}]);

% Display the results
disp("Average Degree: " + averageDegree);
disp("Standard Deviation of Degree: " + stdDegree);
disp("Average Width: " + averageWidth);
disp("Standard Deviation of Width: " + stdWidth);
disp(roiCounter + " out of " + maxNumROIs + " selected");

% Create a single ROI on the original frame with a radius of 256
centerX = size(frame, 2) / 2;
centerY = size(frame, 1) / 2;
radius = 256;
figure('Visible', 'off');
imshow(frame, []);
roi = drawROI(frame, centerX, centerY, radius);
roiMask = createMask(roi);
close(gcf);
maskedFrameROI = frame .* roiMask;

% Perform Radon Transform on the ROI
RROI = performRadonTransform(maskedFrameROI);


% Calculate standard deviation curve
stdDevROI = std(RROI);
stdDoubledROI = [stdDevROI stdDevROI];
smoothedCurveROI = smoothCurve(stdDoubledROI, windowSize);

normalizeStdDevROI = (smoothedCurveROI - min(smoothedCurveROI)) / (max(smoothedCurveROI) - min(smoothedCurveROI));


% figure;
% plot(normalizeStdDevROI);
% xlabel('Theta');
% ylabel('Smoothed Standard Deviation');
% title('Smoothed Standard Deviation Magnitude per Theta');
% saveas(gcf, 'smoothed_std_deviation.png');

% Analyze the curve
analysisResultROI = analyzeCurveFunction(stdDoubledROI);
pseudoFWHMROI = analysisResultROI(1);
degreeROI = analysisResultROI(2);

% Display the results for the ROI with radius 256
disp("Degree of ROI with Radius 256: " + degreeROI);
disp("Width of ROI with Radius 256: " + pseudoFWHMROI);

fprintf("%.4f %.4f %.4f %.4f %d %d %.4f %.4f  \n", averageDegree, stdDegree, averageWidth, stdWidth, roiCounter, maxNumROIs, degreeROI, pseudoFWHMROI);

% Function to find pseudo FWHM
function pseudoFWHM = findPseudoFWHM(stdDoubled)
    [~, ind1] = max(diff(stdDoubled)); % finds the first positive slope inflection point
    [~, ind2] = min(diff(stdDoubled(ind1:end))); % finds the first negative slope inflection point after the first positive one
    
    pseudoFWHM = ind2; % calculates the pseudo FWHM
end

function degrees = findDegree(stdDoubled)
    [~, locs] = findpeaks(stdDoubled);
    degrees = locs(stdDoubled(locs) == max(stdDoubled(locs)));
end
