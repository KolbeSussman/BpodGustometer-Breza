%{
gustometer Function Documentation
===============================

**Purpose:**
The `gustometer` function implements a behavioral training protocol using the Bpod system. It 
conducts a series of trials with randomized trial types, delivers stimuli, collects responses, 
and administers rewards or punishments based on trial type.

**Global Variables:**
- `BpodSystem`: A global structure used by the Bpod system to manage trial data, 
  protocol settings, and system status.

**Local Variables:**
- `MaxTrials`: Integer value specifying the maximum number of trials to be executed 
  (set to 1000).
- `S`: Structure containing protocol settings (e.g., stimulus duration, reward amount). 
  Loaded from the Bpod system or initialized with default values if empty.
- `TrialTypes`: Array of integers defining the type of each trial, randomly assigned 
  as 1 or 2.
- `R`: Array containing valve open durations calculated using the `GetValveTimes` function.
- `sma`: State machine object used to define the trial states and transitions.

**Workflow:**

1. **Initialize Parameters:**
   - **Load Settings:**
     - Loads protocol settings from the Bpod system's `ProtocolSettings` struct into `S`.
     - If settings are empty, default values are initialized:
       - `StimulusDuration`: Duration of stimulus presentation, set to 0.05 seconds.
       - `RewardAmount`: Volume of reward delivered, set to 5 microliters (ul).
       - `OpenValveOne`: Command string for opening Valve 1.
       - `OpenValveTwo`: Command string for opening Valve 3.
       - GUI elements for these settings are set to 'pushbutton'.

2. **Define Trials:**
   - **Randomize Trial Types:**
     - Creates an array `TrialTypes` with randomly interleaved values of 1 and 2.
     - This array is saved in `BpodSystem.Data.TrialTypes`, storing the trial type for each trial.

3. **Initialize Plots:**
   - **Bpod Notebook:**
     - Initialized with `BpodNotebook('init')` to record text notes about the session or individual trials.
   - **Parameter GUI:**
     - Initialized with `BpodParameterGUI('init', S)` to display and edit protocol parameters during the session.

4. **Main Trial Loop:**
   - **Loop Over Trials:**
     - Iterates from 1 to `MaxTrials`.
     - In each iteration:
       - **Sync Parameters:**
         - Synchronizes the parameters with the GUI using `BpodParameterGUI('sync', S)`.
       - **Update Reward Times:**
         - Computes valve opening times for reward delivery using `GetValveTimes`.
       - **Determine Trial-Specific Actions:**
         - Based on `TrialTypes(currentTrial)`, sets actions for:
           - Stimulus delivery
           - Reward delivery
           - Punishment
       - **Define State Machine:**
         - Initializes a new state machine with `NewStateMachine()`.
         - Defines states:
           - `WaitForPoke`: Waits for poke in Port 2 to transition to `DeliverStimulus`.
           - `DeliverStimulus`: Delivers stimulus and transitions to `CloseStimulusValve`.
           - `CloseStimulusValve`: Closes the stimulus valve and transitions to `WaitForResponse`.
           - `WaitForResponse`: Waits for response or timeout and transitions to appropriate states.
           - `Reward`: Delivers reward and transitions to `CloseRewardValve`.
           - `CloseRewardValve`: Closes the reward valve and transitions to `exit`.
           - `Punish`: Delivers punishment and transitions to `exit`.
       - **Send State Machine:**
         - Sends the state machine to Bpod using `SendStateMachine(sma)`.
       - **Run State Machine:**
         - Executes the state machine using `RunStateMachine`.
       - **Record Trial Data:**
         - If trial data is returned (`RawEvents` is not empty):
           - Adds trial events to `BpodSystem.Data` using `AddTrialEvents`.
           - Syncs data with the Bpod notebook using `BpodNotebook('sync', BpodSystem.Data)`.
           - Saves the trial settings to `BpodSystem.Data.TrialSettings`.
           - Saves the data using `SaveBpodSessionData`.

5. **Handle Pause:**
   - **Check for Pause:**
     - Checks if the protocol is paused and waits until the user resumes using `HandlePauseCondition`.
   - **Exit Condition:**
     - If the protocol is stopped (`BpodSystem.Status.BeingUsed == 0`), the function exits.

6. **End of Function:**
   - The loop terminates after `MaxTrials` or if the protocol is stopped.

Author:
    Kolbe Sussman
    ksussman@emich.edu
    last updated: 8/12/24

%}

