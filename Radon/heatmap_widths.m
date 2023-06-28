% FILE PATH
files = "228N_2L_baseline.tif";

% SET ROI MOVEMENT STEP SIZE 
stepSize = 60;

% SET RADIUS OF ROI
radius = 30;

% Read TIFF file
stack = tiffreadVolume(files);
numSlices = size(stack, 3);
numFrames = numSlices / 3;

% Specify the frame to analyze
frameNumber = 14;

% Select the THG channel
ch1 = stack(:, :, 1:3:numSlices-2);
frame = double(ch1(:, :, frameNumber));

% Determine the size of the frame
frameSize = size(frame);

% Preallocate arrays for width and pseudo FWHM data points
widthData = zeros(frameSize);
pseudoFWHMData = zeros(frameSize);

% Initialize counter for the number of ROIs
roiCounter = 0;

% Create a figure to hold the image
figure;
imshow(frame, []);

% Iterate over y-direction
for y = 1:stepSize:frameSize(1)
    % Iterate over x-direction
    for x = 1:stepSize:frameSize(2)
        % Set the center coordinates of the ROI
        centerX = x;
        centerY = y;
        
        % Create the ROI object using the current figure
        roi = drawcircle(gca, 'Center', [centerX, centerY], 'Radius', radius);
        
        % Get the binary mask of the ROI
        roiMask = createMask(roi);
        
        % Apply ROI mask
        maskedFrame = frame .* roiMask;
        
        % Perform Radon Transform
        R = radon(maskedFrame, linspace(0, 180, 180));
        
        % Calculate standard deviation
        stdDev = std(R);
        normalizeStdDev = (stdDev - min(stdDev)) / (max(stdDev) - min(stdDev));
        stdDoubled = [normalizeStdDev normalizeStdDev];
        
        % Calculate width and pseudo FWHM
        width = findFWHM(stdDoubled);
        pseudoFWHM = findPseudoFWHM(stdDoubled);
        
        % Store width and pseudo FWHM data points
        roiCounter = roiCounter + 1;
        widthData(centerY, centerX) = width;
        pseudoFWHMData(centerY, centerX) = pseudoFWHM;
    end
end

% % Generate heat maps for width and pseudo FWHM
% figure;
% imagesc(widthData);
% colormap('hot');
% colorbar;
% title('Width Heat Map');
% xlabel('X');
% ylabel('Y');
% 
% 
% figure;
% imagesc(pseudoFWHMData);
% colormap('hot');
% colorbar;
% title('Pseudo FWHM Heat Map');
% xlabel('X');
% ylabel('Y');


% Create a grid of squares for each heat map
figure;
hold on;
colormap('hot');
colorbar;
title('Width Heat Map (Squares)');
xlabel('X');
ylabel('Y');

for y = 1:stepSize:frameSize(1)
    for x = 1:stepSize:frameSize(2)
        centerX = x;
        centerY = y;
        
        % Calculate the coordinates of the square
        xSquare = [centerX - radius, centerX + radius, centerX + radius, centerX - radius];
        ySquare = [centerY - radius, centerY - radius, centerY + radius, centerY + radius];
        
        % Retrieve the width value
        widthValue = widthData(centerY, centerX);
        
        % Draw the square with the corresponding color
        fill(xSquare, ySquare, widthValue, 'EdgeColor', 'none');
    end
end

% Create a grid of squares for the pseudo FWHM heat map
figure;
hold on;
colormap('hot');
colorbar;
title('Pseudo FWHM Heat Map (Squares)');
xlabel('X');
ylabel('Y');

for y = 1:stepSize:frameSize(1)
    for x = 1:stepSize:frameSize(2)
        centerX = x;
        centerY = y;
        
        % Calculate the coordinates of the square
        xSquare = [centerX - radius, centerX + radius, centerX + radius, centerX - radius];
        ySquare = [centerY - radius, centerY - radius, centerY + radius, centerY + radius];
        
        % Retrieve the pseudo FWHM value
        pseudoFWHMValue = pseudoFWHMData(centerY, centerX);
        
        % Draw the square with the corresponding color
        fill(xSquare, ySquare, pseudoFWHMValue, 'EdgeColor', 'none');
    end
end

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
