%{
    Documentation for the Bpod Protocol: **Training Protocol**
    -----------------------------------------------------------------------
    
    Overview:
    The `train` function is a Bpod protocol designed to execute a sequence
    of trials where a subject can trigger different valves by poking into
    specific ports. This protocol is typically used for operant conditioning
    experiments, where the subject learns to associate specific actions
    (e.g., poking into a port) with outcomes (e.g., the release of a reward).
    The protocol manages the setup, execution, and data recording for each
    trial, ensuring a streamlined training process.

    Function Definition:
    The protocol is defined in the function `train`, which handles the 
    initialization, parameter definition, trial execution, and data 
    management for the training routine.

    Global Variables:
    - `BpodSystem`: The global variable that holds the Bpod system's state, 
      data, and status. This is required for interaction with the Bpod hardware.

    Key Parameters:
    - `MaxTrials`: Specifies the maximum number of trials to be executed 
      (default is 10,000).
    - `S.GUI.StimulusDuration`: The duration of the stimulus (in seconds).
    - `S.GUI.RewardAmount`: The amount of reward delivered (in microliters).
    - `S.GUI.OpenValveOne` and `S.GUI.OpenValveTwo`: Button controls for
      manually opening valves.

    State Machine Design:
    The protocol uses a state machine (`sma`) to control the sequence of
    events for each trial. The state machine includes the following states:

    1. `WaitForPoke`: 
       Waits for the subject to poke into a port (Port 1, 2, or 3). Based on 
       the poke location, the state machine transitions to the corresponding 
       valve opening state (`runvalve1`, `runvalve2`, or `runvalve3`).

    2. `runvalveX` (where X is 1, 2, or 3): 
       Opens the corresponding valve (Valve 1, 2, or 3) for a brief duration 
       (0.1 seconds). After the valve is opened, the state machine transitions 
       to the corresponding valve closing state (`CloseValveX`).

    3. `CloseValveX` (where X is 1, 2, or 3): 
       Closes the corresponding valve by sending a brief signal (0.1 seconds).
       The state machine then transitions to the `NextTrial` state.

    4. `NextTrial`: 
       Marks the end of the current trial and prepares the system for the next 
       trial by transitioning out of the state machine.

    Execution Flow:
    1. Initialization: 
       The function begins by initializing the Bpod system, the data structures,
       and the protocol settings.

    2. Parameter Definition: 
       Parameters for the protocol (such as stimulus duration and reward amount)
       are loaded and set up. If no settings are provided, default values are used.

    3. Trial Type Definition: 
       The trials are randomly interleaved between two trial types. This randomness
       helps ensure that the subject does not anticipate the outcomes based on trial order.

    4. Main Trial Loop: 
       For each trial, the state machine is configured, sent to the Bpod device, 
       and executed. The system waits for a subject response (poke) and then 
       executes the corresponding valve sequence.

    5. Data Recording: 
       If the state machine successfully completes a trial, the event data is 
       recorded, synchronized with the Bpod notebook, and saved to the current 
       data file.

    6. Pause and Exit Handling: 
       The function checks if the protocol is paused and waits until the user 
       resumes. If the protocol is stopped, the function exits.

    Customization:
    - Adjusting Stimulus and Reward Parameters: 
      The stimulus duration and reward amount can be customized via the GUI or 
      by modifying the corresponding parameters in the `S` structure.
    - Modifying Valve Timing: 
      The duration for which each valve remains open can be adjusted by changing 
      the `Timer` parameter in the `runvalveX` states.

    Error Handling:
    - If no trial data is returned (i.e., `RawEvents` is empty), the function 
      skips saving data for that trial.
    - The function checks the status of `BpodSystem.Status.BeingUsed` to 
      determine if the experiment should continue running or exit early.

    This protocol is suitable for experiments where subjects are trained to 
    associate specific actions with outcomes. It provides flexibility in 
    parameter settings and ensures reliable data recording and management

Author:
    Kolbe Sussman
    ksussman@emich.edu
    last updated: 8/12/24

%}

