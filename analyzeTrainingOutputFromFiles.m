%{
analyzeTrainOutputFromFiles

This function analyzes data from training output files in MATLAB.

Usage:
    analyzeTrainOutputFromFiles prompts the user to select one or more .mat files containing training data.
    It processes each file to extract nose poke counts and percentages for three ports and generates a CSV file 
    containing the analysis results.

    Output CSV file format:
    The CSV file contains headers and data rows. Each row corresponds to one file, and each column represents 
    a variable. The variables include the file name, counts of nose pokes for three ports, and the percentages 
    of nose pokes for each port.

    Example:
        FileName,Port1_Count,Port2_Count,Port3_Count,Port1_Percentage,Port2_Percentage,Port3_Percentage
        data1.mat,100,150,75,25,37.5,18.75

Functions:
    - analyzeSingleFile: Analyzes data from a single training output file.

Author:
    Kolbe Sussman
    ksussman@emich.edu
    last updated: 8/12/24

%}
function analyzeTrainOutputFromFiles
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
        [fileName, nosePokeCounts, trialPercentages] = analyzeSingleFile(fullfile(filePath, fileNames{i}));
        outputData = [outputData; {fileName}, num2cell(nosePokeCounts), num2cell(trialPercentages)];
    end

    % Define variable names for the headers
    variableNames = {'FileName', 'Port1_Count', 'Port2_Count', 'Port3_Count', 'Port1_Percentage', 'Port2_Percentage', 'Port3_Percentage'};

    % Write variable names to a separate cell array
    outputData = [variableNames; outputData];

    % Write output data to a CSV file with headers
    csvFileName = ['output_' datestr(now, 'mm_dd_yyyy') '.csv'];
    writecell(outputData, csvFileName, 'Delimiter', ',', 'WriteMode', 'overwrite');
end

function [fileName, nosePokeCounts, trialPercentages] = analyzeSingleFile(filePath)
    % Extract file name without extension
    [~, fileName, ~] = fileparts(filePath);

    % Load data from the selected file
    loadedData = load(filePath);

    % Check if the necessary data structure is available
    if ~isfield(loadedData, 'SessionData') || isempty(loadedData.SessionData)
        disp(['No data available in ', filePath]);
        nosePokeCounts = [];
        trialPercentages = [];
        return;
    end

    Data = loadedData.SessionData;

    % Initialize counters for nose pokes
    nosePokeCounts = zeros(1, 3); % [Port1, Port2, Port3]

    % Extract nose poke events
    if isfield(Data, 'RawEvents')
        RawEvents = Data.RawEvents;
        nTrials = numel(RawEvents.Trial);

        for j = 1:nTrials
            % Count nose pokes for each port
            if isfield(RawEvents.Trial{j}.Events, 'Port1In')
                nosePokeCounts(1) = nosePokeCounts(1) + numel(RawEvents.Trial{j}.Events.Port1In);
            end
            if isfield(RawEvents.Trial{j}.Events, 'Port2In')
                nosePokeCounts(2) = nosePokeCounts(2) + numel(RawEvents.Trial{j}.Events.Port2In);
            end
            if isfield(RawEvents.Trial{j}.Events, 'Port3In')
                nosePokeCounts(3) = nosePokeCounts(3) + numel(RawEvents.Trial{j}.Events.Port3In);
            end
        end

        % Total trials is the sum of nose poke counts across all ports
        totalPokes = sum(nosePokeCounts);

        % Calculate percentage of total pokes for each port
        if totalPokes > 0
            trialPercentages = (nosePokeCounts / totalPokes) * 100;
        else
            trialPercentages = [NaN, NaN, NaN]; % Handle case with no pokes
        end
    else
        disp(['RawEvents not found in ', filePath]);
        nosePokeCounts = [];
        trialPercentages = [];
    end
end
