%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main code for multi-modal alignment.
%
% Related Reference:
% "A multi-modal image processing pipeline for quantitative 
% sub-cellular mapping of tissue architecture, histopathology, 
% and tissue microenvironment"
%
% last modified on 09/13/2024
% by Maomao Chen, Yang Liu (liuy46@illinois.edu)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc;clear all;close all;

%% read H&E (.svs) data
%------------------------------------
% Set 1: path and name of H&E image
%------------------------------------
svsPath = 'D:\Example Data\';
svsName = 'gr1000426.svs';

svsFullName = fullfile(svsPath,svsName);
svsRGB = single(imread(svsFullName,'svs',1));
svsOrg = svsRGB(:,:,1);
svsCon = max(svsOrg(:))-svsOrg;
imgRef = imadjust(svsCon./max(svsCon(:)));
figure();imshow(imgRef,[]);

%% read fluo data
%------------------------------------
% Set 2: path and name of fluorescence image
%------------------------------------
movePath = 'D:\Example Data\Multi_Cycle_Registe\';
fileName = 'GR1000426_Cy4_Ex650_Em676_Stitch_Reg';

fullName = strcat(movePath,fileName);
imgCur = single(imread(fullName,'tiff',1));
fluoRmv = imgCur - mean(imgCur(:));
fluoRmv(fluoRmv<0) = 0;
imgMove = imadjust(fluoRmv./max(fluoRmv(:)));

%------------------------------------
% Set 3: rotation angle
%------------------------------------
angle = -90;
imgMove = imrotate(imgMove,angle,'bilinear');
ratio = 1/2;
imgMove = imresize(imgMove,ratio,"bilinear");
figure();imshow(imgMove,[]);

figure();imshowpair(imgMove,imgRef,"Scaling","joint")
% return;

%% mutual information registration
optimizer = registration.optimizer.OnePlusOneEvolutionary;
metric = registration.metric.MattesMutualInformation;

optimizer.GrowthFactor = 1.01;
optimizer.Epsilon = 1.5e-7;
optimizer.InitialRadius = 1e-3;
optimizer.MaximumIterations = 300;

tform = imregtform(imgMove,imgRef,"similarity",optimizer,metric);

%
fluoReg = imwarp(imgMove,tform,"OutputView",imref2d(size(imgRef)));
figure();imshowpair(imgRef,fluoReg,"Scaling","joint")


%% Transfer all images
options.message   = false;
options.overwrite = true;

savePath = strcat(movePath,'Multi_Modal_Register','\'); mkdir(savePath);

dimSVS = size(svsOrg);
myFiles = dir(movePath);
for iFile = 1:length(myFiles)
	fileName = myFiles(iFile).name;
	[cur_path,cur_name,cur_ext] = fileparts(fileName);
	
	if ~(myFiles(iFile).isdir) && strcmp(cur_ext,'.tiff') 
		
		fullName = strcat(movePath,fileName);
		imgCur = single(imread(fullName,'tiff',1));
		
		fluoPad = imrotate(imgCur,angle,'bilinear');
		fluoPad = imresize(fluoPad,ratio,"bilinear");
		imgAfterReg = imwarp(fluoPad,tform,"OutputView",imref2d(size(imgRef)));
		
		nameWrite = strcat(savePath,cur_name,'_HEreg.tiff');
		saveastiff(uint16(imgAfterReg),nameWrite,options);
	end
end

return;





