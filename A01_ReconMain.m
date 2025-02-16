
clc; close all; clear all;
addpath([pwd filesep 'subfunctions']);

%% Setting area

% 1. Set data path
dataPath = 'E:\SW480_drug_treatment_R2_RawData\SW480_Crl_4h_Cy2\';

% 2. Set deconvolution method
% 0: Fast deconvolution with lower accuracy
% 1: Slow deconvolution with higher accurarcy
is_RL_Recon = 0;

% 3. Regularization parameter and stepsize for phase recon
rPara = 1e-5;
stepSize = 1*1e-6;		% mm

% 4. Phase or Fluorescence
is_Phase = 1;
is_Fluo = 1;

% 5. Set path of the region-based PSFs
psfPath = 'E:\230801_PSF\';
javaaddpath([matlabroot filesep 'java' filesep 'DeconvolutionLab_2.jar'])

[dataName,imgPath] = uigetfile([dataPath,'*.*']);


%% Perform phase and fluorescence recon
focusMx = F00_FluoAndPhaseRecon(imgPath,psfPath,is_RL_Recon,rPara,stepSize,is_Phase,is_Fluo);

return;

