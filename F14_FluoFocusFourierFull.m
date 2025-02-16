%% function: Find focal plan
function [focus,gradxy] = F14_FluoFocusFourierFull(imgStack)

%% Define the area for focus calculation

dim = size(imgStack);
gradxy = zeros(1,dim(3));

for i = 1:dim(3)
	curImg = imgStack(:,:,i);
	temp = medfilt2(curImg,[3,3]);

	spec = abs(fftshift(fft2(curImg)));
	spec  = spec - mean(spec(:));
	
	radius = 200;
	[columnsInImage, rowsInImage] = meshgrid(1:dim(2), 1:dim(1));
    circlePixels = (rowsInImage - dim(1)/2).^2 ...
        + (columnsInImage - dim(2)/2).^2 <= radius.^2;
	imgLarge = spec.*circlePixels;
	sumLarge = sum(imgLarge(:));	
	
	radius = 50;
	[columnsInImage, rowsInImage] = meshgrid(1:dim(2), 1:dim(1));
    circlePixels = (rowsInImage - dim(1)/2).^2 ...
        + (columnsInImage - dim(2)/2).^2 <= radius.^2;
	imgLow = spec.*circlePixels;
	sumLow = sum(imgLow(:));
	
	sumHigh = sumLarge - sumLow;
	ratio = sumHigh / sumLow;
	gradxy(i) = ratio;

end

[~,focus] = max(smooth(gradxy));


end