function gustometer
    global BpodSystem
    MaxTrials = 1000;
    
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
    TrialTypes = round(rand(1,MaxTrials)) + 1; % Randomly interleaved trial types 1 and 2
    BpodSystem.Data.TrialTypes = TrialTypes; % The trial type of each trial completed will be added here.
    
    %% Initialize plots
    BpodNotebook('init'); % Bpod Notebook (to record text notes about the session or individual trials)
    BpodParameterGUI('init', S); % Initialize parameter GUI plugin
    
    %% Main trial loop
    for currentTrial = 1:MaxTrials
        S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
        R = GetValveTimes(S.GUI.RewardAmount, [1 3]);   % Update reward amounts
        
        % Determine trial-specific state matrix fields based on trial type
        switch TrialTypes(currentTrial)
            case 1
                LeftAction = 'Punish'; RightAction = 'Reward'; 
                StimulusOutputActions = {'ValveModule1', 2}; % Action to open valve for trial type 1
                RewardOutputActions = {'ValveModule1', 1}; % Action to deliver reward
                PunishOutputActions = {'LED', 1}
            case 2
                LeftAction = 'Reward'; RightAction = 'Punish';  
                StimulusOutputActions = {'ValveModule1', 3}; % Action to open valve for trial type 2
                RewardOutputActions = {'ValveModule1', 8}; % Action to deliver reward
                PunishOutputActions = {'LED', 3}
        end
        
        sma = NewStateMachine(); % Initialize new state machine description
        
        % Define states for stimulus delivery and response collection
        sma = AddState(sma, 'Name', 'WaitForPoke', ...
            'Timer', 0,...
            'StateChangeConditions', {'Port2In', 'DeliverStimulus'},...
            'OutputActions', {}); 
    
        sma = AddState(sma, 'Name', 'DeliverStimulus', ...
            'Timer', S.GUI.StimulusDuration,... % Duration of stimulus presentation
            'StateChangeConditions', {'Tup', 'CloseStimulusValve', 'Port2Out', 'CloseStimulusValve'},...
            'OutputActions', StimulusOutputActions);
    
        sma = AddState(sma, 'Name', 'CloseStimulusValve', ...
            'Timer', 0.1,... % Immediately close the stimulus valve
            'StateChangeConditions', {'Tup', 'WaitForResponse'},...
            'OutputActions', StimulusOutputActions); % Action to close the valve
    
        sma = AddState(sma, 'Name', 'WaitForResponse', ...
            'Timer', 15,... 
            'StateChangeConditions', {'Port1In', LeftAction, 'Port3In', RightAction, 'Tup','exit'},...
            'OutputActions', {});
        
        % Define states for reward delivery or punishment
        sma = AddState(sma, 'Name', 'Reward', ...
            'Timer', S.GUI.StimulusDuration,... % Duration of reward delivery
            'StateChangeConditions', {'Tup', 'CloseRewardValve'},...
            'OutputActions', RewardOutputActions); 
    
        sma = AddState(sma, 'Name', 'CloseRewardValve', ...
            'Timer', 0.1,... % Immediately close the reward valve
            'StateChangeConditions', {'Tup', 'exit'},...
            'OutputActions', RewardOutputActions); % Action to close the valve
    
        sma = AddState(sma, 'Name', 'Punish', ...
            'Timer', 3,... % Duration of punishment
            'StateChangeConditions', {'Tup', 'exit'},...
            'OutputActions', {PunishOutputActions}); 
    
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