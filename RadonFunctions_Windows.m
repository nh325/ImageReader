% FILE PATH
files = "wk8.tif";

% SET ROI MOVEMENT STEP SIZE 
stepSize = 15;

% SET INITAL XY VALUES
initialX = 160;
initialY = 180;

% SET RADIUS OF ROI
radius = 15;

% SET NUMBER OF SLICES TO SKIP
skipSlices = 2;

% AREA RESITRICTION FROM LEFT AND BOTTOM EDGE
buffer_X = 240;
buffer_Y = 220;

% START AND END SLICE
startSlice = 13;
endSlice = 23;

% Read TIFF file
stack = tiffreadVolume(files);
numSlices = size(stack, 3);
numFrames = numSlices / 3;

% Specify the folder name to save the images and figures
folderName = 'radon_results';

% Create the folder if it does not exist
if ~exist(folderName, 'dir')
    mkdir(folderName);
end

% Function to draw the circle ROI
drawROI = @(frame, centerX, centerY, radius) drawcircle('Center', [centerX, centerY], 'Radius', radius);

% Function to perform Radon transform
performRadonTransform = @(maskedFrame) radon(maskedFrame, linspace(0, 180, 180));

% % Function to calculate normalized standard deviation
% calculateStdDev = @(R) (std(R));

% % Function to calculate normalized standard deviation
% calculateNormalizedStdDev = @(R) (std(R) - min(std(R))) / (max(std(R)) - min(std(R)));

% Function to analyze the curve
analyzeCurveFunction = @(stdDoubled) [findFWHM(stdDoubled), findPseudoFWHM(stdDoubled)];

% Determine the actual number of frames with available data
actualNumFrames = ceil(numSlices / 3 / skipSlices);

% Calculate the maximum number of ROIs
maxNumROIs = floor(((size(stack, 1) - buffer_Y - initialY) / stepSize + 1) * ((size(stack, 2) - buffer_X - initialX) / stepSize + 1));

% Preallocate arrays for ROI-specific analysis results
roiWidths = cell(1, maxNumROIs);
roiHeights = cell(1, maxNumROIs);
roiAreas = cell(1, maxNumROIs);
roiPseudoFWHM = cell(1, maxNumROIs);

% Initialize structural arrays to store analysis results
results = struct('Width', roiWidths, 'Height', roiHeights, 'Area', roiAreas, 'PseudoFWHM', roiPseudoFWHM);

% Iterate over each frame
for m = startSlice:skipSlices:endSlice
    disp(m)
    
    % Select the THG channel
    ch1 = stack(:, :, 1:3:numSlices-2);
    
    frame = double(ch1(:, :, m));
    
    % Set the initial position
    centerX = initialX;
    centerY = initialY;
    
    % Initialize counter for the number of ROIs
    roiCounter = 0;
    
    % Iterate over y-direction
    while centerY + radius <= size(frame, 1) - buffer_Y
        % Iterate over x-direction
        while centerX + radius <= size(frame, 2) - buffer_X

            figure('Visible', 'off');
            imshow(frame, []);
       
            % Create the ROI object
            roi = drawROI(frame, centerX, centerY, radius);

            % Save the image with ROI outline
            filename = sprintf('image_with_roi_outline_slice%d_centerX%d_centerY%d.png', m, centerX, centerY);
            saveas(gcf, fullfile(folderName, filename));
                       
            % Get the binary mask of the ROI
            roiMask = createMask(roi);
            
            % Apply ROI mask
            maskedFrame = frame .* roiMask;
            
            % Perform Radon Transform
            R = performRadonTransform(maskedFrame);
            
            % Calculate standard deviation
            stdDev = std(R);
            normalizeStdDev = (stdDev - min(stdDev)) / (max(stdDev) - min(stdDev));
            stdDoubled = [normalizeStdDev normalizeStdDev];
            
            analysisResult = analyzeCurveFunction(stdDoubled);
            width = analysisResult(1);
            height = max(stdDev);
            area = trapz(stdDev);
            pseudoFWHM = analysisResult(2);
            
            % Store the analysis results for the current ROI
            roiCounter = roiCounter + 1;
            roiWidths{roiCounter} = width;
            roiHeights{roiCounter} = height;
            roiAreas{roiCounter} = area;
            roiPseudoFWHM{roiCounter} = pseudoFWHM;
            
            % Save the Radon transform figure
            imagesc(0:179, 1:size(R, 1), R);
            colormap(gca, 'hot');
            colorbar;
            xlabel('Theta (degrees)');
            ylabel('Radon Transform Parameter');
            title('Radon Transform');
            filename = sprintf('radon_transform_slice%d_centerX%d_centerY%d.png', m, centerX, centerY);
            saveas(gcf, fullfile(folderName, filename));
            
            % Save the standard deviation figure
            plot(stdDoubled);
            xlabel('Theta');
            ylabel('Standard Deviation');
            title('Standard Deviation Magnitude per Theta');
            filename = sprintf('std_deviation_slice%d_centerX%d_centerY%d.png', m, centerX, centerY);
            saveas(gcf, fullfile(folderName, filename));
            
            % Move to the next x position
            centerX = centerX + stepSize;
        end
        
        % Move back to the starting position for the next row
        centerX = initialX;
        % Move to the next y position
        centerY = centerY + stepSize;
    end
    
    % Trim empty cells from the analysis results
    roiWidths = roiWidths(1:roiCounter);
    roiHeights = roiHeights(1:roiCounter);
    roiAreas = roiAreas(1:roiCounter);
    roiPseudoFWHM = roiPseudoFWHM(1:roiCounter);
    
    % Store the analysis results for the current frame
    results(m).Width = roiWidths;
    results(m).Height = roiHeights;
    results(m).Area = roiAreas;
    results(m).PseudoFWHM = roiPseudoFWHM;
end


% Save the analysis results
save(fullfile(folderName, 'analysis_results.mat'), 'results');

function fwhm = findFWHM(stdDoubled)
    half_max = max(stdDoubled) / 2;

    % Find the indices where the curve crosses the half-maximum threshold
    indices = find(stdDoubled >= half_max);

   
    % Calculate the distance between the first and last crossing indices
    fwhm = (indices(end) - indices(1) + 1) / 2;
    
end


function pseudoFWHM = findPseudoFWHM(stdDoubled)
    [~, ind1] = max(diff(stdDoubled)); % finds the first positive slope inflection point    
    [~, ind2] = min(diff(stdDoubled(ind1:end))); % finds the first negative slope inflection point after the first positive one
       
    pseudoFWHM = ind2; % calculates the pseudo FWHM
    
end

