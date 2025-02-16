% register different cycles
clc;clear all;close all;

% writing parameters
options.message   = false;
options.overwrite = true;

%% Setting area

% 1. set crop parameters
% sw480_5Fu_3d_Cy1
% 1.1 Set the coordinate of the starting point [x,y]
sPoint = [672,640];
% 1.2 Set the size of the crop area [width,hight]
sizeCut = [19296,20352];


% 2. set the folder path of the reference image
refPath = 'F:\231030_BFStitch\SW480_R_Cy1\';

% 3. set the folder path of the register image
movePathPart = 'F:\231030_BFStitch\SW480_R_Cy';


%% get ref fluo image
% crop images
ifCrop = 1;
if ifCrop
	regPath = strcat(refPath,'Register'); mkdir(regPath);
	myFiles = dir(refPath);
	for iFile = 1:length(myFiles)
		if ~(myFiles(iFile).isdir)
			fileName = myFiles(iFile).name;
			[cur_path,cur_name,cur_ext] = fileparts(fileName);
			
			imgRead = imread(strcat(refPath,fileName));
			imgCrop = imgRead(sPoint(2):sPoint(2)+sizeCut(2)-1,sPoint(1):sPoint(1)+sizeCut(1)-1);
			nameWrite = strcat(regPath,'\',cur_name,'_Reg.tiff');
			saveastiff(uint16(imgCrop),nameWrite,options);
		end
	end
end

%% get reference image
imgRefBuff = [];
myFiles = dir(refPath);
for iFile = 1:length(myFiles)
	fileName = myFiles(iFile).name;
	[cur_path,cur_name,cur_ext] = fileparts(fileName);
	
	if ~(myFiles(iFile).isdir) && strcmp(cur_ext,'.tiff') 
		% Channels
		k1 = strfind(fileName, '_Ex');
		k2 = strfind(fileName, '_Em');
		chanName = fileName(k1+1:k2+5);
		exName = fileName(k1+1:k2-1);
		if strcmpi(exName,'Ex000')
			if strcmpi(chanName,'Ex000_Em438')
				continue;
			else
				fullName = strcat(refPath,fileName);
				imgCur = single(imread(fullName,'tiff',1));
				imgRefBuff = cat(3,imgRefBuff,imgCur);
			end
		end
	end
end

imgRefOrg = mean(imgRefBuff,3);
imgRef = imgRefOrg(sPoint(2):sPoint(2)+sizeCut(2)-1,sPoint(1):sPoint(1)+sizeCut(1)-1);

imgRef = imgRef - min(imgRef(:));
imgRef = imadjust(imgRef/max(imgRef(:)));
figure();imshow(imgRef,[]);
clear imgRefBuff;

%% get move fluo image

for num = 2:7
movePath = strcat(movePathPart,num2str(num),'\')

imgMoveBuff = [];
myFiles = dir(movePath);
for iFile = 1:length(myFiles)
	fileName = myFiles(iFile).name;
	[cur_path,cur_name,cur_ext] = fileparts(fileName);
	
	if ~(myFiles(iFile).isdir) && strcmp(cur_ext,'.tiff') 
		
		% Channels
		k1 = strfind(fileName, '_Ex');
		k2 = strfind(fileName, '_Em');
		chanName = fileName(k1+1:k2+5);
		exName = fileName(k1+1:k2-1);
		if strcmpi(exName,'Ex000')
			if strcmpi(chanName,'Ex000_Em438')
				continue;
			else
				fullName = strcat(movePath,fileName);
				imgCur = single(imread(fullName,'tiff',1));
				imgMoveBuff = cat(3,imgMoveBuff,imgCur);
			end
		end
	end
end

imgMoveOrg = mean(imgMoveBuff,3);
imgMove = imgMoveOrg(sPoint(2):sPoint(2)+sizeCut(2)-1,sPoint(1):sPoint(1)+sizeCut(1)-1);

imgMove = imgMove - min(imgMove(:));
imgMove = imadjust(imgMove/max(imgMove(:)));
figure();imshow(imgMove,[]);
clear imgMoveBuff;
% 
% figure();imshowpair(imgRef, imgMove,'Scaling','joint');


%% SIFT registration

% Detect SIFT features in ref images
metric_threshold = 10000;	% Larger threshold returns fewer feature points
metric_step = 1000;
maxPoint = 100000;
minPoint = 10000;

siftPoints1 = detectSURFFeatures(imgRef,'MetricThreshold',metric_threshold,'NumOctaves',2);
pNum_1 = size(siftPoints1);
while(pNum_1(1) > maxPoint)
	metric_threshold = metric_threshold + metric_step;
	siftPoints1 = detectSURFFeatures(imgRef,'MetricThreshold',metric_threshold,'NumOctaves',2);
	pNum_1 = size(siftPoints1);
end
while(pNum_1(1) < minPoint)
	metric_threshold = metric_threshold - metric_step;
	siftPoints1 = detectSURFFeatures(imgRef,'MetricThreshold',metric_threshold,'NumOctaves',2);
	pNum_1 = size(siftPoints1);
end

% Detect SIFT features in Move images
metric_threshold = 10000;	% Larger threshold returns fewer feature points
siftPoints2 = detectSURFFeatures(imgMove,'MetricThreshold',metric_threshold,'NumOctaves',2);
pNum_2 = size(siftPoints2);
while(pNum_2(1) > maxPoint)
	metric_threshold = metric_threshold + metric_step;
	siftPoints2 = detectSURFFeatures(imgMove,'MetricThreshold',metric_threshold,'NumOctaves',2);
	pNum_2 = size(siftPoints2);
end
while(pNum_2(1) < minPoint)
	metric_threshold = metric_threshold - metric_step;
	siftPoints2 = detectSURFFeatures(imgMove,'MetricThreshold',metric_threshold,'NumOctaves',2);
	pNum_2 = size(siftPoints2);
end

% Extract SIFT descriptors for the detected SIFT features
[features1, validPoints1] = extractFeatures(imgRef, siftPoints1);
[features2, validPoints2] = extractFeatures(imgMove, siftPoints2);

% Match SIFT features between the two images
indexPairs = matchFeatures(features1, features2);
matchedPoints1 = validPoints1(indexPairs(:, 1), :);
matchedPoints2 = validPoints2(indexPairs(:, 2), :);

% figure();showMatchedFeatures(imgRef,imgMove,matchedPoints1,matchedPoints2);

% Estimate geometric transformation between the two images
% tform = estimateGeometricTransform(matchedPoints2, matchedPoints1, 'similarity','MaxNumTrials',20000);
tform = estgeotform2d(matchedPoints2, matchedPoints1, 'similarity','MaxNumTrials',20000);


% Apply geometric transformation to one of the images
registeredImage = imwarp(imgMove, tform, 'OutputView', imref2d(size(imgRef)));

% 
% figure();imshowpair(imgRef,registeredImage,'Scaling','joint');

% return;

%% register and rewrite all the files
regPath = strcat(movePath,'Register'); mkdir(regPath);
myFiles = dir(movePath);
for iFile = 1:length(myFiles)
	if ~(myFiles(iFile).isdir)
		fileName = myFiles(iFile).name;
		[cur_path,cur_name,cur_ext] = fileparts(fileName);
		
		imgRead = imread(strcat(movePath,fileName));
		imgCrop = imgRead(sPoint(2):sPoint(2)+sizeCut(2)-1,sPoint(1):sPoint(1)+sizeCut(1)-1);
		
		imgReg = imwarp(imgCrop,tform,'OutputView',imref2d(size(imgCrop)));
		
		nameWrite = strcat(regPath,'\',cur_name,'_Reg.tiff');
		saveastiff(uint16(imgReg),nameWrite,options);
	end
end

end

return;

%% Image transform using imageJ parameters
tMatrix = [[0.999977268700612, 0.006742557531337, 19.36449307701678]', [-0.006742557531337, 0.999977268700612, -49.47662952840892]',[0,0,1]'];
tform = affine2d(tMatrix);

options.message   = false;
options.overwrite = true;

savePath = 'G:\00_MultiplexData\JX_Data\02-07-2023';
rstPath = 'G:\00_MultiplexData\JX_Data\02-07-2023\sw480-Crl_Cy5\DecRslt';

fileList = [{'sw480-Crl_Cy5_Ro1_Co3_Ex470_Em510_Dec.tiff'},{'sw480-Crl_Cy5_Ro1_Co3_Ex530_Em572_Dec.tiff'},...
			{'sw480-Crl_Cy5_Ro1_Co3_Ex589_Em615_Dec.tiff'},{'sw480-Crl_Cy5_Ro1_Co3_Ex650_Em676_Dec.tiff'}];

for i = 1:length(fileList)
	fileName = fileList{i};
	nameRead = strcat(rstPath,'\',fileName);
	imgCy2 = single(imread(nameRead,'tiff',1));
	imgNew = imwarp(imgCy2,tform,'OutputView',imref2d(size(imgCy2)));
	nameWrite = strcat(savePath,'\',fileName);
	saveastiff(uint16(imgNew),nameWrite,options);
end


return;