function train
    global BpodSystem
    MaxTrials = 10000; % Reset to original number of trials

    %% Initialize Bpod
    if isempty(BpodSystem)
        BpodSystem = struct();
    end
    if ~isfield(BpodSystem, 'Data')
        BpodSystem.Data = struct();
    end
    if ~isfield(BpodSystem, 'ProtocolSettings')
        BpodSystem.ProtocolSettings = struct();
    end
    if ~isfield(BpodSystem.Status, 'BeingUsed')
        BpodSystem.Status.BeingUsed = 1;
    end

    %% Define parameters
    S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
    if isempty(fieldnames(S)) % If settings file was an empty struct, populate struct with default settings
        S.GUI.StimulusDuration = 0.1; % in seconds
        S.GUI.RewardAmount = 5; % in microliters (ul)
        S.GUI.OpenValveOne = 'OpenValve(1)';
        S.GUIMeta.OpenValveOne.Style = 'pushbutton';
        S.GUI.OpenValveTwo = 'OpenValve(3)';
        S.GUIMeta.OpenValveTwo.Style = 'pushbutton';
    end 

    %% Define trials
    TrialTypes = round(rand(1, MaxTrials)) + 1; % Randomly interleaved trial types 1 and 2
    BpodSystem.Data.TrialTypes = TrialTypes; % The trial type of each trial completed will be added here.

    %% Initialize plots and GUI
    BpodNotebook('init'); % Bpod Notebook (to record text notes about the session or individual trials)
    BpodParameterGUI('init', S); % Initialize parameter GUI plugin

    %% Main trial loop
    for currentTrial = 1:MaxTrials
        % Sync parameters with BpodParameterGUI plugin
        S = BpodParameterGUI('sync', S); 
        % Update reward amounts
        R = GetValveTimes(S.GUI.RewardAmount, [1 3]); 
        
        % Initialize new state machine description
        sma = NewStateMachine(); 
        
        % Define states for stimulus delivery and response collection
        sma = AddState(sma, 'Name', 'WaitForPoke', ...
            'Timer', 0, ...
            'StateChangeConditions', {'Port1In', 'runvalve1', 'Port2In', 'runvalve2', 'Port3In', 'runvalve3'}, ...
            'OutputActions', {});
% Port1 is Left, Port2 is Center, Port3 is Right
        sma = AddState(sma, 'Name', 'runvalve1', ...
            'Timer', 0.1, ... % Open ValveModule1, output 8 for 0.1 seconds
            'StateChangeConditions', {'Tup', 'CloseValve1'}, ...
            'OutputActions', {'ValveModule1', 8});

        sma = AddState(sma, 'Name', 'CloseValve1', ...
            'Timer', 0.1, ... % Close ValveModule1, output 8
            'StateChangeConditions', {'Tup', 'NextTrial'}, ...
            'OutputActions', {'ValveModule1', 8}); 

        sma = AddState(sma, 'Name', 'runvalve2', ...
            'Timer', 0.1, ... % Open ValveModule1, output 2 for 0.1 seconds
            'StateChangeConditions', {'Tup', 'CloseValve2'}, ...
            'OutputActions', {'ValveModule1', 2});

        sma = AddState(sma, 'Name', 'CloseValve2', ...
            'Timer', 0.1, ... % Close ValveModule1, output 2
            'StateChangeConditions', {'Tup', 'NextTrial'}, ...
            'OutputActions', {'ValveModule1', 2}); 

        sma = AddState(sma, 'Name', 'runvalve3', ...
            'Timer', 0.1, ... % Open ValveModule1, output 1 for 0.1 seconds
            'StateChangeConditions', {'Tup', 'CloseValve3'}, ...
            'OutputActions', {'ValveModule1', 1});

        sma = AddState(sma, 'Name', 'CloseValve3', ...
            'Timer', 0.1, ... % Close ValveModule1, output 1
            'StateChangeConditions', {'Tup', 'NextTrial'}, ...
            'OutputActions', {'ValveModule1', 1}); 

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
