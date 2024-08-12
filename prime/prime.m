%{
    Documentation for the Bpod Protocol: **Valve Priming Protocol**
    -----------------------------------------------------------------------
    
    Overview:
    This protocol is designed to prime a series of valves connected to the 
    Bpod system. The protocol runs through a set of trials where each valve 
    is sequentially opened for a specified duration and then closed. This is 
    useful for ensuring that the valves are functioning properly and that 
    the system is ready for more complex experimental protocols.

    Function Definition:
    The protocol is defined in the function `prime`, which handles the setup 
    and execution of the valve priming routine.

    Global Variables:
    - `BpodSystem`: The global variable that holds the Bpod system's state, 
      data, and status. This is required for interaction with the Bpod hardware.

    Key Parameters:
    - `MaxTrials`: Defines the number of trials for the protocol. This is 
      set to 10 by default.

    State Machine Design:
    The protocol utilizes a state machine (`sma`) to manage the sequence of 
    operations for each trial. The state machine includes the following states:

    1. `WaitForPoke`: 
       This state waits for an input signal (e.g., a poke event in Port1) to 
       start the priming sequence. Upon detection of the input, the state 
       machine transitions to the next state to open Valve 1.

    2. `runvalveX` (where X ranges from 1 to 8): 
       In each of these states, the corresponding valve (Valve 1 through Valve 8) 
       is opened for 3 seconds. The state machine then transitions to the 
       corresponding `CloseValveX` state.

    3. `CloseValveX` (where X ranges from 1 to 8): 
       This state closes the corresponding valve by outputting a brief signal 
       (0.1 seconds). The state machine then transitions to the next `runvalve` 
       state or, if it is the last valve, exits the trial.

    Execution Flow:
    1. Initialization: 
       The function begins by initializing the state machine for each trial.

    2. State Machine Configuration: 
       Each trial configures the state machine to sequentially open and close 
       each of the eight valves.

    3. Sending State Machine: 
       The configured state machine is sent to the Bpod device for execution.

    4. Running the State Machine: 
       The protocol runs the state machine and collects the raw event data.

    5. Data Handling: 
       If the state machine completes successfully and returns data, the trial 
       events are added to the Bpod data structure, and the session data is saved.

    6. Pause Handling: 
       The protocol checks for a pause condition, allowing the user to pause 
       the experiment if necessary.

    7. Exit Condition: 
       If the Bpod system is no longer being used (e.g., the user stops the 
       experiment), the function will exit.

    Data Handling:
    - `AddTrialEvents`: Adds the trial's event data to the `BpodSystem.Data` structure.
    - `SaveBpodSessionData`: Saves the session data, including trial events and settings, 
      to the current data file.

    Customization:
    - Adjusting Valve Timing: 
      The duration for which each valve remains open (`Timer` parameter in 
      `runvalveX` states) can be adjusted based on experimental needs.
    - Changing the Number of Trials: 
      Modify the `MaxTrials` parameter to increase or decrease the number of 
      trials executed.

    Error Handling:
    - If the `RawEvents` structure is empty, indicating that no trial data was returned, 
      the protocol skips saving data for that trial.
    - The function checks the status of `BpodSystem.Status.BeingUsed` to determine 
      if the experiment should continue running or exit early.

    This protocol serves as a simple and effective way to ensure that the valve 
    system is functioning correctly before proceeding to more complex experimental 
    protocols.

Author:
    Kolbe Sussman
    ksussman@emich.edu
    last updated: 9/12/24

%}

