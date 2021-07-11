# TUDImageProcessing
Repository for Image Processing script

IMPROCESSING Droplet and particle velocimetry and morphometry script
   imProcessing.m handles each aspect from the processing of a video, the
   analysis of the images, and saving the resulting properties. The
   regionprops module of MATLAB's ImageProcessing Toolbox is the core of
   this script that handles the droplet/particle detection. Both grayscale
   and RGB are supported. RGB videos are converted to grayscale for furter
   processing.
