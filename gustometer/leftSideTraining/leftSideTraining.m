%{
leftSideTraining Function Documentation
========================================

**Purpose:**
The `leftSideTraining` function executes a behavioral training protocol 
in a Bpod system. It conducts a series of trials with defined parameters, 
delivers stimuli, collects responses, and administers rewards or punishments.

**Global Variables:**
- `BpodSystem`: A global structure used by the Bpod system to manage trial data, 
  protocol settings, and system status.

**Local Variables:**
- `MaxTrials`: Integer value specifying the maximum number of trials to be executed 
  (default is 10,000).
- `S`: Structure containing protocol settings (e.g., stimulus duration, reward amount). 
  Loaded from the Bpod system or initialized with default values if empty.
- `TrialTypes`: Array of integers defining the type of each trial (all initialized to 1 by default).
- `R`: Array containing valve open durations calculated using the `GetValveTimes` function.
- `currentTrialType`: Integer defining the type of the current trial (set to 2 for all trials).
- `StimulusOutputActions`: Cell array specifying the actions for stimulus delivery.
- `RewardOutputActions`: Cell array specifying the actions for reward delivery.

**Workflow:**

1. **Initialize Parameters:**
   - Load Settings:
     - The function starts by loading protocol settings from the Bpod system's 
       `ProtocolSettings` struct into `S`.
     - If the settings are empty, default values are initialized:
       - `StimulusDuration`: Duration of stimulus presentation, set to 0.05 seconds.
       - `RewardAmount`: Volume of reward delivered, set to 5 microliters (ul).
       - `OpenValveOne`: Command string for opening Valve 1.
       - `OpenValveTwo`: Command string for opening Valve 3.
     - GUI elements for these settings are set to 'pushbutton'.

2. **Define Trials:**
   - Initialize Trial Types:
     - An array `TrialTypes` is created, initializing all trials as type 1.
     - This array is saved in `BpodSystem.Data.TrialTypes`, storing the trial type for each completed trial.

3. **Initialize Plots:**
   - Bpod Notebook:
     - Initialized with `BpodNotebook('init')` to record text notes about the session or individual trials.
   - Parameter GUI:
     - Initialized with `BpodParameterGUI('init', S)` to display and edit protocol parameters during the session.

4. **Main Trial Loop:**
   - Loop Over Trials:
     - The function loops over each trial (from 1 to `MaxTrials`).
     - In each iteration:
       - Sync Parameters:
         - Synchronizes the parameters with the GUI using `BpodParameterGUI('sync', S)`.
       - Update Reward Times:
         - Computes valve opening times for reward delivery using `GetValveTimes`.
       - Define Actions:
         - Specifies stimulus and reward output actions for all trials using `StimulusOutputActions` and `RewardOutputActions`.
   
   **State Machine Definition:**
   - Initialize State Machine:
     - A new state machine is created with `NewStateMachine()`.

   **State Definitions:**
   1. **WaitForPoke**:
      - **Timer**: 0 seconds.
      - **State Change Conditions**:
        - Port 2 In → `DeliverStimulus`.
      - **Output Actions**: None.

   2. **DeliverStimulus**:
      - **Timer**: Defined by `S.GUI.StimulusDuration`.
      - **State Change Conditions**:
        - Timer expiration (`Tup`) → `CloseStimulusValve`.
        - Port 2 Out → `CloseStimulusValve`.
      - **Output Actions**: Action to open the stimulus valve (`StimulusOutputActions`).

   3. **CloseStimulusValve**:
      - **Timer**: 0.1 seconds.
      - **State Change Conditions**: After timer expiration (`Tup`), transition to `WaitForResponse`.
      - **Output Actions**: Action to close the stimulus valve (`StimulusOutputActions`).

   4. **WaitForResponse**:
      - **Timer**: 15 seconds.
      - **State Change Conditions**:
        - Port 1 In → `Reward`.
        - Port 3 In → `Punish`.
        - Timer expiration (`Tup`) → `NextTrial`.
      - **Output Actions**: None.

   5. **Reward**:
      - **Timer**: Defined by `S.GUI.StimulusDuration`.
      - **State Change Conditions**: After timer expiration (`Tup`), transition to `CloseRewardValve`.
      - **Output Actions**: Action to deliver reward (`RewardOutputActions`).

   6. **CloseRewardValve**:
      - **Timer**: 0.1 seconds.
      - **State Change Conditions**: After timer expiration (`Tup`), transition to `NextTrial`.
      - **Output Actions**: Action to close the reward valve (`RewardOutputActions`).

   7. **Punish**:
      - **Timer**: 3 seconds.
      - **State Change Conditions**: After timer expiration (`Tup`), transition to `NextTrial`.
      - **Output Actions**: Turn on LED (punishment).

   8. **NextTrial**:
      - **Timer**: 0 seconds.
      - **State Change Conditions**: After timer expiration (`Tup`), transition to `exit`.
      - **Output Actions**: None.

5. **Execute State Machine:**
   - **Send to Bpod**:
     - The state machine is sent to Bpod using `SendStateMachine(sma)`.
   - **Run the State Machine**:
     - The state machine is executed using `RunStateMachine`.

6. **Record and Save Trial Data:**
   - **Record Trial Events**:
     - If trial data is returned (`RawEvents` is not empty):
       - Add trial events to `BpodSystem.Data` using `AddTrialEvents`.
       - Sync data with the Bpod notebook using `BpodNotebook('sync', BpodSystem.Data)`.
       - Save the trial settings to `BpodSystem.Data.TrialSettings`.
   - **Save Data**:
     - The data is saved using `SaveBpodSessionData`.

7. **Pause and Exit Conditions:**
   - **Handle Pause**:
     - The function checks if the protocol is paused and waits until the user resumes.
   - **Exit Condition**:
     - If the protocol is stopped (`BpodSystem.Status.BeingUsed == 0`), the function exits.

Author:
    Kolbe Sussman
    ksussman@emich.edu
    last updated: 8/12/24

%}

