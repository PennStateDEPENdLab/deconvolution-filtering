clear
addpath(genpath('/home/jcisler/matlab_toolboxes'))
addpath(genpath('./libs/spm8'))
addpath(genpath('./anev_src'));
addpath(genpath('./deconvolve_src'));
addpath(genpath('./utility_src'));

continuing=0;

%load in mask
%mask=load_nii('/home/jcisler/AEC/group/stroop/mask.3x3x3.nii');
%brain_size=size(mask.img);

%GM mask
%eval('!3dAFNItoNIFTI -prefix ./temp ./AEC.005.anat3.seg.fsl.MNI.GM+tlrc')
mask=load_nii('./temp.nii');
brain_size=size(mask.img);

%make two-dimensions
mask_reshaped=reshape(mask.img,brain_size(1)*brain_size(2)*brain_size(3),1);
%identify voxels in the brain
in_brain=find(mask_reshaped==1);

%load in brain data and reshape to two-dimensions
whole_brain=load_nii('R_AEC.005.stroop.run1.scaled.resid.nii');
whole_brain=reshape(whole_brain.img,brain_size(1)*brain_size(2)*brain_size(3),size(whole_brain.img,4));
whole_brain=double(whole_brain(in_brain,:));


%Observation parameters
FO = 0.5;
HRF_d = 6;

%Deconvolution parameters
nev_lr = 0.01;
epsilon = 0.005;


filtered_data = 0*whole_brain;
tracking=0;


%this just saves intermediate results because my server was crashing

%if continuing==1
%    load result

%    place=(1:size(filtered_data,1))';
%    f=find(sum(filtered_data,2)~=0);
%    left_off=place(max(f));
%else
%    left_off=1;
%end
left_off=1;

    
    

%loop through voxels and filter
for xyz=left_off:size(whole_brain,1)
    if sum(whole_brain(xyz,:),2)~=0%skip voxels in brain with no data
    disp(xyz)
    disp(tracking)
        %normalize data
        mean_voxel = mean(whole_brain(xyz,:),2);
        scaled_voxel = whole_brain(xyz,:)-mean_voxel;
        
        %do filtering
        [result] = deconvolve_filter(scaled_voxel,FO,HRF_d,nev_lr,epsilon);
        filtered_data(xyz,:) = result;
    end
    if tracking==1000
      save result filtered_data
      tracking=0;
    else
        tracking=tracking+1;
    end
end
save result filtered_data
%output filtered data
output(1:size(mask_reshaped,1),1:size(filtered_data,2))=0;
output(in_brain,:)=filtered_data;
output=reshape(output,brain_size(1),brain_size(2),brain_size(3),size(filtered_data,2));
mask.img=output;
mask.hdr.dime.dim=[4 54 64 50 size(output,4) 1 1 1];
mask.hdr.dime.datatype=64;
mask.hdr.dime.bitpix=64;
save_nii(mask,['./ACE.005.stroop.run1.decon_filtered.nii']);

