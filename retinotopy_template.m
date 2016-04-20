function retinotopy_template(subject, out_path, subjects_dir)
%
% Adapted from https://github.com/vistalab/vistasoft/blob/
% f91941f61a5df1bf7118ab74833384ac2b2a4ba0/fileFilters/freesurfer/fs_retinotopicTemplate.m
%
% Parameters
% ----------
% subject : str
%    The subject ID in the Freesurfer context
% out_path : str
%    Full path to the location where output files will be generated
% subjects_dir : str (optional)
%    Full path to the Freesurfer SUBJECTS_DIR. Per default this will be set
%    to the environment-defined $SUBJECTS_DIR variable 
%
% Notes 
% ----- 
% Based on the work of Benson et al. (2014). The requirements
% for this to work are: 
% 1. The data should have been processed using the cross-sectional stream
% in FreeSurfer (i.e. recon-all -s subjid -autorecon-all). Preferably using
% Freesurfer version 5.1
% 2. The scripts (surfreg) and atlas (fsaverage_sym), which are not part of
% the standard FreeSurfer 5.1 distribution, should be installed
% 3. surfreg should be installed in $FREESURFER_HOME/bin/
% 4. fsaverage_sym should be copied to the FreeSufer subject data directory
% 
%
%
% References
% ----------
% NC Benson, OH Butt, R Datta, PD Radoeva, DH Brainard, GK Aguirre (2012)
% The retinotopic organization of striate cortex is well predicted by
% surface topology. Current Biology 22: 2081-2085.
%
% NC Benson, OH Butt, DH Brainard, GK Aguirre (2014) 
% Correction of distortion in flattened representations of the cortical surface 
% allows prediction of V1-V3 functional organization from anatomy. 
% PLoS Comput. Biol. 10(3):e1003538. doi:10.1371/journal.pcbi.1003538
%
% Greve, Douglas N., Lise Van der Haegen, Qing Cai, Steven Stufflebeam, Mert
% R. Sabuncu, Bruce Fischl, and Marc Bysbaert. "A surface-based analysis of
% language lateralization and cortical asymmetry." (2013). Journal of
% Cognitive Neuroscience. In press.

% % To accomodate user set SUBJECTS_DIR system variable:
% if notDefined('subjects_dir')
%     subjects_dir = getenv('SUBJECTS_DIR');
% else
%     syscall(sprintf('export SUBJECTS_DIR=%s', subjects_dir));
% end


maps = {'eccen', 'polar', 'V123'};
hemis = {'lh', 'rh'};
for map_idx = 1:length(maps)
    template = fullfile('/export01/data/hiranya/templates', ...
	sprintf('%s-template-2.5.sym.mgh', maps{map_idx}));
    for hemi_idx = 1:length(hemis)
        file_root = fullfile(out_path, sprintf('%s_%s', hemis{hemi_idx} , maps{map_idx}));
        % These commands differ slightly for the two hemispheres (xhemi):
        if strcmp(hemis{hemi_idx}, 'lh')
            % If the registration file is not there, we'll have to make it:
            if ~(exist(fullfile(subjects_dir, subject, ...
                    '/surf/lh.fsaverage_sym.sphere.reg'), 'file') == 2)
                fprintf('[%s]: Registering... This might take a while... \n',...
                    mfilename);
                
                cmd_str1 = sprintf('surfreg --s %s --t fsaverage_sym --lh', subject);
            else
                cmd_str1 = '';
            end
            cmd_str2 = ['mri_surf2surf --srcsubject fsaverage_sym --srcsurfreg sphere.reg --trgsubject ' ...
                sprintf('%s --trgsurfreg fsaverage_sym.sphere.reg --sval %s --tval ', subject, template) ...
                sprintf('%s.mgh --hemi lh', file_root)];
        else
            if ~(exist(fullfile(subjects_dir, subject, ...
                    'xhemi/surf/lh.fsaverage_sym.sphere.reg'), 'file') == 2)
                fprintf('[%s]: Registering... This might take a while... \n',...
                    mfilename);
                
                % Yep - the following line is with 'lh':
                cmd_str1 = sprintf('surfreg --s %s --t fsaverage_sym --lh --xhemi', subject);
            else
                cmd_str1 = '';
            end
            cmd_str2 = ['mri_surf2surf --srcsubject fsaverage_sym --trgsubject ' ...
                sprintf('%s/xhemi --sval %s --tval ', subject, template) ...
                sprintf('%s.mgh --srcsurfreg sphere.reg --trgsurfreg ', file_root) ...
                'fsaverage_sym.sphere.reg --hemi lh'];
        end
        syscall(cmd_str1);
        syscall(cmd_str2);
        
        
        cmd_str = [sprintf('mri_surf2vol --surfval %s.mgh --projfrac 1 ', file_root) ...
            sprintf('--identity %s --o %s.mgz --hemi %s ', subject, file_root, hemis{hemi_idx}) ...
            sprintf('--template %s/%s/mri/orig.mgz', subjects_dir, subject)];
        syscall(cmd_str);
        
        % Convert to volume:
        outfile = [file_root '.nii']; 
        cmd_str = [sprintf('mri_convert  %s.mgz ', file_root), outfile];
        syscall(cmd_str);
        %gzip(outfile);
        %delete(outfile);
        
    end
end
end 


% Helper function: throw an error if the system call doesn't work as
% expected:
    function [status, result] = syscall(cmd_str)
        % Allow for noops:
        if strcmp(cmd_str, '')
            return
        end
        fprintf('[%s]: Executing "%s" \n', mfilename, cmd_str);
        [status, result] = system(cmd_str);
        if status~=0
            error(result);
        end
    end
