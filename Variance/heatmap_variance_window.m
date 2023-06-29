% FILE PATH
filePath = '228N_2L_baseline.tif';

% SET ROI MOVEMENT STEP SIZE 
stepSize = 30;

% SET WINDOW SIZE FOR ROLLING AVERAGE
sigma = 1.75;

% SET RADIUS OF ROI
radius = 15;

% SET FRAME NUMBER
frameNumber = 17;

% Read TIFF file
stack = tiffreadVolume(filePath);
numSlices = size(stack, 3);
numFrames = numSlices / 3;

% Select the THG channel
ch1 = stack(:, :, 1:3:numSlices-2);
frame = double(ch1(:, :, frameNumber));

% Smooth the frame using a rolling average
smoothedFrame = imgaussfilt(frame, sigma);

% Determine the size of the frame
frameSize = size(frame);

% Preallocate array for moving average variance data points
movingAverageVarianceData = zeros(frameSize);

% Initialize counter for the number of ROIs
roiCounter = 0;

% Create a figure to hold the image
figure;
imshow(smoothedFrame, []);

% Iterate over y-direction
for y = radius+1:stepSize:frameSize(1)-radius
    % Iterate over x-direction
    for x = radius+1:stepSize:frameSize(2)-radius
        % Set the center coordinates of the ROI
        centerX = x;
        centerY = y;

        % Calculate the variance of the pixels within the circle
        maskedFrame = frame(centerY-radius:centerY+radius, centerX-radius:centerX+radius);
        variance = var(maskedFrame(:));

        % Store the moving average variance data point
        roiCounter = roiCounter + 1;
        movingAverageVarianceData(centerY, centerX) = variance;
    end
end

% Create a heat map for the moving average variance
figure;
hold on;
colormap('hot');
colorbar;
title('Moving Average Variance Heat Map');
xlabel('X');
ylabel('Y');

% Create a matrix to store the count of overlapping ROIs
overlapCount = zeros(frameSize);

for y = radius+1:stepSize:frameSize(1)-radius
    for x = radius+1:stepSize:frameSize(2)-radius
        centerX = x;
        centerY = y;

        % Calculate the coordinates of the square
        xSquare = [centerX - radius, centerX + radius, centerX + radius, centerX - radius];
        ySquare = [centerY - radius, centerY - radius, centerY + radius, centerY + radius];

        % Retrieve the variance value
        movingAverageVarianceValue = movingAverageVarianceData(centerY, centerX);

        % Update the overlapping region with the average value
        for i = 1:numel(xSquare)
            px = xSquare(i);
            py = ySquare(i);

            % Check if the pixel is within the frame
            if px >= 1 && px <= frameSize(2) && py >= 1 && py <= frameSize(1)
                % Increment the overlap count
                overlapCount(py, px) = overlapCount(py, px) + 1;

                % Calculate the average value for the overlap
                movingAverageVarianceData(py, px) = (movingAverageVarianceData(py, px) + movingAverageVarianceValue) / overlapCount(py, px);
            end
        end

        % Draw the square with the corresponding color
        fill(xSquare, ySquare, movingAverageVarianceData(centerY, centerX), 'EdgeColor', 'none');
    end
end
