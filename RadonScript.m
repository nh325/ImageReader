files = "228N_2L_wk8.tif";

% Read TIFF file
stack = tiffreadVolume(files(1:length(files)));
numChan = size(stack, 3);

% Select the THG channel
ch1 = stack(:, :, 1:3:numChan-2);

% Specify the slice number
m = 21;
if m > size(ch1, 3) % Make sure slice exists
    error('Invalid frame index.');
end

frame = double(ch1(:, :, m));
figure; imshow(frame, []);

% Draw ROI
roi = drawcircle;
center = roi.Center;
radius = roi.Radius;
roiMask = createMask(roi); % Get the binary mask of the ROI

% Calculate radius of ROI
roiRadius = radius;

% Save the ROI
roiImage = frame .* roiMask;
imwrite(uint8(roiImage), 'roi_image.png');

% Apply ROI mask
maskedFrame = frame .* roiMask;

% Radon Transform
theta = linspace(0, 180, 180); % Specify the angles for Radon transform
numAngles = length(theta);
numPixels = size(maskedFrame, 1);
R = zeros(numPixels, numAngles);
for i = 1:numAngles
    angle = theta(i);
    rotatedFrame = imrotate(maskedFrame, -angle, 'bilinear', 'crop');
    R(:, i) = sum(rotatedFrame, 2);
end

% Display Radon transform
figure;
imagesc(theta, 1:numPixels, R);
colormap(gca, 'hot');
colorbar;
xlabel('Theta (degrees)');
ylabel('Radon Transform Parameter');
title('Radon Transform');
saveas(gcf, 'radon_transform.png');

% Calculate standard deviation per column
raw_stdDev = std(R);
stdDev = (raw_stdDev - min(raw_stdDev)) / (max(raw_stdDev)-min(raw_stdDev));

% Smooth the standard deviation curve
windowSize = 20;
smoothed_stdDev = movmean(stdDev, windowSize);

% Display smoothed standard deviation magnitude per column
figure;
plot(smoothed_stdDev);
xlabel('Theta');
ylabel('Smoothed Standard Deviation');
title('Smoothed Standard Deviation Magnitude per Theta');
saveas(gcf, 'smoothed_std_deviation.png');

% Width: Find the full width at half maximum (FWHM)
halfMax = max(smoothed_stdDev) / 2;
aboveHalfMax = smoothed_stdDev > halfMax;
firstAboveHalfMax = find(aboveHalfMax, 1);
lastAboveHalfMax = find(aboveHalfMax, 1, 'last');
width = lastAboveHalfMax - firstAboveHalfMax;
widthIndices = [firstAboveHalfMax, lastAboveHalfMax];

% Height: Find the maximum standard deviation
[height, heightIndex] = max(smoothed_stdDev);

% Area under the curve: Compute the integral of the standard deviation curve
area = trapz(smoothed_stdDev);

% Display analysis results
fprintf('Width: %.2f\n', width);
fprintf('Width Indices: [%d, %d]\n', widthIndices(1), widthIndices(2));
fprintf('Height: %.2f\n', height);
fprintf('Height Index: %d\n', heightIndex);
fprintf('Area under the curve: %.2f\n', area);

% Pseudo FWHM
doubleStdDev = [smoothed_stdDev smoothed_stdDev];
[~, ind1] = max(diff(doubleStdDev)); % finds the first positive slope inflection point
[~, ind2] = min(diff(doubleStdDev(ind1:end))); % finds the first negative slope inflection point after the first positive one
pseudoFWHM = ind2;
pseudoFWHMIndex = ind1 + ind2 - 1;

fprintf('Pseudo FWHM: %.2f\n', pseudoFWHM);
fprintf('Pseudo FWHM Indices: [%d, %d]\n', ind1, pseudoFWHMIndex);

% Calculate centroid of the smoothed standard deviation curve
theta_centroid = linspace(0, 180, length(smoothed_stdDev));
centroid = sum(theta_centroid .* smoothed_stdDev) / sum(smoothed_stdDev);

fprintf('Centroid: %.2f\n', centroid);

% Display radius of ROI
fprintf('ROI Radius: %.2f\n', roiRadius);
