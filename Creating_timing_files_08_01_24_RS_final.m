% Creating timing files for IntuSchizo, Session A
% 08.01.2024, Raphaela Schöpfer

% Base directory where the subject folders are stored
baseDir = 'C:\Users\Raphaela Schöpfer\Documents\fMRI\source_data\';

% List of subjects
subjects = arrayfun(@(x) sprintf('sub-%02d', x), 1:128, 'UniformOutput', false);

% Loop over each subject
for i = 1:length(subjects)
    % Define the path for session A
    sessionAPath = fullfile(baseDir, subjects{i}, 'session_A', 'behav', 'events.xlsx');

    % Check if the file exists
    if ~isfile(sessionAPath)
        fprintf('File not found for %s, skipping...\n', subjects{i});
        continue;
    end

    % Initialize cell arrays for each subject
    names = {'CorrectIntuition', 'CorrectInsight', 'FalseIntuition', 'FalseInsight'};
    onsets = cell(1, length(names));
    durations = cell(1, length(names));

    % Define the path for session A
    sessionAPath = fullfile(baseDir, subjects{i}, 'session_A', 'behav', 'events.xlsx');

    % Check if the file exists
    if isfile(sessionAPath)
        data = readtable(sessionAPath);

        % Filter out trials and calculate onsets and durations
        uniqueTrials = unique(data.trial_no); 

        for k = 1:length(uniqueTrials)
            trialData = data(data.trial_no == uniqueTrials(k), :);

            % Ensure there are at least 7 rows for this trial number
            if size(trialData, 1) < 7
                continue;
            end
        
            secondRow = trialData(2, :); % For triad_type
            fifthRow = trialData(5, :);  % For SCTdenompres_press
            seventhRow = trialData(7, :);  % For SCTdenomknow_press

            % Convert to numeric values and handle NaNs for specific rows
            SCTdenompres_press_val = str2double(fifthRow.SCTdenompres_press);
            SCTdenomknow_press_val = str2double(seventhRow.SCTdenomknow_press);

            % Replace NaNs with a default value or handle them as needed
            if isnan(SCTdenompres_press_val)
                SCTdenompres_press_val = -1; % Or another appropriate value
            end
            if isnan(SCTdenomknow_press_val)
                SCTdenomknow_press_val = -1; % Or another appropriate value
            end

            % Determine condition based on criteria
            if strcmp(secondRow.triad_type, 'COH') && SCTdenompres_press_val == 3
                if SCTdenomknow_press_val == 1
                    condition = 'CorrectIntuition';
                elseif SCTdenomknow_press_val == 3
                    condition = 'CorrectInsight';
                end
            elseif strcmp(secondRow.triad_type, 'INC') && SCTdenompres_press_val == 3
                if SCTdenomknow_press_val == 1
                    condition = 'FalseIntuition';
                elseif SCTdenomknow_press_val == 3
                    condition = 'FalseInsight';
                end
            else
                continue; % Skip if none of the conditions are met
            end

            % Append onsets and durations
            idx = find(strcmp(names, condition));
            if isempty(idx)
                continue; % Skip if condition is not found in 'names'
            end
            onset = secondRow.global_clock_new; % Onset from the second row
            lastRow = trialData(end, :); % Last row of the block
            duration = lastRow.global_clock_new - onset; % Duration calculation
            onsets{idx}(end+1) = onset;
            durations{idx}(end+1) = duration;
        end

        % Save the timing files in the session_A directory for each subject
        save(fullfile(baseDir, subjects{i}, 'session_A', 'behav', [subjects{i} '_SPM_timingData.mat']), 'names', 'onsets', 'durations');
    else
        fprintf('File not found: %s\n', sessionAPath);
    end
end
