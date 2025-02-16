

function DecResult = F11_LRDeconv(stackIn,PSFIn,itNum)

% normalize to 1 in total
psfSum = sum(PSFIn(:));
psfNorm = PSFIn ./ psfSum;

%% 3D deconvolution
DecResult = DL2.RL(single(stackIn), single(psfNorm), itNum);

% imgDec = DecResult(:,:,2);

end