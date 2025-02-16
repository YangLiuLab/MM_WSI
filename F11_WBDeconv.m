

function imgDec = F11_WBDeconv(stackIn,PSFIn,gpuFlag,itNum)

[Sx, Sy, Sz] = size(stackIn);

% Forward projector
PSF1 = PSFIn/sum(PSFIn(:));

% Back projector
bp_type = 'wiener-butterworth';
alpha = 0.05;
beta = 1; 
n = 10;
resFlag = 2;
iRes = [3,3,5];
verboseFlag = 0;
[PSF2, ~] = BackProjector(PSF1, bp_type, alpha, beta, n, resFlag, iRes, verboseFlag);
PSF2 = PSF2/sum(PSF2(:));

% deconvolution
PSF_fp = align_size(PSF1, Sx,Sy,Sz);
PSF_bp = align_size(PSF2, Sx,Sy,Sz);

if(gpuFlag)
	OTF_fp = fftn(ifftshift(gpuArray(single(PSF_fp))));
	OTF_bp = fftn(ifftshift(gpuArray(single(PSF_bp))));
else
	OTF_fp = fftn(ifftshift(PSF_fp));
	OTF_bp = fftn(ifftshift(PSF_bp));
end
smallValue = 0.001;

if(gpuFlag)
	stack = gpuArray(single(stackIn));
else
	stack = stackIn;
end
stack = max(stack,smallValue);

% Measured image as initialization
stackEstimate = stack;
for i = 1:itNum
	stackEstimate = stackEstimate.*ConvFFT3_S(stack./...
	ConvFFT3_S(stackEstimate, OTF_fp),OTF_bp);
	stackEstimate = max(stackEstimate,smallValue);
end

if(gpuFlag)
	imgDec = gather(stackEstimate);
else
	imgDec = stackEstimate;
end

end



%% Function
function img2 = align_size(img1,Sx2,Sy2,Sz2,padValue)
if(nargin == 4)
    padValue = 0;
end

[Sx1,Sy1,Sz1] = size(img1);
Sx = max(Sx1,Sx2);
Sy = max(Sy1,Sy2);
Sz = max(Sz1,Sz2);
imgTemp = ones(Sx,Sy,Sz)*padValue;

Sox = round((Sx-Sx1)/2)+1;
Soy = round((Sy-Sy1)/2)+1;
Soz = round((Sz-Sz1)/2)+1;
imgTemp(Sox:Sox+Sx1-1,Soy:Soy+Sy1-1,Soz:Soz+Sz1-1) = img1;


Sox = round((Sx-Sx2)/2)+1;
Soy = round((Sy-Sy2)/2)+1;
Soz = round((Sz-Sz2)/2)+1;
img2 = imgTemp(Sox:Sox+Sx2-1,Soy:Soy+Sy2-1,Soz:Soz+Sz2-1);
end


%% function
function [outVol] = ConvFFT3_S(inVol,OTF)

outVol = single(real(ifftn(fftn(inVol).*OTF)));  

end

