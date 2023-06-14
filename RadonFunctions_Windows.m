% FILE PATH
files = "sample.tif";

% SET ROI MOVEMENT STEP SIZE 
stepSize = 100;

% SET INITAL XY VALUES
initialX = 200;
initialY = 200;

%SET RADIUS OF ROI
radius = 100;

% SET NUMBER OF SLICES TO SKIP
skipSlices = 50;

% AREA RESITRICTION FROM LEFT AND BOTTOM EDGE
buffer = 100;


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

% Function to calculate normalized standard deviation
calculateStdDev = @(R) (std(R) - min(std(R))) / (max(std(R))-min(std(R)));

% Function to find the full width at half maximum (FWHM)
findFWHM = @(stdDev) find(stdDev > max(stdDev) / 2, 1, 'last') - find(stdDev > max(stdDev) / 2, 1) + 1;

% Function to analyze the curve
analyzeCurveFunction = @(stdDev) [findFWHM(stdDev), max(stdDev), trapz(stdDev)];

% Determine the actual number of frames with available data
actualNumFrames = ceil(numSlices / 3 / skipSlices);

% Calculate the maximum number of ROIs
maxNumROIs = floor(((size(stack, 1) - buffer - initialY) / stepSize + 1) * ((size(stack, 2) - buffer - initialX) / stepSize + 1));

% Preallocate arrays for ROI-specific analysis results
roiWidths = cell(1, maxNumROIs);
roiHeights = cell(1, maxNumROIs);
roiAreas = cell(1, maxNumROIs);

% Initialize structural arrays to store analysis results
results = struct('Width', roiWidths, 'Height', roiHeights, 'Area', roiAreas);

% Iterate over each frame
for m = 1:skipSlices:numFrames
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
    while centerY + radius <= size(frame, 1) - buffer
        % Iterate over x-direction
        while centerX + radius <= size(frame, 2) - buffer
            % Display the image
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
            stdDev = calculateStdDev(R);
            
            % Analyze the curve
            analysisResult = analyzeCurveFunction(stdDev);
            width = analysisResult(1);
            height = analysisResult(2);
            area = analysisResult(3);
            
            % Store the analysis results for the current ROI
            roiCounter = roiCounter + 1;
            roiWidths{roiCounter} = width;
            roiHeights{roiCounter} = height;
            roiAreas{roiCounter} = area;
            
            % Save the Radon transform figure
            figure('Visible', 'off');
            imagesc(0:179, 1:size(R, 1), R);
            colormap(gca, 'hot');
            colorbar;
            xlabel('Theta (degrees)');
            ylabel('Radon Transform Parameter');
            title('Radon Transform');
            filename = sprintf('radon_transform_slice%d_centerX%d_centerY%d.png', m, centerX, centerY);
            saveas(gcf, fullfile(folderName, filename));
            
            % Save the standard deviation figure
            figure('Visible', 'off');
            plot(stdDev);
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
    
    % Store the analysis results for the current frame
    results(m).Width = roiWidths;
    results(m).Height = roiHeights;
    results(m).Area = roiAreas;
end

% Save the analysis results
save(fullfile(folderName, 'analysis_results.mat'), 'results');
