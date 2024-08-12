%{
altX Function Documentation
==========================

**Purpose:**
The `altX` function executes a behavioral training protocol using a Bpod system. It 
conducts a series of trials with defined parameters, alternates between trial types 
based on the number of consecutive rewarded trials, delivers stimuli, collects responses, 
and administers rewards or punishments.

**Global Variables:**
- `BpodSystem`: A global structure used by the Bpod system to manage trial data, 
  protocol settings, and system status.
- `rewardcount`: A global variable to count the number of consecutive rewarded trials.

**Local Variables:**
- `MaxTrials`: Integer value specifying the maximum number of trials to be executed 
  (set to 1000).
- `prompt`: Cell array containing the prompt message for user input.
- `dlgtitle`: String specifying the title of the input dialog box.
- `dims`: Array specifying the dimensions of the input dialog box.
- `definput`: Default input value for the dialog box.
- `answer`: Cell array containing the user input retrieved from the dialog box.
- `altnum`: Integer value specifying the number of consecutive rewarded trials before switching.
- `S`: Structure containing protocol settings (e.g., stimulus duration, reward amount). 
  Loaded from the Bpod system or initialized with default values if empty.
- `TrialTypes`: Array of integers defining the type of each trial (all initialized to 1 by default).
- `R`: Array containing valve open durations calculated using the `GetValveTimes` function.
- `currentTrialType`: Integer defining the type of the current trial (set to 1 initially).
- `sma`: State machine object used to define the trial states and transitions.

**Workflow:**

1. **User Input:**
   - **Prompt User:**
     - Prompts the user to enter the number of consecutive rewarded trials before switching 
       using an input dialog box.
     - The input is parsed and converted to a numeric value stored in `altnum`.

2. **Initialize Parameters:**
   - **Load Settings:**
     - Loads protocol settings from the Bpod system's `ProtocolSettings` struct into `S`.
     - If settings are empty, default values are initialized:
       - `StimulusDuration`: Duration of stimulus presentation, set to 0.05 seconds.
       - `RewardAmount`: Volume of reward delivered, set to 5 microliters (ul).
       - `OpenValveOne`: Command string for opening Valve 1.
       - `OpenValveTwo`: Command string for opening Valve 3.
       - GUI elements for these settings are set to 'pushbutton'.

3. **Define Trials:**
   - **Initialize Trial Types:**
     - An array `TrialTypes` is created, initializing all trials as type 1.
     - This array is saved in `BpodSystem.Data.TrialTypes`, storing the trial type for each completed trial.
   - **Initialize Reward Count:**
     - Sets `rewardcount` to 0.

4. **Initialize Plots:**
   - **Bpod Notebook:**
     - Initialized with `BpodNotebook('init')` to record text notes about the session or individual trials.
   - **Parameter GUI:**
     - Initialized with `BpodParameterGUI('init', S)` to display and edit protocol parameters during the session.

5. **Main Trial Loop:**
   - **Set Initial Trial Type:**
     - Starts with `currentTrialType` set to 1.
   - **Loop Over Trials:**
     - Iterates from 1 to `MaxTrials`.
     - In each iteration:
       - **Sync Parameters:**
         - Synchronizes the parameters with the GUI using `BpodParameterGUI('sync', S)`.
       - **Update Reward Times:**
         - Computes valve opening times for reward delivery using `GetValveTimes`.
       - **Define Trial-Specific Actions:**
         - Determines stimulus and reward output actions based on `currentTrialType`.
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
       - **Update Reward Count:**
         - Checks if the `Reward` state was reached and increments `rewardcount`.
         - Resets `rewardcount` if the `Punish` state was reached.
       - **Switch Trial Type:**
         - Switches trial type after reaching the specified number of consecutive rewarded trials.
         - Updates `TrialTypes` for the next trial.
       - **Save Current Trial Type:**
         - Saves the trial type for the current trial in `BpodSystem.Data.TrialTypes`.
       - **Handle Pause:**
         - Checks if the protocol is paused and waits until the user resumes.
       - **Exit Condition:**
         - If the protocol is stopped (`BpodSystem.Status.BeingUsed == 0`), the function exits.
    
6. **End of Function:**
   - The loop terminates after `MaxTrials` or if the protocol is stopped.

Author:
    Kolbe Sussman
    ksussman@emich.edu
    last updated: 8/12/24

%}
function altX
    global BpodSystem rewardcount
    MaxTrials = 1000;

    % Prompt user to enter the number of consecutive rewarded trials before switching
    prompt = {'Enter the number of consecutive rewarded trials before switching:'};
    dlgtitle = 'Input';
    dims = [1 50];
    definput = {'9'};
    answer = inputdlg(prompt, dlgtitle, dims, definput);
    altnum = str2double(answer{1});

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
    rewardcount = 0;

    %% Initialize plots
    BpodNotebook('init'); % Bpod Notebook (to record text notes about the session or individual trials)
    BpodParameterGUI('init', S); % Initialize parameter GUI plugin

    %% Main trial loop
    currentTrialType = 1; % Start with trial type 1
    for currentTrial = 1:MaxTrials
        S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
        R = GetValveTimes(S.GUI.RewardAmount, [1 3]);   % Update reward amounts

        % Determine trial-specific state matrix fields based on trial type
        switch currentTrialType
            case 1
                LeftAction = 'Punish'; RightAction = 'Reward'; 
                StimulusOutputActions = {'ValveModule1', 2}; % Action to open valve for trial type 1
                RewardOutputActions = {'ValveModule1', 1}; % Action to deliver reward
                PunishOutputActions = {'LED', 1}

            case 2
                LeftAction = 'Reward'; RightAction = 'Punish';  
                StimulusOutputActions = {'ValveModule1', 3}; % Action to open valve for trial type 2
                RewardOutputActions = {'ValveModule1', 8}; % Action to deliver re
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
            'StateChangeConditions', {'Port1In', LeftAction, 'Port3In', RightAction, 'Tup', 'exit'},...
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
    
        % Print specific field (e.g., States) within RawEvents
        %disp(RawEvents.States);  % Display the States field and its
        %contents --> this was just for debugging
    
        % If trial data was returned, record trial events and settings
        if ~isempty(fieldnames(RawEvents)) 
            BpodSystem.Data = AddTrialEvents(BpodSystem.Data, RawEvents); % Computes trial events from raw data
            BpodSystem.Data = BpodNotebook('sync', BpodSystem.Data); % Sync with Bpod notebook plugin
            BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
            SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
        end
    
        % Check if RawEvents contains States field before accessing it
        if isfield(RawEvents, 'States')
            % Check if the Reward state was reached and update reward counter
            if any(RawEvents.States == 5)
                rewardcount = rewardcount + 1;
            end
        
            % Check if the punish state was reached and reset reward counter
            if any(RawEvents.States == 7)
                rewardcount = 0;
            end
        else
            % Handle case where RawEvents.States is not defined (e.g., protocol stopped abruptly)
            disp('Warning: RawEvents.States not found.');
        end
    
    
        % Print reward count after each trial --> for debugging
        % fprintf('Trial %d: Reward count = %d\n', currentTrial, rewardcount);
    
        % Switch trial type after x consecutive rewarded trials
        if rewardcount >= altnum
            currentTrialType = 3 - currentTrialType; % Switch between 1 and 2
            rewardcount = 0;
        end
    
        % Update the trial type for the next trial
        if currentTrial < MaxTrials
            TrialTypes(currentTrial + 1) = currentTrialType;
        end
        
        % Save the trial type of the current trial
        BpodSystem.Data.TrialTypes(currentTrial) = currentTrialType;

        HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    
        if BpodSystem.Status.BeingUsed == 0
            return
        end
    end
end