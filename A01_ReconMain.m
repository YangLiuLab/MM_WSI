%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main code for region-based deconvolution, phase retreival and 
% multi-tile stitching.
%
% Related Reference:
% "A multi-modal image processing pipeline for quantitative 
% sub-cellular mapping of tissue architecture, histopathology, 
% and tissue microenvironment"
%
% last modified on 09/13/2024
% by Maomao Chen, Yang Liu (liuy46@illinois.edu)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc; close all; clear all;
addpath([pwd filesep 'subfunctions']);
javaaddpath([matlabroot filesep 'java' filesep 'DeconvolutionLab_2.jar'])

%% Parameter settings
% 1. Set data path
dataPath = 'D:\Example Data\';

% 2. Set path of the region-based PSFs
psfPath = 'D:\230801_PSF\';

% 3. Select deconvolution method
% 0: Fast deconvolution with lower accuracy
% 1: Slow deconvolution with higher accurarcy
Decon_Method = 0;

% 4. Regularization parameter for phase retrieval
rPara = 1e-5;

% 5. Stepsize along the z-axis
stepSize = 2*1e-6;		% meter

% 6. Open a dialog box to select data
[dataName,imgPath] = uigetfile([dataPath,'*.*']);


%% Start region-based deconvolution and phase retrival
focusMx = F00_FluoAndPhaseRecon(imgPath,psfPath,Decon_Method,rPara,stepSize,1,1);

return;

