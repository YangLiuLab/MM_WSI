function focalMx = F00_FluoAndPhaseRecon(imgPath,psfPath,is_RL_Recon,rPara,stepSize,is_Phase,is_Fluo)

% set parameters
itNum = 1;
gpuFlag = 0;

rRow = [44,8243];
rCol = [72,5571];

options.message   = false;
options.overwrite = true;

focalMx = [];

%% Parse imaging information
nRow = 0;
nCol = 0;
nStack = 0;
nAve = 0;
strChan = [];

myFiles = dir(imgPath);
for iFile = 1:length(myFiles)
	fileName = myFiles(iFile).name;
	[cur_path,cur_name,cur_ext] = fileparts(fileName);
	
	if ~(myFiles(iFile).isdir) && strcmp(cur_ext,'.tiff') 
		% Rows 
		k = strfind(fileName, '_Ro');
		curRow = str2num(fileName(k+3));
		if curRow > nRow
			nRow = curRow;
		end
		
		% Columns
		k = strfind(fileName, '_Co');
		curCol = str2num(fileName(k+3));
		if curCol > nCol
			nCol = curCol;
		end
		
		% Channels
		k1 = strfind(fileName, '_Ex');
		k2 = strfind(fileName, '_Em');
		chanName = fileName(k1+1:k2+5);
		
		ExWL = chanName(3:5);
		if ~sum(strcmpi(strChan,chanName))
			strChan{end+1} = chanName;
		end
		
		% z stack number
		k0 = strfind(fileName, '_Rp');
		if isempty(k0)
			k1 = strfind(fileName, '_La');
			k2 = strfind(fileName, '_Ex');
			curStack = str2num(fileName(k1+3:k2-1));
			if curStack > nStack
				nStack = curStack;
			end
		else
			k1 = strfind(fileName, '_La');
			curStack = str2num(fileName(k1+3:k0-1));
			if curStack > nStack
				nStack = curStack;
			end
			
			k2 = strfind(fileName, '_Ex');
			curAve = str2num(fileName(k0+3:k2-1));
			if curAve > nAve
				nAve = curAve;
			end
		end
		
		% preName
		k = strfind(fileName, '_Ro');
		namePre = fileName(1:k-1);
	end
end
nChan = length(strChan);

% nAve = 1;
nRow = 1;
nCol = 1;

%% Deconvolution
rstPath = strcat(imgPath,'\DecRsltWithBack','\'); mkdir(rstPath);

imgAllPos = [];
for iChan = 1:nChan
	nameChan = strChan{iChan};
	ExWL = nameChan(3:5);
	if strcmp(ExWL,'000')
		if is_Phase
			for iRow = 1:nRow
				for iCol = 1:nCol
					fprintf('Chan:%d-%d Row:%d-%d Colume:%d-%d.\n',iChan,nChan,iRow,nRow,iCol,nCol);
					namePos = strcat(namePre,'_Ro',num2str(iRow),'_Co',num2str(iCol));

					% Phase retrieval
					imgPhase = F02_DeconPhasePart(namePos,nameChan,imgPath,nStack,nAve,rPara,stepSize);

					% Write image
					nameWrite = strcat(rstPath,namePos,'_',nameChan,'_','Dec.tiff');
					saveastiff(uint16(imgPhase(rRow(1):rRow(2),rCol(1):rCol(2))),nameWrite,options);
				end
			end
		end
	else
		if is_Fluo
			for iRow = 1:nRow
				for iCol = 1:nCol
					fprintf('Chan:%d-%d Row:%d-%d Colume:%d-%d.\n',iChan,nChan,iRow,nRow,iCol,nCol);
					namePos = strcat(namePre,'_Ro',num2str(iRow),'_Co',num2str(iCol));

					% Fluorescence Deconvolution
					imgDec = F01_DeconFluorPart(namePos,nameChan,imgPath,psfPath,itNum,gpuFlag,nStack,is_RL_Recon,nAve,rstPath);

					% Write image
					nameWrite = strcat(rstPath,namePos,'_',nameChan,'_','Dec.tiff');
					saveastiff(uint16(imgDec(rRow(1):rRow(2),rCol(1):rCol(2))),nameWrite,options);
				end
			end
		end
	end
end


%% Stitch images
if nRow == 1 && nCol == 1
	return;
end

% make stitch folder
stitchPath = strcat(imgPath,'\Stitch','\'); mkdir(stitchPath);

%---------------------------------------------------------------------------------------------
% Generate grid
%-----------------------------------------------------------------------------------------------
img_name_grid = cell(nRow,nCol,nChan);
for iChan = 1:nChan
	nameChan = strChan{iChan};
	ExWL = nameChan(3:5);
	for iRow = 1:nRow
		for iCol = 1:nCol
			namePos = strcat(namePre,'_Ro',num2str(iRow),'_Co',num2str(iCol));
			nameAll = strcat(namePos,'_',nameChan,'_Dec.tiff');
			img_name_grid{iRow,iCol,iChan} = nameAll;
		end
	end
end

% Stitch tiles
I_array = F03_StitchTiles(img_name_grid,stitchPath,rstPath);

% Save stitched images
for i = 1:size(img_name_grid,3)
	temp_img_name_grid = img_name_grid(:,:,i);
	nameOrg = temp_img_name_grid{1};
	k = strfind(nameOrg, '_Ro');
	namePart1 = nameOrg(1:k-1);
	k1 = strfind(nameOrg, '_Ex');
	k2 = strfind(nameOrg, '_Dec');
	namePart2 = nameOrg(k1:k2-1);
	
	nameWrite = strcat(stitchPath,namePart1,namePart2,'_Stitch.tiff');
	saveastiff(uint16(I_array(:,:,i)),nameWrite,options);
end

end