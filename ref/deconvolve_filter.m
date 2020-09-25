function [result] = deconvolve_filter(data,FO,HRF_d,nev_lr,epsilon)
 
TS = numel(data);

%Build observation kernel
KERobs = spm_advanced_hrf(1/FO,HRF_d);
Kobs = numel(KERobs);

%Estimate the true BOLD via deconvolution filter
BLDdcv_low = zeros(1,TS*FO+(Kobs-1));
    
%Deconvolve the BOLD
[NEVdcv] = deconvolve_Bush_2011(data,KERobs,nev_lr,epsilon);

%Convolve Solved NEV with the HRF Model
BLDdcv_low = convolve_anev_roi_hrf(NEVdcv',FO,HRF_d);

%Prune the data to the observed range
result = BLDdcv_low(1,Kobs:end);

%Normalize to percent signal change
mResult = mean(result);
result = result-mResult;
result = result/mResult;

