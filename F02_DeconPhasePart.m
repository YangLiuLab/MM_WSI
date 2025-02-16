
% Calculate phase image

function phaseFinal = F02_DeconPhasePart(namePos,nameChan,imgPath,nStack,nAve,rPara,stepSize)
%% 1. Set phase retrival parameters
load('SubCoord.mat');
k = strfind(nameChan, '_Em');
EmWaveLen = str2num(nameChan(k+3:k+5));

Pixelsize = 320e-9;			% Pixelszie (m)
lambda = EmWaveLen*1e-9;	% Wavelength (m)
k = 2*pi/lambda;			% Wave number
IntThr = 0.01;


%% 2. Read image stack
nameWF = [];
imgStack = F12_ReadImgStack(imgPath,namePos,nameChan,nameWF,nStack,nAve);


%% 3. Decon sub images and merge WF
dim = size(imgStack);
distArray = [1,2];

imgDec = single(zeros(dim(1),dim(2),length(distArray)));
countsI = single(zeros(dim(1),dim(2),length(distArray)));
focalArray = zeros(1,54);

for iSub = 1:54
	curImgStack = imgStack(xst_big(iSub):xed_big(iSub),yst_big(iSub):yed_big(iSub),:);
	
	% find focal plan
	nvaArray = zeros(1,nStack);
	dim = size(imgStack);
	for i = 1:nStack
		curImg = curImgStack(:,:,i);
	% 	curImg = imgStack(:,:,i);
		imgMed = medfilt2(curImg,[3,3]);

		% Normalized variance
		meanValue = mean(imgMed(:));
		sqValue = (imgMed - meanValue) .* (imgMed - meanValue);
		nvaValue = sum(sqValue(:))/(dim(1)*dim(2)*meanValue);
		nvaArray(i) = nvaValue;
	end

	[~,minIdx] = min(nvaArray);

	if minIdx > nStack-2
		focalPos = nStack-2;
	elseif minIdx < 3
		focalPos = 3;
	else
		focalPos = minIdx;
	end
	
	focalArray(iSub) = focalPos;
	
	for iDist = 1:length(distArray)

		dist = distArray(iDist);

		I0 = curImgStack(:,:,focalPos);
		Iz = curImgStack(:,:,focalPos - dist);
		I_z = curImgStack(:,:,focalPos + dist);

		% Axial intensity derivative
		dz = dist*stepSize;
		dIdz = (Iz-I_z)/(2*dz);

		% Valid domain within the apecture
		Aperture = ones(size(I0));
		Aperture(I0<max(max(I0))/10)=NaN;

		% Solve TIE with FFT-TIE
		phi_FFT = TIE_FFT_solution(dIdz,I0,Pixelsize,k,rPara,IntThr);
		
		% Non-negative
		imgPhasePart = phi_FFT;
		imgPhasePart = (imgPhasePart+10)*1000;
		imgPhasePart(imgPhasePart<0) = 0;
		
		% Generate mask for linear stitching
		alpha = 1.5;
		size_I = size(imgPhasePart);
		w_mat = single(compute_linear_blend_pixel_weights(size_I, alpha));
		imgPhasePart = imgPhasePart .* w_mat;
		
		% Stitch parts and masks
		imgDec(xst_big(iSub):xed_big(iSub),yst_big(iSub):yed_big(iSub),iDist) =...
			imgDec(xst_big(iSub):xed_big(iSub),yst_big(iSub):yed_big(iSub),iDist) + imgPhasePart;
		
		countsI(xst_big(iSub):xed_big(iSub),yst_big(iSub):yed_big(iSub),iDist) =...
			countsI(xst_big(iSub):xed_big(iSub),yst_big(iSub):yed_big(iSub),iDist) + w_mat;
	end	
	
end

imgDec = imgDec./countsI;
focalArray = reshape(focalArray,[9,6])

%% Average phase image
phaseFinal = mean(imgDec,3);

end



%% transform image
function imgTrans = fun_TransImage(imgDec, EmWaveLen)

load('tformSingleNew.mat');

%% Select transform matrix

if 438 == EmWaveLen
	tform = tform438;
elseif 494 == EmWaveLen
	tform = tform494;
elseif 510 == EmWaveLen
	tform = tform510;
elseif 549 == EmWaveLen
	tform = tform549;
elseif 615 == EmWaveLen
	tform = tform615;
elseif 631 == EmWaveLen
	tform = tform631;
elseif 676 == EmWaveLen
	tform = tform676;
elseif 692 == EmWaveLen
	tform = tform_692;
else
	tform = [1,1,1;1,1,1;1,1,1];
end

%% Image transformation
if 572 == EmWaveLen
	imgTrans = imgDec;
else
	imgTrans = imwarp(imgDec,tform,'OutputView',imref2d(size(imgDec)));
end

end


%% Create mask for local focusing fusion
function w_mat = compute_linear_blend_pixel_weights(size_I, alpha)
d_min_mat_i = zeros(size_I(1), 1);
d_min_mat_j = zeros(1, size_I(2));
for i = 1:size_I(1)
    d_min_mat_i(i,1) = min(i, size_I(1) - i + 1);
end
for j = 1:size_I(2)
    d_min_mat_j(1,j) = min(j, size_I(2) - j + 1);
end

w_mat = d_min_mat_i*d_min_mat_j;
w_mat = w_mat.^alpha;

end







