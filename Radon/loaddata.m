% Load the analysis results
load(fullfile(folderName, 'analysis_results.mat'));

% Access the width, height, and area attributes for all ROIs within each frame and all the frames
for m = 1:numel(results)
    frameResults = results(m);
    roiWidths = frameResults.Width;
    roiHeights = frameResults.Height;
    roiAreas = frameResults.Area;
    roiPseudo = frameResults.PseudoFWHM;
    
    fprintf('Frame %d:\n', m);
    for n = 1:numel(roiWidths)
        fprintf('ROI %d: Width = %.2f, Height = %.2f, Area = %.2f\n, PseudoFWHM = %.2f\n', n, roiWidths{n}, roiHeights{n}, roiAreas{n}, roiPseudo{n});
    end
    fprintf('\n');
end
