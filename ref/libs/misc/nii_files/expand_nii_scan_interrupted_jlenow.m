function [img_idx]=expand_nii_scan_interrupted(filename, newpath)
%  Expand a multiple-scan NIFTI file into multiple single-scan NIFTI files
%  09/28/2011 - AJ modified this script to expand nii files that have been
%  interrupted on the scanner.
%  New usage does not take # of timepoints; instead calculates that.
%
%
%
%  NIFTI data format can be found on: http://nifti.nimh.nih.gov
%
%  - Jimmy Shen (jimmy@rotman-baycrest.on.ca)
%  - Fixed by Andy James (GAJames@uams.edu)
%
addpath /home/ajames/matlab/NIFTI_20100413/



   if ~exist('newpath','var'), newpath = pwd; 
   end
   
   
   T=evalc(['!3dTcat -prefix temp ' filename '[''1..10'']'])
   findstr(T,'cannot read brick')
   T(ans+18:ans+20)
   img_idx=str2num(ans)-1
   %img_idx=152
   
   
   for i=1:img_idx
     
      nii_i = load_untouch_nii(filename, i);

      fn = [nii_i.fileprefix '_' sprintf('%04d',i) '.nii'];
      pnfn = fullfile(newpath, fn);

      save_untouch_nii(nii_i, pnfn);
   end
   filenameprefix=filename(1:length(filename)-4);
   eval(['!rm concat_*orig*'])
   %eval(['!rm ' filenameprefix '.nii'])
   eval(['!3dTcat -prefix concat_' filenameprefix ' ' filenameprefix '_*.nii'])
   %eval(['!3drefit -TR 2.000 concat_' filenameprefix '+orig'])
   eval(['!3dAFNItoNIFTI -float concat_' filenameprefix '+orig'])
   eval(['!rm ' filenameprefix '_????.nii'])
   eval(['!rm concat_' filenameprefix '+orig*'])
      
   
return;					% expand_nii_scan