function leftSideTraining
    global BpodSystem
    MaxTrials = 10000;
    
    %% Define parameters
    S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
    if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
        S.GUI.StimulusDuration = .05; % in seconds
        S.GUI.RewardAmount = 5; %ul
        S.GUI.OpenValveOne = 'OpenValve(1)';
        S.GUIMeta.OpenValveOne.Style = 'pushbutton';
        S.GUI.OpenValveTwo = 'OpenValve(3)';
        S.GUIMeta.OpenValveTwo.Style = 'pushbutton';
    end 
    
    %% Define trials
    TrialTypes = ones(1, MaxTrials); % All trials of the same type
    BpodSystem.Data.TrialTypes = TrialTypes; % The trial type of each trial completed will be added here.
    
    %% Initialize plots
    BpodNotebook('init'); % Bpod Notebook (to record text notes about the session or individual trials)
    BpodParameterGUI('init', S); % Initialize parameter GUI plugin
    
    %% Main trial loop
    for currentTrial = 1:MaxTrials
        S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
        R = GetValveTimes(S.GUI.RewardAmount, [1 3]); % Update reward amounts
        currentTrialType = 2;
        % For all trials, use right side only
        StimulusOutputActions = {'ValveModule1', 3}; % Action to open valve
        RewardOutputActions = {'ValveModule1', 8}; % Action to deliver reward
    
    
        sma = NewStateMachine(); % Initialize new state machine description
    
        % Define states for stimulus delivery and response collection
        sma = AddState(sma, 'Name', 'WaitForPoke', ...
            'Timer', 0, ...
            'StateChangeConditions', {'Port2In', 'DeliverStimulus'}, ...
            'OutputActions', {}); 
    
        sma = AddState(sma, 'Name', 'DeliverStimulus', ...
            'Timer', S.GUI.StimulusDuration, ... % Duration of stimulus presentation
            'StateChangeConditions', {'Tup', 'CloseStimulusValve', 'Port2Out', 'CloseStimulusValve'}, ...
            'OutputActions', StimulusOutputActions);
    
        sma = AddState(sma, 'Name', 'CloseStimulusValve', ...
            'Timer', 0.1, ... % Immediately close the stimulus valve
            'StateChangeConditions', {'Tup', 'WaitForResponse'}, ...
            'OutputActions', StimulusOutputActions); % Action to close the valve
    
        sma = AddState(sma, 'Name', 'WaitForResponse', ...
            'Timer', 15, ... 
            'StateChangeConditions', {'Port1In', 'Reward', 'Port3In', 'Punish', 'Tup', 'NextTrial'}, ...
            'OutputActions', {});
    
        % Define states for reward delivery or punishment
        sma = AddState(sma, 'Name', 'Reward', ...
            'Timer', S.GUI.StimulusDuration, ... % Duration of reward delivery
            'StateChangeConditions', {'Tup', 'CloseRewardValve'}, ...
            'OutputActions', RewardOutputActions); 
    
        sma = AddState(sma, 'Name', 'CloseRewardValve', ...
            'Timer', 0.1, ... % Immediately close the reward valve
            'StateChangeConditions', {'Tup', 'NextTrial'}, ...
            'OutputActions', RewardOutputActions); % Action to close the valve
    
        sma = AddState(sma, 'Name', 'Punish', ...
            'Timer', 3, ... % Duration of punishment
            'StateChangeConditions', {'Tup', 'NextTrial'}, ...
            'OutputActions', {'LED', 3}); 

        sma = AddState(sma, 'Name', 'NextTrial', ...
            'Timer', 0, ... % Duration of punishment
            'StateChangeConditions', {'Tup', 'exit'}, ...
            'OutputActions', {});
    
        SendStateMachine(sma); % Send state machine to Bpod
    
        RawEvents = RunStateMachine; % Run the state machine
    
        % If trial data was returned, record trial events and settings
        if ~isempty(fieldnames(RawEvents)) 
            BpodSystem.Data = AddTrialEvents(BpodSystem.Data, RawEvents); % Computes trial events from raw data
            BpodSystem.Data = BpodNotebook('sync', BpodSystem.Data); % Sync with Bpod notebook plugin
            BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
            SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
        end
        
        HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
        
        if BpodSystem.Status.BeingUsed == 0
            return
        end
    end
end
