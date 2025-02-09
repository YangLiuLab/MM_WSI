# A multi-modal whole-slide image processing pipeline for quantitative mapping of tissue architecture, histopathology, and tissue microenvironment

## 1. Data scope
    This data set is the example data for multi-modal whole-slide image processing pipeline.
    This data is collected for multi-layer reconstruction, multi-tile stitching, multi-cycle alignment and multi-modal registration.

## 2. Data structure
    Folder 'GR1000426_Cy2' contains the 1st cycle of fluorescence and brightfield images.
    Folder 'GR1000426_Cy4' contains the 2st cycle of fluorescence and brightfield images.
    Folder 'Multi_Cycle_Register' contains the reconstructed and registered images.
    Data 'gr1000426.svs' is the corresponding H&E image.

## 3. Format of the data name
    The fluorescence image 'SW480_Cy1_Ro1_Co1_La2_Ex589_Em615.tiff' has a corresponding bright-field image for phase retrieval named ‘SW480_Cy1_Ro1_Co1_La2_Ex000_Em615.tiff’.
    For the fluorescence image:
	(1) 'SW480' is the predefined name, usually describing the experimental target.
	(2) 'Ro1_Co1' defines the tile information, with Ro1 representing the 1st row and Co1 representing the 1st column.
	(3) 'La2' defines the layer information, with La2 indicating the 2nd layer.
	(4) 'Ex589_Em615' defines the excitation and emission wavelengths, with the excitation wavelength being 589 nm and the emission wavelength being 615 nm.
    For the bright-field image: 
	The only difference between the bright-field image and the corresponding fluorescence image is that the excitation wavelength is set to 'Ex000'.

## 4. Reference
	A multi-modal whole-slide image processing pipeline for quantitative mapping of tissue architecture, histopathology, and tissue microenvironment
