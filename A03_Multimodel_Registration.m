clc;clear all;close all;

%% read H&E (.svs) data
%------------------------------------
% Set 1: path and name of H&E image
%------------------------------------
svsPath = 'E:\230926_TissueImages\GR1000416_Register\HE\';
svsName = '00_GR1000416_HE.svs';

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
movePath = 'E:\230926_TissueImages\GR1000416_Register\';
fileName = 'GR1000416_Cy1_Ro1_Co1_Ex650_Em676_Stitch_Reg';

fullName = strcat(movePath,fileName);
imgCur = single(imread(fullName,'tiff',1));
fluoRmv = imgCur - mean(imgCur(:));
fluoRmv(fluoRmv<0) = 0;
imgMove = imadjust(fluoRmv./max(fluoRmv(:)));
imgMove = imresize(imgMove,1,"bilinear");

%------------------------------------
% Set 3: rotation angle
%------------------------------------
angle = 90;
imgMove = imrotate(imgMove,angle,'bilinear');
figure();imshow(imgMove,[]);


figure();imshowpair(imgMove,imgRef,"Scaling","joint")
return;

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

savePath = strcat(movePath,'HEreg','\'); mkdir(savePath);

dimSVS = size(svsOrg);
myFiles = dir(movePath);
for iFile = 1:length(myFiles)
	fileName = myFiles(iFile).name;
	[cur_path,cur_name,cur_ext] = fileparts(fileName);
	
	if ~(myFiles(iFile).isdir) && strcmp(cur_ext,'.tiff') 
		
		fullName = strcat(movePath,fileName);
		imgCur = single(imread(fullName,'tiff',1));
		
		fluoPad = imrotate(imgCur,angle,'bilinear');
		fluoPad = imresize(fluoPad,1/2,"bilinear");
		imgAfterReg = imwarp(fluoPad,tform,"OutputView",imref2d(size(imgRef)));
		
		nameWrite = strcat(savePath,cur_name,'_HEreg.tiff');
		saveastiff(uint16(imgAfterReg),nameWrite,options);
	end
end

return;





