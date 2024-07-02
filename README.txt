This folder contains the MATLAB scripts used for gel analysis in this study. The workflow for analyzing gel images over time is as follows:

1. Image Preparation: Individual gel images in a time series were cropped and converted to .mat files using the 'GelImagesToMat.m' script.
2. Size and Curvature Analysis: 
   - For monolayer gels, size change analysis was performed using 'GelSizeAnalysis.m'.
   - For bilayer gels, curvature change analysis was conducted using 'BilayerCurvature.m'.
   - 'IMGIpfilter.m' contains helper functions for image analysis, applying a low-pass filter to remove background noise.
   - 'histogram_stretch.m' contains helper functions for image analysis, conducting histogram stretching to enhance contrast.
3. Video Generation: The .mat files generated in step 2 can be used to generate time series videos using the 'SuppVideo1_5.m' script.

For additional details, please refer to the Methods section.
Other scripts generated in this study can be found here:
https://github.com/charliecharlie29/Hydrogel-Automata-Directed-By-DNA-Codes