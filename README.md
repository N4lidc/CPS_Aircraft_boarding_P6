# Aircraft Boarding CPS

## Project Context

This project was developed as part of the 6th semester Computer Science project.
If you want a more detailed explanation of what this project does, please read the [About](About.md) file.

```text
.
├── ExperimentRunner.m          – Runs multiple simulations across configurations and saves results to CSV
├── Main.m                      – Runs a single simulation with parameters from load_params.m
├── boarding/
│   ├── back_to_front_strategy.m            – Passengers board from rear rows forward
│   ├── create_gate_queue.m                 – Dispatcher that selects the boarding strategy
│   ├── half_block_mix_strategy.m           – Rows split into halves for boarding order
│   ├── outside_in_strategy.m               – Window seats board before aisle seats
│   ├── random_strategy.m                   – Passengers board in random order
│   ├── reverse_pyramid_strategy.m          – Alternating rows and window/aisle pattern
│   └── steffen_strategy.m                  – Optimized strategy to minimize aisle interference
├── passengers/
│   ├── assign_unique_seats.m               – Assigns each passenger a unique seat
│   ├── init_passengers.m                   – Creates initial passenger struct array
│   ├── try_advance.m                       – Moves passenger to next state (AtGate → Scanned → ...)
│   └── try_seat.m                          – Attempts to seat a passenger in assigned row
├── simulation/
│   ├── handle_events.m                     – Processes events from the event queue
│   ├── handle_global_state_check.m         – Manages global state transitions (Preboard → General → ...)
│   └── run_simulation.m                    – Main simulation loop and KPI tracker
├── utils/
│   ├── global_state_machine.m              – Global state machine logic for boarding phases
│   ├── load_params.m                       – Loads all simulation parameters
│   ├── push.m                              – Adds events to the event queue
│   └── truncnorm_sample.m                  – Generates truncated normal distribution samples
├── visualization/
│   ├── cabin_visu.m                        – Draws cabin layout and passenger states
│   ├── initCabinVisu.m                     – Initializes the visualization figure
│   └── updateCabinVisu.m                   – Updates visualization after each event
├── results/
│   └── experiment_*.csv                    – Output CSV files from batch runs
├── README.md
└── About.md                                - Project context
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

