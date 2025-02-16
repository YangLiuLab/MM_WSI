%% function: Read image stack
function img_stack = F12_ReadImgStack(imgPath,namePos,nameChan,nameWF,nStack,nAve)

% Read image stack
img_stack = [];

if 0 == nAve
	for iStack = 1:nStack
		nameStack = strcat('La',num2str(iStack));

		if isempty(nameWF)
			nameAll = strcat(namePos,'_',nameStack,'_',nameChan);
		else
			nameAll = strcat(namePos,'_',nameStack,'_',nameChan,'_',nameWF);
		end

		fileName = fullfile(imgPath,nameAll);
		imgCur = single(imread(fileName,'tiff',1));

		img_stack = cat(3,img_stack,imgCur);
	end
else
	for iStack = 1:nStack
		nameStack = strcat('La',num2str(iStack));

		imgRep = [];
		for iAve = 1:nAve
			nameRep = strcat('Rp',num2str(iAve));
			nameAll = strcat(namePos,'_',nameStack,'_',nameRep,'_',nameChan);
			fileName = fullfile(imgPath,nameAll);
			imgCur = single(imread(fileName,'tiff',1));
			imgRep = cat(3,imgRep,imgCur);
		end

		imgAve = mean(imgRep,3);
		img_stack = cat(3,img_stack,imgAve);
	end
end


end