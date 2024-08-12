%{
train2 Function Documentation
============================

**Purpose:**
The `train2` function is designed to execute a behavioral training protocol 
in a Bpod system. It runs a series of trials with predefined parameters, 
handles stimulus delivery, response collection, and reward dispensing.

**Global Variables:**
- `BpodSystem`: A global structure used by the Bpod system to manage trial data, 
  protocol settings, and system status.

**Local Variables:**
- `MaxTrials`: Integer value specifying the maximum number of trials to be executed 
  (default is 200).
- `S`: Structure containing protocol settings (e.g., stimulus duration, reward amount). 
  Loaded from the Bpod system or initialized with default values if empty.
- `TrialTypes`: Array of integers defining the type of each trial (all initialized to 1 by default).
- `R`: Array containing valve open durations calculated using the `GetValveTimes` function.

**Workflow:**

1. **Initialize Parameters:**
   - Load Settings:
     - The function starts by loading protocol settings from the Bpod system's 
       `ProtocolSettings` struct.
     - If settings are empty, default values are initialized:
       - `StimulusDuration`: Duration of stimulus presentation, set to 0.05 seconds.
       - `RewardAmount`: Volume of reward delivered, set to 5 microliters (ul).
       - `OpenValveOne`: Command string for opening Valve 1.
       - `OpenValveTwo`: Command string for opening Valve 2.
     - These settings are associated with GUI elements (e.g., pushbuttons).

2. **Define Trials:**
   - Initialize Trial Types:
     - An array `TrialTypes` is created, initializing all trials as type 1.
     - This array is saved in `BpodSystem.Data.TrialTypes`, storing the trial type for each completed trial.

3. **Initialize Plots:**
   - Bpod Notebook:
     - Initialized with `BpodNotebook('init')` to record text notes for the session or individual trials.
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

   **Trial-Specific Actions:**
   - Determine State Machine Fields:
     - Based on trial type, the function determines actions for stimulus delivery and reward output.
     - **Trial Type 1**:
       - Stimulus Output: `{'ValveModule1', 2}` opens Valve 2.
       - Reward Output: `{'ValveModule1', 1}` delivers reward.
     - **Trial Type 2**:
       - Stimulus Output: `{'ValveModule1', 3}` opens Valve 3.
       - Reward Output: `{'ValveModule1', 4}` delivers reward.

5. **Define State Machine:**
   - Initialize State Machine:
     - A new state machine is created with `NewStateMachine()`.

   **State Definitions:**
   1. **WaitForPoke**:
      - **Timer**: 0 seconds.
      - **State Change Conditions**:
        - Port 2 In → `runvalve2`.
        - Port 1 In → `runlight1`.
        - Port 3 In → `runlight3`.
      - **Output Actions**: None.

   2. **runvalve2**:
      - **Timer**: 0.5 seconds.
      - **State Change Conditions**: After timer expiration (`Tup`), transition to `CloseValve2`.
      - **Output Actions**: Open ValveModule1, output 2.

   3. **CloseValve2**:
      - **Timer**: 0.1 seconds.
      - **State Change Conditions**: After timer expiration (`Tup`), transition to `WaitForResponse`.
      - **Output Actions**: Close ValveModule1, output 2.

   4. **WaitForResponse**:
      - **Timer**: 15 seconds.
      - **State Change Conditions**:
        - Port 1 In → `Reward1`.
        - Port 3 In → `Reward2`.
        - Timer expiration (`Tup`) → `exit`.
      - **Output Actions**: None.

   5. **Reward1**:
      - **Timer**: Defined by `S.GUI.StimulusDuration`.
      - **State Change Conditions**: After timer expiration (`Tup`), transition to `CloseRewardValve1`.
      - **Output Actions**: Open ValveModule1, output 8.

   6. **CloseRewardValve1**:
      - **Timer**: 0.1 seconds.
      - **State Change Conditions**: After timer expiration (`Tup`), transition to `exit`.
      - **Output Actions**: Close ValveModule1, output 8.

   7. **Reward2**:
      - **Timer**: Defined by `S.GUI.StimulusDuration`.
      - **State Change Conditions**: After timer expiration (`Tup`), transition to `CloseRewardValve2`.
      - **Output Actions**: Open ValveModule1, output 8.

   8. **CloseRewardValve2**:
      - **Timer**: 0.1 seconds.
      - **State Change Conditions**: After timer expiration (`Tup`), transition to `exit`.
      - **Output Actions**: Close ValveModule1, output 1.

   9. **runlight1**:
      - **Timer**: 1 second.
      - **State Change Conditions**: After timer expiration (`Tup`), transition to `NextTrial`.
      - **Output Actions**: Turn on light 1.

   10. **runlight3**:
       - **Timer**: 1 second.
       - **State Change Conditions**: After timer expiration (`Tup`), transition to `NextTrial`.
       - **Output Actions**: Turn on light 3.

   11. **NextTrial**:
       - **Timer**: 0 seconds.
       - **State Change Conditions**: After timer expiration (`Tup`), transition to `exit`.
       - **Output Actions**: None.

6. **Execute State Machine:**
   - **Send to Bpod**:
     - The state machine is sent to Bpod using `SendStateMachine(sma)`.
   - **Run the State Machine**:
     - The state machine is executed using `RunStateMachine`.

7. **Record and Save Trial Data:**
   - **Record Trial Events**:
     - If trial data is returned (`RawEvents` is not empty):
       - Add trial events to `BpodSystem.Data`.
       - Sync data with the Bpod notebook.
       - Save the trial settings to `BpodSystem.Data.TrialSettings`.
   - **Save Data**:
     - The data is saved using `SaveBpodSessionData`.

8. **Pause and Exit Conditions:**
   - **Handle Pause**:
     - The function checks if the protocol is paused and waits until the user resumes.
   - **Exit Condition**:
     - If the protocol is stopped (`BpodSystem.Status.BeingUsed == 0`), the function exits.

Author:
    Kolbe Sussman
    ksussman@emich.edu
    last updated: 7/25/24

%}

