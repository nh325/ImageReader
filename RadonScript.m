files = "sample.tif";

% Read TIFF file
stack = tiffreadVolume(files(1:length(files)));
numSlices = size(stack, 3); % number of channels

% SELECT CHANNEL (uses 1st out of 3)
ch1 = stack(:, :, 1:3:numChan-2);

% SPECIFY SLICE NUMBER
m = 21; % CHANGE!
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

% Save the ROI
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

% Display standard deviation magnitude per column
figure;
plot(stdDev);
xlabel('Theta');
ylabel('Standard Deviation');
title('Standard Deviation Magnitude per Theta');
saveas(gcf, 'std_deviation.png');
