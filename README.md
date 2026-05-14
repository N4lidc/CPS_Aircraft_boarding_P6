# Aircraft Boarding CPS
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
