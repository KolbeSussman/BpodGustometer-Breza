# BpodGustometer-Breza
Custom functions for Bpod State Machine

# Gustometer Training Protocols
This repository contains a series of MATLAB scripts designed for training protocols using the Sanworks Bpod State Machine r2.5 and Sanworks Mouse Behavior Box r2. The scripts manage various training phases, from initial training to advanced discriminations, and include tools for analyzing the resulting data.

## Training Protocols
train: Initial training phase for the animal.
train2: Follow-up training phase to build on the initial training.
rightSideTraining: Training focused on responses from the right side.
leftSideTraining: Training focused on responses from the left side.
AltX (9): Alternate training with 9 scheduled sessions.
AltX (6): Alternate training with 6 scheduled sessions.
AltX (3): Alternate training with 3 scheduled sessions.
discrimFLUID: Fluid discrimination training phase.
discrimLIGHT: Light discrimination training phase.
Note: The number in parentheses for AltX indicates the schedule to be input when prompted.

Advancement Criteria
train, train2: Advance to the next protocol after the animal consistently completes 50 or more trials.
rightSideTraining, leftSideTraining, AltX (9), AltX (6), AltX (3), discrimFLUID: Advance to the next protocol after achieving 80% performance or better. Regress if the animal scores 60% or worse for 3 consecutive sessions.
Important: Limit H2O-deprivation to no more than 2 straight weeks. If additional tests are required, provide weekends off. If an animal has a weekend off, repeat the most recent protocol on Monday as a “booster training,” regardless of whether advancement criteria were met. This process may extend beyond 2 weeks, depending on the animal’s performance.

## Prime Protocol
Run the prime protocol once per day before starting training sessions to ensure the fluid lines are full. Begin the priming process by poking the left port (Port1) with your fingers. Repeat as necessary.

## Analysis Scripts
analyzeGustometerOutputFromFiles: Analyzes one or more .mat files containing gustometer data. The analysis includes generating a CSV file with trial counts, reward counts, punishment counts, and percentages.

analyzeTrainOutputFromFiles: Analyzes data from training output files, extracting nose poke counts and percentages for each port, and generating a CSV file with the results.

## Hardware
Sanworks Bpod State Machine r2.5: Sanworks Bpod State Machine r2.5
Sanworks Mouse Behavior Box r2: Sanworks Mouse Behavior Box r2
### Usage
To use the scripts, ensure the Sanworks Bpod State Machine r2.5 and Sanworks Mouse Behavior Box r2 are properly set up and connected. Follow the training protocols as outlined, and utilize the analysis scripts to process and review the collected data.
___________________________________________________________
For any issues or questions, please contact:

Author: Kolbe Sussman
Email: ksussman@emich.edu
Last Updated: 8/12/24

