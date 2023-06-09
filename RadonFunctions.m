files = "sample.tif";

% Read TIFF file
stack = tiffreadVolume(files);
numSlices = size(stack, 3);
numFrames = numSlices / 3;

% Specify the folder name to save the images and figures
folderName = 'analysis_results';

% Create the folder if it does not exist
if ~exist(folderName, 'dir')
    mkdir(folderName);
end

% Function to draw the circle ROI
drawROI = @(frame, centerX, centerY, radius) drawcircle('Center', [centerX, centerY], 'Radius', radius);

% Function to perform Radon transform
performRadonTransform = @(maskedFrame) radon(maskedFrame, linspace(0, 180, 180));

% Function to calculate standard deviation
calculateStdDev = @(R) std(R);

% Function to find the full width at half maximum (FWHM)
findFWHM = @(stdDev) find(stdDev > max(stdDev) / 2, 1, 'last') - find(stdDev > max(stdDev) / 2, 1) + 1;

% Function to analyze the curve
analyzeCurveFunction = @(stdDev) [findFWHM(stdDev), max(stdDev), trapz(stdDev)];

% Set the number of slices to skip
skipSlices = 50;

% Determine the actual number of frames with available data
actualNumFrames = ceil(numSlices / 3 / skipSlices);

% Initialize structural arrays to store analysis results
results = struct('Width', {}, 'Height', {}, 'Area', {});

% Iterate over each frame
for m = 1:skipSlices:numFrames
    disp(m)
    
    % Select the THG channel
    ch1 = stack(:, :, 1:3:numSlices-2);
    
    frame = double(ch1(:, :, m));
    
    % Set the initial position to the top left corner
    initialX = 200;
    centerX = initialX;
    centerY = 200;
    
    % Initialize arrays to store ROI-specific analysis results
    roiWidths = {};
    roiHeights = {};
    roiAreas = {};
    
    % Iterate over y-direction
    while centerY + 100 <= size(frame, 1) - 100
        % Iterate over x-direction
        while centerX + 100 <= size(frame, 2) - 100
            % Display the image
            figure;
            imshow(frame, []);
            
            % Create the ROI object
            roi = drawROI(frame, centerX, centerY, 100);
            
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
            roiWidths{end + 1} = width;
            roiHeights{end + 1} = height;
            roiAreas{end + 1} = area;
            
            % Save the Radon transform figure
            figure;
            imagesc(0:179, 1:size(R, 1), R);
            colormap(gca, 'hot');
            colorbar;
            xlabel('Theta (degrees)');
            ylabel('Radon Transform Parameter');
            title('Radon Transform');
            filename = sprintf('radon_transform_slice%d_centerX%d_centerY%d.png', m, centerX, centerY);
            saveas(gcf, fullfile(folderName, filename));
            
            % Save the standard deviation figure
            figure;
            plot(stdDev);
            xlabel('Theta');
            ylabel('Standard Deviation');
            title('Standard Deviation Magnitude per Theta');
            filename = sprintf('std_deviation_slice%d_centerX%d_centerY%d.png', m, centerX, centerY);
            saveas(gcf, fullfile(folderName, filename));
            
            % Close all figures
            close all;  
            % Move to the next x position
            centerX = centerX + 100;
        end
        
        % Move back to the starting position for the next row
        centerX = initialX;
        % Move to the next y position
        centerY = centerY + 100;
    end
    
    % Store the analysis results for the current frame
    results(m).Width = roiWidths;
    results(m).Height = roiHeights;
    results(m).Area = roiAreas;
end

% Save the analysis results
save(fullfile(folderName, 'analysis_results.mat'), 'results');