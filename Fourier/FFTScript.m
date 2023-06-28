% Specify the TIFF file path
filePath = 'sample.tif';

% Read the TIFF file
stack = tiffreadVolume(filePath);
numSlices = size(stack, 3);
numFrames = numSlices / 3;

% Specify the folder name to save the FFT results
folderName = 'fft_results';

% Create the folder if it does not exist
if ~exist(folderName, 'dir')
    mkdir(folderName);
end

% Iterate over each frame
for m = 1:numFrames
    % Select the THG channel
    ch1 = stack(:, :, 1:3:numSlices-2);
    
    % Extract the current frame
    frame = double(ch1(:, :, m));
    
    % Perform the Fast Fourier Transform (FFT)
    fftResult = fftshift(fft2(frame));
    
    % Calculate the power spectrum (magnitude squared)
    powerSpectrum = abs(fftResult).^2;
    
    % Save the FFT result and power spectrum
    filenameFFT = sprintf('fft_result_frame%d.png', m);
    filenamePowerSpectrum = sprintf('power_spectrum_frame%d.png', m);
    imwrite(mat2gray(log(1 + abs(fftResult))), fullfile(folderName, filenameFFT));
    imwrite(mat2gray(log(1 + powerSpectrum)), fullfile(folderName, filenamePowerSpectrum));
end
