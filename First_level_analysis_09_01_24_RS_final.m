% First-Level Analysis Script, IntuSchizo, Session A
% Raphaela Schöpfer, 09.01.2024

clc;
clear all;

% Define the base directory for the source data
baseDir = 'C:\Users\Raphaela Schöpfer\Documents\fMRI\source_data\';

% List of subjects
subjects = {'sub-10'}; % Add more subject IDs as needed

% Loop over each subject
for i = 1:length(subjects)
    % Specify the directories for functional and anatomical data
    funcDir = fullfile(baseDir, subjects{i}, 'session_A', 'func');
    anatDir = fullfile(baseDir, subjects{i}, 'session_A', 'anat');

    % Specify the directory for the timing files
    timingDir = fullfile(baseDir, subjects{i}, 'session_A', 'behav');

    % Specify the output directory for the SPM results (within the session_A directory)
    outputDir = fullfile(baseDir, subjects{i}, 'session_A', 'stats');
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    % Load the SPM default configurations for first-level analysis
    spm('Defaults','fMRI');
    spm_jobman('initcfg');

    % Specify the SPM job
    matlabbatch = {};

    % Functional Data ('swaf')
    f = spm_select('FPList', funcDir, '^swaf.*\.nii$');
    matlabbatch{1}.spm.stats.fmri_spec.sess.scans = cellstr(f);

    % Load the timing file
    timingFileName = [subjects{i}, '_SPM_timingData.mat']; 
    timingFile = fullfile(timingDir, timingFileName);

    % Check if the timing file exists
    if ~exist(timingFile, 'file')
        error('Timing file does not exist for subject %s at the path %s', subjects{i}, timingFile);
    end

    % Load the timing file
    load(timingFile, 'names', 'onsets', 'durations');

    % Initialize a counter for the number of conditions added to matlabbatch
    condIndex = 0;

    % Setting up conditions, onsets, and durations for each condition
    for c = 1:length(names)
        if ~isempty(onsets{c}) && ~isempty(durations{c})
            condIndex = condIndex + 1; % Increment condition index
            matlabbatch{1}.spm.stats.fmri_spec.sess.cond(condIndex).name = names{c};
            matlabbatch{1}.spm.stats.fmri_spec.sess.cond(condIndex).onset = onsets{c};
            matlabbatch{1}.spm.stats.fmri_spec.sess.cond(condIndex).duration = durations{c};           
        else
            fprintf('Warning: Condition %s has no events for subject %s. It will be excluded from the analysis.\n', names{c}, subjects{i});
        end
    end

    if condIndex == 0
        error('No conditions have events for subject %s. Cannot proceed with analysis.', subjects{i});
    end

    % Set the output directory for the model specification
    matlabbatch{1}.spm.stats.fmri_spec.dir = {outputDir};

    % Model Specification Settings    
    
    % Timing parameters
    matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
    matlabbatch{1}.spm.stats.fmri_spec.timing.RT = 2; 
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 35;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 35;
    
    % High-Pass Filter
    matlabbatch{1}.spm.stats.fmri_spec.sess.hpf = 128;
    
    % Global Signal Normalization
    matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
    
    % Explicit Basis Functions and Derivatives
    matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
    
    % Session-Specific Multiple Regressors (motion parameters)
    regFile = spm_select('FPList', funcDir, '^rp.*\.txt$');
    matlabbatch{1}.spm.stats.fmri_spec.sess.multi_reg = {regFile};
    
    % Serial Correlation (AR(1))
    matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';

    % Model Estimation
    matlabbatch{2}.spm.stats.fmri_est.spmmat = {fullfile(outputDir, 'SPM.mat')};
        
    % Initialize Contrast Definitions
    matlabbatch{3}.spm.stats.con.spmmat = {fullfile(outputDir, 'SPM.mat')};
    
    % Define the contrast (for example "CorrectInsight vs FalseInsight")
    idxCorrectInsight = find(strcmp(names, 'CorrectInsight'));
    idxFalseInsight = find(strcmp(names, 'FalseInsight'));
    
    % Initialize weights as zeros
    weights = zeros(1, length(names));
    
    % Set weights for the conditions of interest
    weights(idxCorrectInsight) = 1;
    weights(idxFalseInsight) = -1;
    
    % Add the contrast to matlabbatch
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'CorrectInsight vs FalseInsight';
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = weights;
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
    
    % Run the SPM job
    spm_jobman('run', matlabbatch);

end

