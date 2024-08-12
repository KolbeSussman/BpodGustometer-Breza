%{
analyzeGustometerOutputFromFiles

This function analyzes data from gustometer output files in MATLAB.

Usage: 
    analyzeGustometerOutputFromFiles analyzes one or more .mat files containing gustometer data.
    It prompts the user to select the files, analyzes each file, and generates a CSV file containing the analysis results.

    Output CSV file format:
    The CSV file contains headers and data rows. Each row corresponds to one file, and each column represents a variable.
    The variables include file name, trial counts for two trial types, reward counts for two rewards, and punishment count, 
    as well as reward percentages for each reward and punishment.

    Example:
        FileName,TrialType1_Count,TrialType2_Count,Reward1_Count,Reward2_Count,Punish_Count,Reward1_Percentage,Reward2_Percentage,Punish_Percentage
        data1.mat,100,150,75,60,15,37.5,40,10

Functions:
    - analyzeSingleFile: Analyzes data from a single gustometer output file.

Author:
    Kolbe Sussman
    ksussman@emich.edu
    last updated: 8/12/24

%}

function analyzeGustometerOutputFromFiles
    % Select one or more files for analysis
    [fileNames, filePath] = uigetfile('*.mat', 'Select file(s) for analysis', 'MultiSelect', 'on');

    % Check if the user canceled the selection
    if isequal(fileNames, 0) || isequal(filePath, 0)
        disp('File selection canceled.');
        return;
    end

    % If only one file is selected, uigetfile returns a string instead of a cell array
    if ~iscell(fileNames)
        fileNames = {fileNames};
    end

    % Initialize output variables
    outputData = {};

    % Loop through selected files
    for i = 1:numel(fileNames)
        [fileName, trialCounts, rewardCounts, rewardPercentages] = analyzeSingleFile(fullfile(filePath, fileNames{i}));
        outputData = [outputData; {fileName}, num2cell(trialCounts), num2cell(rewardCounts), num2cell(rewardPercentages)];
    end

    % Define variable names for the headers
    variableNames = {'FileName', 'TrialType1_Count', 'TrialType2_Count', 'Reward1_Count', 'Reward2_Count', ...
        'Punish1_Count', 'Punish2_Count', 'TimeOut_Count', 'Reward1_Percentage', 'Reward2_Percentage',...
        'Punish1_Percentage', 'Punish2_Percentage', 'TimeOut_Percentage'};
%[Reward1, Reward2, Punish1, Punish2, TimeOut]
    % Write variable names to a separate cell array
    outputData = [variableNames; outputData];

    % Write output data to a CSV file with headers
    csvFileName = ['output_' datestr(now, 'mm_dd_yyyy') '.csv'];
    writecell(outputData, csvFileName, 'Delimiter', ',', 'WriteMode', 'overwrite');
end

function [fileName, trialCounts, rewardCounts, rewardPercentages] = analyzeSingleFile(filePath)
    % Extract file name without extension
    [~, fileName, ~] = fileparts(filePath);

    % Load data from the selected file
    loadedData = load(filePath);

    % Check if the necessary data structure is available
    if ~isfield(loadedData, 'SessionData') || isempty(loadedData.SessionData)
        disp(['No data available in ', filePath]);
        trialCounts = [];
        rewardCounts = [];
        rewardPercentages = [];
        return;
    end

    Data = loadedData.SessionData;

    % Extract trial types and outcomes
    if isfield(Data, 'TrialTypes') && isfield(Data, 'RawEvents')
        TrialTypes = Data.TrialTypes;
        RawEvents = Data.RawEvents;
        nTrials = numel(RawEvents.Trial);

        % Initialize counters for outcomes
        rewardCounts = zeros(1, 5); % [Reward1, Reward2, Punish1, Punish2, TimeOut]
        trialCounts = zeros(1, 2);  % [TrialType1, TrialType2]

        for j = 1:nTrials
            trialType = TrialTypes(j);
            trialCounts(trialType) = trialCounts(trialType) + 1;
        
            % Determine the outcome of the trial
            if sum(~isnan(RawEvents.Trial{j}.States.Reward)) > 0
                if trialType == 1
                    rewardCounts(1) = rewardCounts(1) + 1;
                else
                    rewardCounts(2) = rewardCounts(2) + 1;
                end
            elseif sum(~isnan(RawEvents.Trial{j}.States.Punish)) > 0
                if trialType == 1
                    rewardCounts(3) = rewardCounts(3) + 1;
                else
                    rewardCounts(4) = rewardCounts(4) + 1;
                end
            else rewardCounts(5) = rewardCounts(5) + 1;
            end
        end

        % Calculate percentages
        rewardPercentages = zeros(1, 5);
        rewardPercentages(1) = (rewardCounts(1) ./ trialCounts(1)) * 100;
        rewardPercentages(2) = (rewardCounts(2) ./ trialCounts(2)) * 100;
        rewardPercentages(3) = (rewardCounts(3) ./ trialCounts(1)) * 100;
        rewardPercentages(4) = (rewardCounts(4) ./ trialCounts(2)) * 100;
        rewardPercentages(5) = (rewardCounts(5) ./ sum(trialCounts)) * 100;

    else
        disp(['TrialTypes or RawEvents not found in ', filePath]);
        trialCounts = [];
        rewardCounts = [];
        rewardPercentages = [];
    end
end
