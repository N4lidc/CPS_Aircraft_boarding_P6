# Bachelor_Project_P6 : Aircraft Boarding CPS

This repository contains the implementation of a Cyber-Physical System (CPS) model for simulating aircraft boarding. The project models passenger boarding as a state-based simulation, where global boarding control logic interacts with individual passenger behavior inside a simplified aircraft cabin.

The goal is to evaluate how different boarding strategies and control policies affect boarding performance, while ensuring that the simulation remains valid and consistent with the model constraints.

## Project Overview

Aircraft boarding is a time-dependent and variable process where passenger behavior, aircraft layout, luggage handling, and boarding rules influence each other. Delays may occur when passengers block the aisle, stow luggage, wait for access to their row, or experience seat interference.

This project approaches aircraft boarding as a CPS by separating the system into two interacting parts:

- **Global state machine**: represents the supervisory control logic of the boarding process.
- **Passenger state machine**: represents the behavior of each individual passenger from gate to seat.

These state machines make it possible to simulate boarding under controlled assumptions and compare different boarding strategies.

## Main Features

- FSM-based aircraft boarding simulation
- Global boarding control with phases such as preboarding, general boarding, hold, final call, and door closed
- Individual passenger behavior modeled through states such as at gate, scanned, in corridor, in aisle, waiting, stowing luggage, seating, and seated
- Shared aircraft resources such as aisle positions and seats
- Modeling of aisle blocking and seat interference
- Support for assigned seating
- Comparison of selected boarding strategies
- Evaluation using correctness checks and boarding performance measures

## Boarding Strategies

The project focuses on selected boarding strategies. These include:

- Random boarding
- Back-to-front boarding
- Outside-in boarding
- Reverse pyramid boarding
- Half-Block mix boarding
- Steffen boarding

## Model Structure

### Global State Machine

The global state machine controls the overall boarding process. It handles:

- Boarding phases
- Scanner status
- Passenger admission rate
- Boarding eligibility filters
- Corridor congestion
- Door closing

The main global states are:

- `Init`
- `Preboard`
- `General`
- `Hold`
- `Final Call`
- `Door Closed`

### Passenger State Machine

Each passenger is modeled as an individual state machine. This allows passenger-specific behavior such as walking speed, assigned seat, luggage status, and waiting time to affect the simulation.

The main passenger states are:

- `At Gate`
- `Scanned`
- `In Corridor`
- `In Aisle`
- `Advance`
- `Waiting`
- `At Row`
- `Stowing Luggage`
- `Seating`
- `Waiting For Seat`
- `Seated`

## Simulation Scope

The simulation is limited to the boarding process inside the aircraft cabin. It starts when passengers are called to board and ends when all passengers are seated.

Included in the model:

- Assigned seating
- A single-aisle aircraft layout
- One front boarding door
- Passenger movement through corridor and aisle
- Luggage stowage
- Aisle blocking
- Seat interference
- Priority boarding conditions
- Boarding strategy rules

## Evaluation

The model can be evaluated using two categories of measures.

### Correctness and Validity Checks

These checks ensure that the simulation does not produce impossible states:

- All passengers are eventually seated
- No passenger remains indefinitely in the corridor or queue
- At most one passenger occupies a seat
- At most one passenger occupies each aisle position at a time

### Performance Measures

These measures are used to compare boarding strategies:

- Total boarding time
- Scanner utilization
- Average and peak aisle occupancy
- Average and peak corridor occupancy
- Total waiting time in the aisle
- Queue and congestion behavior

## Repository Structure

```text
.
├── ExperimentRunner.m
├── Main.m
├── boarding/
│   ├── back_to_front_strategy.m
│   ├── create_gate_queue.m
│   ├── half_block_mix_strategy.m
│   ├── outside_in_strategy.m
│   ├── random_strategy.m
│   ├── reverse_pyramid_strategy.m
│   └── steffen_strategy.m
├── passengers/
│   ├── assign_unique_seats.m
│   ├── init_passengers.m
│   ├── try_advance.m
│   └── try_seat.m
├── simulation/
│   ├── handle_events.m
│   ├── handle_global_state_check.m
│   └── run_simulation.m
├── utils/
│   ├── global_state_machine.m
│   ├── load_params.m
│   ├── push.m
│   └── truncnorm_sample.m
├── visualization/
│   ├── cabin_visu.m
│   ├── initCabinVisu.m
│   └── updateCabinVisu.m
├── results/
│   └── experiment_*.csv
└── README.md
```

## Getting Started

### Prerequisites

- MATLAB installed on your machine
- This repository downloaded or cloned to a local folder
- No extra MATLAB toolboxes are required for the core simulation

### Installation

1. Download or clone this repository.
2. Open the repository root folder in MATLAB.
3. Keep the repository root as the current folder when you run the scripts.
4. You do not need to add folders to the MATLAB path manually; both entry-point scripts do that themselves.

### Running the Simulation

To run one simulation, execute [Main.m](Main.m).

This loads the default parameters from [utils/load_params.m](utils/load_params.m), runs the simulation through [simulation/run_simulation.m](simulation/run_simulation.m), and prints the selected boarding strategy in the MATLAB Command Window.

If you want to try a different boarding strategy, edit `params.boarding_strategy` in [utils/load_params.m](utils/load_params.m) and run [Main.m](Main.m) again. Use one of these values:

- `random`
- `back_to_front`
- `outside_in`
- `reverse_pyramid`
- `half_block_mix`
- `steffen`

To run multiple simulations and save results into [results/](results), execute [ExperimentRunner.m](ExperimentRunner.m).

The batch runner saves one summary CSV and one per-run CSV with a timestamped filename inside [results/](results).

## Project Context

This project was developed as part of the 6th semester Computer Science project.