function prime
    global BpodSystem
    MaxTrials = 10;

    %% Main trial loop
    for currentTrial = 1:MaxTrials
        sma = NewStateMachine(); % Initialize new state machine description

        % Close all valves at the beginning of each trial
        sma = AddState(sma, 'Name', 'WaitForPoke', ...
            'Timer', 0, ...
            'StateChangeConditions', {'Port1In', 'runvalve1'}, ...
            'OutputActions', { });
    
        sma = AddState(sma, 'Name', 'runvalve1', ...
            'Timer', 3, ... % Open ValveModule1, output 1 for 3 seconds
            'StateChangeConditions', {'Tup', 'CloseValve1'}, ...
            'OutputActions', {'ValveModule1', 1});
    
        sma = AddState(sma, 'Name', 'CloseValve1', ...
            'Timer', 0.1, ... % Close ValveModule1, output 1
            'StateChangeConditions', {'Tup', 'runvalve2'}, ...
            'OutputActions', {'ValveModule1', 1}); % Close ValveModule1, output 1
        
        sma = AddState(sma, 'Name', 'runvalve2', ...
            'Timer', 3, ... % Open ValveModule1, output 2 for 3 seconds
            'StateChangeConditions', {'Tup', 'CloseValve2'}, ...
            'OutputActions', {'ValveModule1', 2});
    
        sma = AddState(sma, 'Name', 'CloseValve2', ...
            'Timer', 0.1, ... % Close ValveModule1, output 2
            'StateChangeConditions', {'Tup', 'runvalve3'}, ...
            'OutputActions', {'ValveModule1', 2}); % Close ValveModule1, output 2
    
        sma = AddState(sma, 'Name', 'runvalve3', ...
            'Timer', 3, ... % Open ValveModule1, output 3 for 3 seconds
            'StateChangeConditions', {'Tup', 'CloseValve3'}, ...
            'OutputActions', {'ValveModule1', 3});
    
        sma = AddState(sma, 'Name', 'CloseValve3', ...
            'Timer', 0.1, ... % Close ValveModule1, output 3
            'StateChangeConditions', {'Tup', 'runvalve4'}, ...
            'OutputActions', {'ValveModule1', 3}); % Close ValveModule1, output 3
    
        sma = AddState(sma, 'Name', 'runvalve4', ...
            'Timer', 3, ... % Open ValveModule1, output 4 for 3 seconds
            'StateChangeConditions', {'Tup', 'CloseValve4'}, ...
            'OutputActions', {'ValveModule1', 4});
    
        sma = AddState(sma, 'Name', 'CloseValve4', ...
            'Timer', 0.1, ... % Close ValveModule1, output 4
            'StateChangeConditions', {'Tup', 'runvalve5'}, ...
            'OutputActions', {'ValveModule1', 4}); % Close ValveModule1, output 4

        sma = AddState(sma, 'Name', 'runvalve5', ...
            'Timer', 3, ... % Open ValveModule1, output 5 for 3 seconds
            'StateChangeConditions', {'Tup', 'CloseValve5'}, ...
            'OutputActions', {'ValveModule1', 5});
    
        sma = AddState(sma, 'Name', 'CloseValve5', ...
            'Timer', 0.1, ... % Close ValveModule1, output 5
            'StateChangeConditions', {'Tup', 'runvalve6'}, ...
            'OutputActions', {'ValveModule1', 5}); % Close ValveModule1, output 5
        
        sma = AddState(sma, 'Name', 'runvalve6', ...
            'Timer', 3, ... % Open ValveModule1, output 6 for 3 seconds
            'StateChangeConditions', {'Tup', 'CloseValve6'}, ...
            'OutputActions', {'ValveModule1', 6});
    
        sma = AddState(sma, 'Name', 'CloseValve6', ...
            'Timer', 0.1, ... % Close ValveModule1, output 6
            'StateChangeConditions', {'Tup', 'runvalve7'}, ...
            'OutputActions', {'ValveModule1', 6}); % Close ValveModule1, output 6
    
        sma = AddState(sma, 'Name', 'runvalve7', ...
            'Timer', 3, ... % Open ValveModule1, output 7 for 3 seconds
            'StateChangeConditions', {'Tup', 'CloseValve7'}, ...
            'OutputActions', {'ValveModule1', 7});
    
        sma = AddState(sma, 'Name', 'CloseValve7', ...
            'Timer', 0.1, ... % Close ValveModule1, output 7
            'StateChangeConditions', {'Tup', 'runvalve8'}, ...
            'OutputActions', {'ValveModule1', 7}); % Close ValveModule1, output 7
    
        sma = AddState(sma, 'Name', 'runvalve8', ...
            'Timer', 3, ... % Open ValveModule1, output 8 for 3 seconds
            'StateChangeConditions', {'Tup', 'CloseValve8'}, ...
            'OutputActions', {'ValveModule1', 8});
    
        sma = AddState(sma, 'Name', 'CloseValve8', ...
            'Timer', 0.1, ... % Close ValveModule1, output 8
            'StateChangeConditions', {'Tup', 'exit'}, ...
            'OutputActions', {'ValveModule1', 8}); % Close ValveModule1, output 8

        SendStateMachine(sma);

        RawEvents = RunStateMachine;

        if ~isempty(fieldnames(RawEvents)) % If trial data was returned
            BpodSystem.Data = AddTrialEvents(BpodSystem.Data, RawEvents); % Computes trial events from raw data
            BpodSystem.Data.TrialSettings(currentTrial) = struct(); % Save an empty struct for settings
            SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
        end
        HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
        if BpodSystem.Status.BeingUsed == 0
            return
        end
    end
end
