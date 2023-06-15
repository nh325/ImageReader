# ImageReader

# RadonScript: 
- Upload a TIFF file
- Input appropriate channel and slice number
- Draw circle ROI for Radon transform and std dev plot
- Save to directory

# RadonFunctions:
- Has functions for subsections of RadonScript
- Iterates over slices and automates ROI selection
- Input ROI radius and movement steps
- Save each Radon transform, std dev plot, saves data

# loaddata:
- Access data from RadonFunctions (width, height, area under std dev curve)

# plotdata:
- Access data from RadonFunctions (width, height, area under std dev curve)
- Plot boxplots for each data type

# FFTScript
- Upload TIFF file
- Input appropriate channel and slice number
- Perform FFT on each slice
- Save to directory