function train2
    global BpodSystem
    MaxTrials = 200; % Reset to original number of trials

    %% Define parameters
    S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
    if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
        S.GUI.StimulusDuration = 0.05; % in seconds
        S.GUI.RewardAmount = 5; % ul
        S.GUI.OpenValveOne = 'OpenValve(1)';
        S.GUIMeta.OpenValveOne.Style = 'pushbutton';
        S.GUI.OpenValveTwo = 'OpenValve(3)';
        S.GUIMeta.OpenValveTwo.Style = 'pushbutton';
    end 

    %% Define trials
    TrialTypes = ones(1, MaxTrials); % Initialize all trials as type 1
    BpodSystem.Data.TrialTypes = TrialTypes; % The trial type of each trial completed will be added here.


    %% Initialize plots
    BpodNotebook('init'); % Bpod Notebook (to record text notes about the session or individual trials)
    BpodParameterGUI('init', S); % Initialize parameter GUI plugin

    %% Main trial loop
    for currentTrial = 1:MaxTrials
        % Sync parameters with BpodParameterGUI plugin
        S = BpodParameterGUI('sync', S); 
        % Update reward amounts
        R = GetValveTimes(S.GUI.RewardAmount, [1 3]); 
        
        % Determine trial-specific state matrix fields based on trial type
        switch TrialTypes(currentTrial)
            case 1
                StimulusOutputActions = {'ValveModule1', 2}; % Action to open valve for trial type 1
                RewardOutputActions = {'ValveModule1', 1}; % Action to deliver reward

            case 2
                StimulusOutputActions = {'ValveModule1', 3}; % Action to open valve for trial type 2
                RewardOutputActions = {'ValveModule1', 4}; % Action to deliver reward

        end
        
        % Initialize new state machine description
        sma = NewStateMachine(); 
        
        % Define states for stimulus delivery and response collection
        sma = AddState(sma, 'Name', 'WaitForPoke', ...
            'Timer', 0, ...
            'StateChangeConditions', {'Port2In', 'runvalve2', 'Port1In', 'runlight1', 'Port3In', 'runlight3'}, ...
            'OutputActions', {}); 

        sma = AddState(sma, 'Name', 'runvalve2', ...
            'Timer', 0.5, ... % Open ValveModule1, output 2 for 0.5 seconds
            'StateChangeConditions', {'Tup', 'CloseValve2'}, ...
            'OutputActions', {'ValveModule1', 2});

        sma = AddState(sma, 'Name', 'CloseValve2', ...
            'Timer', 0.1, ... % Close ValveModule1, output 2
            'StateChangeConditions', {'Tup', 'WaitForResponse'}, ...
            'OutputActions', {'ValveModule1', 2}); 

        sma = AddState(sma, 'Name', 'WaitForResponse', ...
            'Timer', 15,... 
            'StateChangeConditions', {'Port1In', 'Reward1', 'Port3In', 'Reward2', 'Tup', 'exit'},...
            'OutputActions', {});

       % Define states for reward delivery
        sma = AddState(sma, 'Name', 'Reward1', ...
            'Timer', S.GUI.StimulusDuration,... % Duration of reward delivery
            'StateChangeConditions', {'Tup', 'CloseRewardValve1'},...
            'OutputActions', {'ValveModule1', 8}); 
    
        sma = AddState(sma, 'Name', 'CloseRewardValve1', ...
            'Timer', 0.1,... % Immediately close the reward valve
            'StateChangeConditions', {'Tup', 'exit'},...
            'OutputActions', {'ValveModule1', 8}); % Action to close the valve

        % Define states for reward delivery
        sma = AddState(sma, 'Name', 'Reward2', ...
            'Timer', S.GUI.StimulusDuration,... % Duration of reward delivery
            'StateChangeConditions', {'Tup', 'CloseRewardValve2'},...
            'OutputActions', {'ValveModule1', 8}); 
    
        sma = AddState(sma, 'Name', 'CloseRewardValve2', ...
            'Timer', 0.1,... % Immediately close the reward valve
            'StateChangeConditions', {'Tup', 'exit'},...
            'OutputActions', {'ValveModule1', 1}); % Action to close the valve


        sma = AddState(sma, 'Name', 'runvalve2', ...
            'Timer', 0.5, ... % Open ValveModule1, output 2 for 0.5 seconds
            'StateChangeConditions', {'Tup', 'CloseValve2'}, ...
            'OutputActions', {'ValveModule1', 2});

        sma = AddState(sma, 'Name', 'runvalve2', ...
            'Timer', 0.5, ... % Open ValveModule1, output 2 for 0.5 seconds
            'StateChangeConditions', {'Tup', 'CloseValve2'}, ...
            'OutputActions', {'ValveModule1', 2});

        sma = AddState(sma, 'Name', 'runlight1', ...
            'Timer', 1, ... % Turn on light 1 for 1 second
            'StateChangeConditions', {'Tup', 'NextTrial'}, ...
            'OutputActions', {'LED', 1});

        sma = AddState(sma, 'Name', 'runlight3', ...
            'Timer', 1, ... % Turn on light 3 for 1 second
            'StateChangeConditions', {'Tup', 'NextTrial'}, ...
            'OutputActions', {'LED', 3});
        
        sma = AddState(sma, 'Name', 'NextTrial', ...
            'Timer', 0, ...
            'StateChangeConditions', {'Tup', '>exit'}, ...
            'OutputActions', {});

        % Send state machine to Bpod
        SendStateMachine(sma); 

        % Run the state machine
        RawEvents = RunStateMachine; 

        % If trial data was returned, record trial events and settings
        if ~isempty(fieldnames(RawEvents)) 
            BpodSystem.Data = AddTrialEvents(BpodSystem.Data, RawEvents); % Computes trial events from raw data
            BpodSystem.Data = BpodNotebook('sync', BpodSystem.Data); % Sync with Bpod notebook plugin
            BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
            SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
        end

        % Checks to see if the protocol is paused. If so, waits until user resumes.
        HandlePauseCondition; 

        % If the protocol is stopped, exit the function
        if BpodSystem.Status.BeingUsed == 0
            return
        end
    end
end
