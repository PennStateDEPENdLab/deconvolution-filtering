%========================================
% Source: test_deconv_filter.m
% Author: Keith Bush
% Date: July 23, 2012
% 
% Purpose: Examine the use of deconvolution to filter noisy BOLD
% signal for correlation analysis to determine functional
% connectivity.
%
% Last modified: 
%
%========================================
clear all; close all;

%Initialize the parameter structure
addpath(genpath('C:\cygwin\home\kabush\MATLAB\spm8\'));
addpath(genpath('./anev_src'));
addpath(genpath('./deconvolve_src'));
addpath(genpath('./utility_src'));

%Load data
data = load('./data/run2.txt','-ascii');
data = data(:,4:end);  %prune off voxel locations

%Observation parameters
FO = 0.5;
HRF_d = 6;

%Deconvolution parameters
nev_lr = 0.01;
epsilon = 0.005;

%Normalize data (percent signal change)
N = size(data,1);
for i=1:N
    mData = mean(data(i,:));
    data(i,:) = data(i,:)-mData;
    data(i,:) = data(i,:)/mData;
end

%Assign output storage
filtered_data = 0*data;
for i = 1:N
    i
    [result] = deconvolve_filter(data(i,:),FO,HRF_d,nev_lr, ...
                                 epsilon);
    filtered_data(i,:) = result;
end

%Output correlation results
scale = 100;
figure
subplot(1,2,1);
image(corr(data')*scale);

subplot(1,2,2);
image(corr(filtered_data')*scale);