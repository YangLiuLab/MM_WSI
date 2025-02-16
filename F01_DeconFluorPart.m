%% Function: Deconv two single WFs
function imgFinal = F01_DeconFluorPart(namePos,nameChan,imgPath,psfPath,itNum,gpuFlag,nStack,is_RL_Recon,nAve,rstPath)

load('SubCoord.mat');
sideNum = 1;

k = strfind(nameChan, '_Em');
EmWaveLen = str2num(nameChan(k+3:k+5));


%% Decon the 1st WF
% 1. Read image stack
nameWF = [];
img_stack = F12_ReadImgStack(imgPath,namePos,nameChan,nameWF,nStack,nAve);

% 2. flat field correction
dim = size(img_stack);
for i = 1:dim(3)
	img_stack(:,:,i) = fun_FlatCorrect(img_stack(:,:,i), EmWaveLen);
end

% 3. remove background 
img_Pre = F13_Preprocess(img_stack);

% 4. Decon sub images and merge WF
dim = size(img_Pre);
imgBlank = double(zeros(dim(1), dim(2), 2));
imgDec = [];
focalArray = [];
for iSub = 1:54
	SubStack = img_Pre(xst_big(iSub):xed_big(iSub),yst_big(iSub):yed_big(iSub),:);
	
	% find fluo focus
	imgFocus = F14_FluoFocusFourierFull(SubStack);
	if imgFocus == 1
		imgFocus = 2;
	elseif imgFocus == nStack
		imgFocus = nStack-1;
	end
	Img = double(SubStack(:,:,imgFocus-sideNum:imgFocus+sideNum));
	focalArray = cat(2,focalArray,imgFocus);
	
	% read psf stack
	psfStack = [];
	psfFile = strcat(psfPath,num2str(EmWaveLen),'\psf\',num2str(EmWaveLen),'_',num2str(iSub));
	for iPSF = 1:30
		curPsf = single(imread(psfFile,'tiff',iPSF));
		psfStack = cat(3,psfStack,curPsf);
	end

	% find psf focus
	[~,psf_focal] = max(max(psfStack,[],[1,2]));
	if psf_focal == 30
		psf_focal = 29;
	end

	% load 3 psf layers
	psf = [];
	psf = double(psfStack(:,:,psf_focal-sideNum : psf_focal+sideNum));
	
	if is_RL_Recon
		% R-L deconvolution
		curDec = F11_LRDeconv(Img,psf,50);
	else
		% W-B deconvolution
		curDec = F11_WBDeconv(Img,psf,gpuFlag,itNum);
	end
	
	imgBlank(:,:,2) = 0;
	imgBlank(x_start(iSub):x_end(iSub),y_start(iSub):y_end(iSub),2)...
		= curDec(xst_loc(iSub):xed_loc(iSub),yst_loc(iSub):yed_loc(iSub),sideNum+1);
	imgDec = max(imgBlank,[],3);
	imgBlank(:,:,1) = imgDec;
end

focalArray = reshape(focalArray,[9,6])

% Transform image
imgTrans = fun_TransImage(imgDec, EmWaveLen);

% Rolling ball filter
se = strel('disk',30);
imgFinal = imtophat(imgTrans,se);


end


%% function: Read psf
function psf = Fun_ReadPSFStack(psfPath,EmWaveLen,sideNum,iSub)

if 438==EmWaveLen
	psfFocus = 6;
elseif 494==EmWaveLen
	psfFocus = 7;
elseif 510==EmWaveLen
	psfFocus = 4;
elseif 549==EmWaveLen
	psfFocus = 6;
elseif 572==EmWaveLen
	psfFocus = 9;
elseif 615==EmWaveLen
	psfFocus = 11;
elseif 631==EmWaveLen
	psfFocus = 10;
elseif 676==EmWaveLen
	psfFocus = 10;
elseif 692==EmWaveLen
	psfFocus = 11;
else
	psfFocus = 8;
end

psf = [];
psfFile = strcat(psfPath,num2str(EmWaveLen),'\psf\',num2str(EmWaveLen),'_',num2str(iSub));
for iPSF = psfFocus-sideNum : psfFocus+sideNum
	curPsf = single(imread(psfFile,'tiff',iPSF));
	psf = cat(3,psf,curPsf);
end

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

%% flat correction
function imgCorrect = fun_FlatCorrect(imgTrans, EmWaveLen)

if 438 == EmWaveLen
	map = double(imread('correction_map_438.tiff'));
elseif 494 == EmWaveLen
	map = double(imread('correction_map_438.tiff'));
elseif 510 == EmWaveLen
	map = double(imread('correction_map_510.tiff'));
elseif 549 == EmWaveLen
	map = double(imread('correction_map_510.tiff'));
elseif 572 == EmWaveLen
	map = double(imread('correction_map_572.tiff'));
elseif 615 == EmWaveLen
	map = double(imread('correction_map_615.tiff'));
elseif 631 == EmWaveLen
	map = double(imread('correction_map_615.tiff'));
elseif 676 == EmWaveLen
	map = double(imread('correction_map_676.tiff'));
elseif 692 == EmWaveLen
	map = double(imread('correction_map_676.tiff'));
end

map = map/100;
imgCorrect = imgTrans./map;

end


